// Booking workflow shared by couples and providers. Each step updates the
// booking and notifies the other side.
//
//   couple requests ─▶ pending ─▶ provider accepts ─▶ accepted ─▶ completed
//                         │                              │
//                         └▶ declined / cancelled ◀──────┘
//
// Accepting a booking blocks that date on the service, so other couples see
// it as unavailable, and auto-declines other pending requests for the same
// service and date.

import '../data/models/app_user.dart';
import '../data/models/booking.dart';
import '../data/models/notification.dart';
import '../data/models/planner.dart';
import '../data/models/service.dart';
import '../data/repositories/repositories.dart';

enum PaymentOption { deposit, balance }

class BookingActions {
  BookingActions(this.backend);

  final Backend backend;

  Future<void> _notify(String userId, NotificationType type, Map<String, String> params) => backend.addNotification(
    AppNotification(id: backend.newId(), userId: userId, type: type, params: params, createdAt: DateTime.now()),
  );

  /// Quote for a service on a given guest count.
  static double quote(Service service, int? guestCount) =>
      service.priceUnit == PriceUnit.perPerson ? service.price * (guestCount ?? 0) : service.price;

  /// "Book Services" use case: the couple sends a request for a date.
  Future<Booking> requestBooking({
    required Couple couple,
    required Service service,
    required DateTime date,
    int? guestCount,
    String note = '',
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final fresh = await backend.getService(service.id) ?? service;
    if (!fresh.checkAvailability(day)) {
      throw const AppException('This date is no longer available. Pick another date.');
    }
    if (fresh.priceUnit == PriceUnit.perPerson && (guestCount ?? 0) <= 0) {
      throw const AppException('Enter the number of guests for a per-person price.');
    }
    final booking = Booking(
      id: backend.newId(),
      coupleId: couple.id,
      coupleName: couple.displayNames,
      serviceId: fresh.id,
      serviceTitle: fresh.title,
      providerId: fresh.providerId,
      eventDate: day,
      amount: quote(fresh, guestCount),
      guestCount: guestCount,
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    await backend.saveBooking(booking);
    await _notify(fresh.providerId, NotificationType.bookingRequested, {
      'service': fresh.title,
      'couple': couple.displayNames,
      'date': dateKey(day),
    });
    return booking;
  }

  /// Provider accepts or declines an incoming request.
  Future<void> respond(Booking booking, {required bool accept}) async {
    if (booking.status != BookingStatus.pending) {
      throw const AppException('This request has already been answered.');
    }
    if (!accept) {
      await backend.saveBooking(booking.copyWith(status: BookingStatus.declined));
      await _notify(booking.coupleId, NotificationType.bookingDeclined, {
        'service': booking.serviceTitle,
        'date': dateKey(booking.eventDate),
      });
      return;
    }

    final service = await backend.getService(booking.serviceId);
    if (service != null && !service.checkAvailability(booking.eventDate)) {
      throw const AppException(
        'You already have a booking on this date. Decline this request or unblock the date first.',
      );
    }
    await backend.saveBooking(booking.copyWith(status: BookingStatus.accepted));
    if (service != null) {
      await backend.saveService(service.copyWith(blockedDates: [...service.blockedDates, booking.eventDate]));
    }
    await _notify(booking.coupleId, NotificationType.bookingAccepted, {
      'service': booking.serviceTitle,
      'date': dateKey(booking.eventDate),
    });

    // Other pending requests for the same service and day can't be honoured.
    final others = await backend.watchProviderBookings(booking.providerId).first;
    for (final other in others) {
      if (other.id != booking.id &&
          other.serviceId == booking.serviceId &&
          other.status == BookingStatus.pending &&
          sameDay(other.eventDate, booking.eventDate)) {
        await respond(other, accept: false);
      }
    }
  }

  /// Couple cancels a pending or accepted booking.
  Future<void> cancel(Booking booking) async {
    if (!booking.isOpen) return;
    await backend.saveBooking(booking.copyWith(status: BookingStatus.cancelled));
    if (booking.status == BookingStatus.accepted) {
      // Release the date. With Firebase, security rules only let the provider
      // edit their services, so this step fails for a couple; the provider is
      // notified below and can reopen the date (a Cloud Function should do
      // this automatically in production).
      try {
        final service = await backend.getService(booking.serviceId);
        if (service != null) {
          await backend.saveService(
            service.copyWith(blockedDates: service.blockedDates.where((d) => !sameDay(d, booking.eventDate)).toList()),
          );
        }
      } catch (_) {}
    }
    await _notify(booking.providerId, NotificationType.bookingCancelled, {
      'service': booking.serviceTitle,
      'couple': booking.coupleName,
      'date': dateKey(booking.eventDate),
    });
  }

  /// Provider marks an accepted booking as done after the event.
  Future<void> complete(Booking booking) async {
    if (booking.status != BookingStatus.accepted) return;
    await backend.saveBooking(booking.copyWith(status: BookingStatus.completed));
  }

  /// "Make Payment" use case. Payment-provider integration is future work
  /// (report §9.3); this records the payment and adds it to the budget.
  Future<Booking> pay(Booking booking, PaymentOption option) async {
    if (!booking.canPay) {
      throw const AppException('This booking cannot be paid right now.');
    }
    final amount = switch (option) {
      PaymentOption.deposit =>
        booking.amountPaid > 0 ? throw const AppException('The deposit is already paid.') : booking.depositAmount,
      PaymentOption.balance => booking.balanceDue,
    };
    final paid = booking.amountPaid + amount;
    final updated = booking.copyWith(
      amountPaid: paid,
      paymentStatus: paid >= booking.amount ? PaymentStatus.paid : PaymentStatus.depositPaid,
    );
    await backend.saveBooking(updated);

    final service = await backend.getService(booking.serviceId);
    await backend.saveExpense(
      BudgetExpense(
        id: backend.newId(),
        userId: booking.coupleId,
        title: '${booking.serviceTitle} ${option == PaymentOption.deposit ? 'deposit' : 'payment'}',
        amount: amount,
        category: service?.category ?? ServiceCategory.other,
        bookingId: booking.id,
        createdAt: DateTime.now(),
      ),
    );
    await _notify(booking.providerId, NotificationType.paymentReceived, {
      'service': booking.serviceTitle,
      'couple': booking.coupleName,
      'amount': amount.toStringAsFixed(0),
    });
    return updated;
  }

  /// Admin approves or rejects a new provider.
  Future<void> setProviderApproval(ServiceProvider provider, ApprovalStatus status) async {
    await backend.setProviderApproval(provider.id, status);
    if (status != ApprovalStatus.pending) {
      await _notify(
        provider.id,
        status == ApprovalStatus.approved ? NotificationType.providerApproved : NotificationType.providerRejected,
        {'business': provider.businessName},
      );
    }
  }
}

/// Creates reminder notifications for checklist tasks due in the next 7 days.
/// Runs when a couple opens the app; each task is reminded at most once.
Future<void> createDueReminders(Backend backend, Couple couple) async {
  final tasks = await backend.watchTasks(couple.id).first;
  final existing = await backend.watchNotifications(couple.id).first;
  final reminded = existing.where((n) => n.type == NotificationType.reminder).map((n) => n.params['task']).toSet();
  final now = DateTime.now();
  for (final t in tasks) {
    final due = t.dueDate;
    if (t.done || due == null || reminded.contains(t.title)) continue;
    final days = due.difference(now).inDays;
    if (days >= 0 && days <= 7) {
      await backend.addNotification(
        AppNotification(
          id: backend.newId(),
          userId: couple.id,
          type: NotificationType.reminder,
          params: {'task': t.title, 'date': dateKey(due)},
          createdAt: now,
        ),
      );
    }
  }
}
