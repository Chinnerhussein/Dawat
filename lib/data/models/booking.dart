// Booking (class diagram) / BOOKINGS table (ER diagram).

enum BookingStatus { pending, accepted, declined, cancelled, completed }

enum PaymentStatus { unpaid, depositPaid, paid }

class Booking {
  const Booking({
    required this.id,
    required this.coupleId,
    required this.coupleName,
    required this.serviceId,
    required this.serviceTitle,
    required this.providerId,
    required this.eventDate,
    required this.amount,
    this.status = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
    this.amountPaid = 0,
    this.guestCount,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String coupleId;
  final String coupleName;
  final String serviceId;
  final String serviceTitle;
  final String providerId;
  final DateTime eventDate;

  /// Quoted total for this booking.
  final double amount;
  final double amountPaid;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final int? guestCount;
  final String note;
  final DateTime? createdAt;

  /// Share of the total the couple pays to confirm the booking.
  static const double depositRate = 0.2;

  double get depositAmount => (amount * depositRate).roundToDouble();
  double get balanceDue => amount - amountPaid;

  bool get isOpen => status == BookingStatus.pending || status == BookingStatus.accepted;

  /// The couple can pay once the provider accepts and money is still owed.
  bool get canPay => status == BookingStatus.accepted && balanceDue > 0;

  Map<String, dynamic> toMap() => {
    'coupleId': coupleId,
    'coupleName': coupleName,
    'serviceId': serviceId,
    'serviceTitle': serviceTitle,
    'providerId': providerId,
    'eventDate': eventDate.toIso8601String(),
    'amount': amount,
    'amountPaid': amountPaid,
    'status': status.name,
    'paymentStatus': paymentStatus.name,
    'guestCount': guestCount,
    'note': note,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
    id: id,
    coupleId: m['coupleId'] as String,
    coupleName: (m['coupleName'] as String?) ?? '',
    serviceId: m['serviceId'] as String,
    serviceTitle: (m['serviceTitle'] as String?) ?? '',
    providerId: m['providerId'] as String,
    eventDate: DateTime.parse(m['eventDate'] as String),
    amount: ((m['amount'] as num?) ?? 0).toDouble(),
    amountPaid: ((m['amountPaid'] as num?) ?? 0).toDouble(),
    status: BookingStatus.values.byName((m['status'] as String?) ?? 'pending'),
    paymentStatus: PaymentStatus.values.byName((m['paymentStatus'] as String?) ?? 'unpaid'),
    guestCount: (m['guestCount'] as num?)?.toInt(),
    note: (m['note'] as String?) ?? '',
    createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? ''),
  );

  Booking copyWith({BookingStatus? status, PaymentStatus? paymentStatus, double? amountPaid}) => Booking(
    id: id,
    coupleId: coupleId,
    coupleName: coupleName,
    serviceId: serviceId,
    serviceTitle: serviceTitle,
    providerId: providerId,
    eventDate: eventDate,
    amount: amount,
    guestCount: guestCount,
    note: note,
    createdAt: createdAt,
    status: status ?? this.status,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    amountPaid: amountPaid ?? this.amountPaid,
  );
}
