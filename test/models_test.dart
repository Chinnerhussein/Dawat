import 'package:dawat/data/models/app_user.dart';
import 'package:dawat/data/models/booking.dart';
import 'package:dawat/data/models/notification.dart';
import 'package:dawat/data/models/planner.dart';
import 'package:dawat/data/models/service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('users round-trip through maps with the right subtype', () {
    final couple = Couple(
      id: 'c',
      name: 'Shno',
      partnerName: 'Aram',
      email: 's@x.app',
      weddingDate: DateTime(2027, 6, 14),
      totalBudget: 25000,
    );
    final provider = const ServiceProvider(
      id: 'p',
      name: 'Hemin',
      businessName: 'Lalav Hall',
      email: 'l@x.app',
      approval: ApprovalStatus.approved,
      rating: 4.8,
    );
    const admin = Admin(id: 'a', name: 'Admin', email: 'a@x.app');

    final c2 = AppUser.fromMap('c', couple.toMap());
    final p2 = AppUser.fromMap('p', provider.toMap());
    final a2 = AppUser.fromMap('a', admin.toMap());

    expect(c2, isA<Couple>());
    expect((c2 as Couple).displayNames, 'Shno & Aram');
    expect(c2.weddingDate, DateTime(2027, 6, 14));
    expect(c2.totalBudget, 25000);
    expect(p2, isA<ServiceProvider>());
    expect((p2 as ServiceProvider).approval, ApprovalStatus.approved);
    expect(a2, isA<Admin>());
    expect(a2.role, UserRole.admin);
  });

  test('service availability ignores time of day', () {
    final s = Service(
      id: 's',
      providerId: 'p',
      providerName: 'P',
      title: 'Hall',
      category: ServiceCategory.hall,
      price: 1000,
      city: 'erbil',
      blockedDates: [DateTime(2027, 6, 14)],
    );
    expect(s.checkAvailability(DateTime(2027, 6, 14, 19, 30)), isFalse);
    expect(s.checkAvailability(DateTime(2027, 6, 15)), isTrue);
    expect(s.copyWith(isActive: false).checkAvailability(DateTime(2027, 6, 15)), isFalse);

    final s2 = Service.fromMap('s', s.toMap());
    expect(s2.blockedDates.single, DateTime(2027, 6, 14));
    expect(s2.category, ServiceCategory.hall);
  });

  test('booking money helpers', () {
    final b = Booking(
      id: 'b',
      coupleId: 'c',
      coupleName: 'C',
      serviceId: 's',
      serviceTitle: 'Hall',
      providerId: 'p',
      eventDate: DateTime(2027, 6, 14),
      amount: 3500,
      status: BookingStatus.accepted,
    );
    expect(b.depositAmount, 700);
    expect(b.canPay, isTrue);
    expect(Booking.fromMap('b', b.toMap()).amount, 3500);
    expect(b.copyWith(status: BookingStatus.pending).canPay, isFalse);
  });

  test('planner records round-trip', () {
    const g = Guest(id: 'g', userId: 'u', fullName: 'Kawa', partySize: 4, rsvpStatus: RsvpStatus.attending, tableNo: 2);
    final g2 = Guest.fromMap('g', g.toMap());
    expect(g2.partySize, 4);
    expect(g2.tableNo, 2);
    expect(g2.updateRsvp(RsvpStatus.declined).rsvpStatus, RsvpStatus.declined);

    const e = BudgetExpense(id: 'e', userId: 'u', title: 'Rings', amount: 2400, category: ServiceCategory.other);
    expect(BudgetExpense.fromMap('e', e.toMap()).amount, 2400);

    final n = AppNotification(
      id: 'n',
      userId: 'u',
      type: NotificationType.bookingAccepted,
      params: const {'service': 'Hall'},
    );
    expect(AppNotification.fromMap('n', n.toMap()).params['service'], 'Hall');

    expect(SystemSettings.fromMap(const SystemSettings(maintenanceMode: true).toMap()).maintenanceMode, isTrue);
  });
}
