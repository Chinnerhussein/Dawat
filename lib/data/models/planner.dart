// Couple planning records: BudgetExpense and Guest (class + ER diagrams),
// plus checklist tasks (objective "manage guests, budget and tasks", §4.3).

import 'service.dart';

class BudgetExpense {
  const BudgetExpense({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    this.bookingId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final ServiceCategory category;

  /// Set when the expense was recorded automatically from a booking payment.
  final String? bookingId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'amount': amount,
    'category': category.name,
    'bookingId': bookingId,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory BudgetExpense.fromMap(String id, Map<String, dynamic> m) => BudgetExpense(
    id: id,
    userId: m['userId'] as String,
    title: (m['title'] as String?) ?? '',
    amount: ((m['amount'] as num?) ?? 0).toDouble(),
    category: ServiceCategory.values.byName((m['category'] as String?) ?? 'other'),
    bookingId: m['bookingId'] as String?,
    createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? ''),
  );
}

enum RsvpStatus { pending, attending, declined }

enum GuestSide { bride, groom, both }

class Guest {
  const Guest({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone = '',
    this.side = GuestSide.both,
    this.partySize = 1,
    this.rsvpStatus = RsvpStatus.pending,
    this.tableNo,
  });

  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final GuestSide side;

  /// How many people this invitation covers (e.g. a family of 4).
  final int partySize;
  final RsvpStatus rsvpStatus;
  final int? tableNo;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'fullName': fullName,
    'phone': phone,
    'side': side.name,
    'partySize': partySize,
    'rsvpStatus': rsvpStatus.name,
    'tableNo': tableNo,
  };

  factory Guest.fromMap(String id, Map<String, dynamic> m) => Guest(
    id: id,
    userId: m['userId'] as String,
    fullName: (m['fullName'] as String?) ?? '',
    phone: (m['phone'] as String?) ?? '',
    side: GuestSide.values.byName((m['side'] as String?) ?? 'both'),
    partySize: (m['partySize'] as num?)?.toInt() ?? 1,
    rsvpStatus: RsvpStatus.values.byName((m['rsvpStatus'] as String?) ?? 'pending'),
    tableNo: (m['tableNo'] as num?)?.toInt(),
  );

  /// `updateRSVP()` from the class diagram.
  Guest updateRsvp(RsvpStatus status) => copyWith(rsvpStatus: status);

  Guest copyWith({
    String? fullName,
    String? phone,
    GuestSide? side,
    int? partySize,
    RsvpStatus? rsvpStatus,
    int? tableNo,
    bool clearTable = false,
  }) => Guest(
    id: id,
    userId: userId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    side: side ?? this.side,
    partySize: partySize ?? this.partySize,
    rsvpStatus: rsvpStatus ?? this.rsvpStatus,
    tableNo: clearTable ? null : (tableNo ?? this.tableNo),
  );
}

enum TaskPhase { planning, vendors, ceremony, reception }

class ChecklistTask {
  const ChecklistTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.phase,
    this.dueDate,
    this.done = false,
  });

  final String id;
  final String userId;
  final String title;
  final TaskPhase phase;
  final DateTime? dueDate;
  final bool done;

  bool get isOverdue {
    final d = dueDate;
    return !done && d != null && d.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'phase': phase.name,
    'dueDate': dueDate?.toIso8601String(),
    'done': done,
  };

  factory ChecklistTask.fromMap(String id, Map<String, dynamic> m) => ChecklistTask(
    id: id,
    userId: m['userId'] as String,
    title: (m['title'] as String?) ?? '',
    phase: TaskPhase.values.byName((m['phase'] as String?) ?? 'planning'),
    dueDate: DateTime.tryParse((m['dueDate'] as String?) ?? ''),
    done: (m['done'] as bool?) ?? false,
  );

  ChecklistTask copyWith({String? title, TaskPhase? phase, DateTime? dueDate, bool? done}) => ChecklistTask(
    id: id,
    userId: userId,
    title: title ?? this.title,
    phase: phase ?? this.phase,
    dueDate: dueDate ?? this.dueDate,
    done: done ?? this.done,
  );
}
