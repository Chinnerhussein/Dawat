import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models/app_user.dart';
import '../../data/models/booking.dart';
import '../../data/models/notification.dart';
import '../../data/models/planner.dart';
import '../../data/models/service.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);
final _compact = NumberFormat.compactCurrency(locale: 'en_US', symbol: r'$');

String money(num value) => _money.format(value);
String moneyCompact(num value) => value >= 10000 ? _compact.format(value) : _money.format(value);

String fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String fmtDateShort(DateTime d) => DateFormat('d MMM').format(d);
String fmtDateLong(DateTime d) => DateFormat('EEEE, d MMMM yyyy').format(d);

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return fmtDate(d);
}

/// Parses a stored `yyyy-MM-dd` value for display.
String fmtDateKey(String? key) {
  final d = key == null ? null : DateTime.tryParse(key);
  return d == null ? (key ?? '') : fmtDate(d);
}

String cityName(String key) => switch (key) {
  'erbil' => 'Erbil',
  'sulaymaniyah' => 'Sulaymaniyah',
  'duhok' => 'Duhok',
  'zakho' => 'Zakho',
  'halabja' => 'Halabja',
  'kirkuk' => 'Kirkuk',
  _ => key,
};

String roleName(UserRole r) => switch (r) {
  UserRole.couple => 'Bride & Groom',
  UserRole.provider => 'Service provider',
  UserRole.admin => 'Admin',
};

extension ServiceCategoryX on ServiceCategory {
  String get label => switch (this) {
    ServiceCategory.hall => 'Halls',
    ServiceCategory.catering => 'Catering',
    ServiceCategory.photography => 'Photography',
    ServiceCategory.decoration => 'Decoration',
    ServiceCategory.music => 'Music',
    ServiceCategory.dress => 'Dress & Suits',
    ServiceCategory.makeup => 'Makeup',
    ServiceCategory.cars => 'Cars',
    ServiceCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    ServiceCategory.hall => Icons.account_balance_outlined,
    ServiceCategory.catering => Icons.room_service_outlined,
    ServiceCategory.photography => Icons.photo_camera_outlined,
    ServiceCategory.decoration => Icons.local_florist_outlined,
    ServiceCategory.music => Icons.music_note_outlined,
    ServiceCategory.dress => Icons.checkroom_outlined,
    ServiceCategory.makeup => Icons.brush_outlined,
    ServiceCategory.cars => Icons.directions_car_outlined,
    ServiceCategory.other => Icons.more_horiz,
  };

  /// Two-stop gradient used as artwork until providers upload photos.
  List<Color> get artColors => switch (this) {
    ServiceCategory.hall => const [Color(0xFF8A4E5E), Color(0xFF2B1A30)],
    ServiceCategory.catering => const [Color(0xFFD98E5F), Color(0xFF5A2E24)],
    ServiceCategory.photography => const [Color(0xFF6E5A8A), Color(0xFF22162E)],
    ServiceCategory.decoration => const [Color(0xFFC77A8A), Color(0xFF4A2335)],
    ServiceCategory.music => const [Color(0xFF9C6B3E), Color(0xFF2E1B14)],
    ServiceCategory.dress => const [Color(0xFFE2B8A0), Color(0xFF6B3F4C)],
    ServiceCategory.makeup => const [Color(0xFFD7998F), Color(0xFF5B2B37)],
    ServiceCategory.cars => const [Color(0xFF7D8BA0), Color(0xFF1F2331)],
    ServiceCategory.other => const [Color(0xFF8C7A86), Color(0xFF2A1D2F)],
  };
}

extension PriceUnitX on PriceUnit {
  String get suffix => switch (this) {
    PriceUnit.perEvent => '',
    PriceUnit.perPerson => ' / person',
    PriceUnit.perHour => ' / hour',
  };
  String get label => switch (this) {
    PriceUnit.perEvent => 'Per event',
    PriceUnit.perPerson => 'Per person',
    PriceUnit.perHour => 'Per hour',
  };
}

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pending => 'Pending',
    BookingStatus.accepted => 'Confirmed',
    BookingStatus.declined => 'Declined',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.completed => 'Completed',
  };
}

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.unpaid => 'Unpaid',
    PaymentStatus.depositPaid => 'Deposit paid',
    PaymentStatus.paid => 'Paid in full',
  };
}

extension RsvpX on RsvpStatus {
  String get label => switch (this) {
    RsvpStatus.pending => 'Awaiting reply',
    RsvpStatus.attending => 'Attending',
    RsvpStatus.declined => 'Not coming',
  };
}

extension GuestSideX on GuestSide {
  String get label => switch (this) {
    GuestSide.bride => "Bride's side",
    GuestSide.groom => "Groom's side",
    GuestSide.both => 'Both',
  };
}

extension TaskPhaseX on TaskPhase {
  String get label => switch (this) {
    TaskPhase.planning => 'Planning',
    TaskPhase.vendors => 'Vendors',
    TaskPhase.ceremony => 'Ceremony',
    TaskPhase.reception => 'Reception',
  };
}

extension NotificationText on AppNotification {
  String get title => switch (type) {
    NotificationType.bookingRequested => 'New booking request',
    NotificationType.bookingAccepted => 'Booking confirmed',
    NotificationType.bookingDeclined => 'Booking declined',
    NotificationType.bookingCancelled => 'Booking cancelled',
    NotificationType.paymentReceived => 'Payment received',
    NotificationType.providerApproved => 'Your business is live',
    NotificationType.providerRejected => 'Application not approved',
    NotificationType.reminder => 'Reminder',
  };

  String get body {
    final p = params;
    return switch (type) {
      NotificationType.bookingRequested => '${p['couple']} asked to book ${p['service']} on ${fmtDateKey(p['date'])}.',
      NotificationType.bookingAccepted =>
        '${p['service']} confirmed your booking for ${fmtDateKey(p['date'])}. You can now pay the deposit.',
      NotificationType.bookingDeclined =>
        '${p['service']} is not available on ${fmtDateKey(p['date'])}. Try another date or vendor.',
      NotificationType.bookingCancelled =>
        '${p['couple']} cancelled ${p['service']} on ${fmtDateKey(p['date'])}. The date is open again.',
      NotificationType.paymentReceived =>
        '${p['couple']} paid ${money(num.tryParse(p['amount'] ?? '') ?? 0)} for ${p['service']}.',
      NotificationType.providerApproved =>
        '${p['business']} was approved. Couples can now find and book your services.',
      NotificationType.providerRejected => '${p['business']} was not approved. Contact Dawat support for details.',
      NotificationType.reminder => '"${p['task']}" is due on ${fmtDateKey(p['date'])}.',
    };
  }

  IconData get icon => switch (type) {
    NotificationType.bookingRequested => Icons.mark_email_unread_outlined,
    NotificationType.bookingAccepted => Icons.event_available_outlined,
    NotificationType.bookingDeclined => Icons.event_busy_outlined,
    NotificationType.bookingCancelled => Icons.event_busy_outlined,
    NotificationType.paymentReceived => Icons.payments_outlined,
    NotificationType.providerApproved => Icons.verified_outlined,
    NotificationType.providerRejected => Icons.block_outlined,
    NotificationType.reminder => Icons.alarm_outlined,
  };
}
