// User hierarchy from the class diagram (report §7.2):
// Couple and ServiceProvider specialise User. Admin is the third actor in the
// use case diagram (§7.1). All three are stored in the USERS table / `users`
// collection and told apart by the `role` field (ER diagram, §7.3).

enum UserRole { couple, provider, admin }

enum ApprovalStatus { pending, approved, rejected }

sealed class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = 'erbil',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  /// City key, e.g. `erbil`, `duhok`. See [kCities].
  final String city;

  /// Admins can suspend an account by setting this to false.
  final bool isActive;
  final DateTime? createdAt;

  UserRole get role;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'role': role.name,
    'isActive': isActive,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  AppUser withActive(bool active);

  static AppUser fromMap(String id, Map<String, dynamic> m) {
    final role = UserRole.values.byName((m['role'] as String?) ?? 'couple');
    final name = (m['name'] as String?) ?? '';
    final email = (m['email'] as String?) ?? '';
    final phone = (m['phone'] as String?) ?? '';
    final city = (m['city'] as String?) ?? 'erbil';
    final isActive = (m['isActive'] as bool?) ?? true;
    final createdAt = DateTime.tryParse((m['createdAt'] as String?) ?? '');
    switch (role) {
      case UserRole.couple:
        return Couple(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          isActive: isActive,
          createdAt: createdAt,
          partnerName: (m['partnerName'] as String?) ?? '',
          weddingDate: DateTime.tryParse((m['weddingDate'] as String?) ?? ''),
          totalBudget: ((m['totalBudget'] as num?) ?? 0).toDouble(),
        );
      case UserRole.provider:
        return ServiceProvider(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          isActive: isActive,
          createdAt: createdAt,
          businessName: (m['businessName'] as String?) ?? name,
          bio: (m['bio'] as String?) ?? '',
          rating: ((m['rating'] as num?) ?? 0).toDouble(),
          ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
          approval: ApprovalStatus.values.byName((m['approval'] as String?) ?? 'pending'),
        );
      case UserRole.admin:
        return Admin(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          isActive: isActive,
          createdAt: createdAt,
        );
    }
  }
}

/// The Bride & Groom actor.
class Couple extends AppUser {
  const Couple({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.city,
    super.isActive,
    super.createdAt,
    this.partnerName = '',
    this.weddingDate,
    this.totalBudget = 0,
  });

  final String partnerName;
  final DateTime? weddingDate;
  final double totalBudget;

  @override
  UserRole get role => UserRole.couple;

  /// First names, e.g. "Shno & Aram", or just the account holder's name.
  String get displayNames {
    String first(String n) => n.trim().split(RegExp(r'\s+')).first;
    return partnerName.trim().isEmpty ? name : '${first(name)} & ${first(partnerName)}';
  }

  int? get daysToGo {
    final d = weddingDate;
    if (d == null) return null;
    final today = DateTime.now();
    return DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'partnerName': partnerName,
    'weddingDate': weddingDate?.toIso8601String(),
    'totalBudget': totalBudget,
  };

  Couple copyWith({
    String? name,
    String? phone,
    String? city,
    String? partnerName,
    DateTime? weddingDate,
    double? totalBudget,
    bool? isActive,
  }) => Couple(
    id: id,
    email: email,
    createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    isActive: isActive ?? this.isActive,
    partnerName: partnerName ?? this.partnerName,
    weddingDate: weddingDate ?? this.weddingDate,
    totalBudget: totalBudget ?? this.totalBudget,
  );

  @override
  Couple withActive(bool active) => copyWith(isActive: active);
}

/// The Service Provider actor (halls, caterers, photographers, salons…).
class ServiceProvider extends AppUser {
  const ServiceProvider({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.city,
    super.isActive,
    super.createdAt,
    required this.businessName,
    this.bio = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.approval = ApprovalStatus.pending,
  });

  final String businessName;
  final String bio;
  final double rating;
  final int ratingCount;

  /// New providers stay hidden from couples until an admin approves them.
  final ApprovalStatus approval;

  @override
  UserRole get role => UserRole.provider;

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'businessName': businessName,
    'bio': bio,
    'rating': rating,
    'ratingCount': ratingCount,
    'approval': approval.name,
  };

  ServiceProvider copyWith({
    String? name,
    String? phone,
    String? city,
    String? businessName,
    String? bio,
    ApprovalStatus? approval,
    bool? isActive,
  }) => ServiceProvider(
    id: id,
    email: email,
    createdAt: createdAt,
    rating: rating,
    ratingCount: ratingCount,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    isActive: isActive ?? this.isActive,
    businessName: businessName ?? this.businessName,
    bio: bio ?? this.bio,
    approval: approval ?? this.approval,
  );

  @override
  ServiceProvider withActive(bool active) => copyWith(isActive: active);
}

/// The Admin actor. Admin accounts are never created from the app's sign-up
/// screen; they are set up by another admin or directly in the database.
class Admin extends AppUser {
  const Admin({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.city,
    super.isActive,
    super.createdAt,
  });

  @override
  UserRole get role => UserRole.admin;

  Admin copyWith({String? name, String? phone, String? city, bool? isActive}) => Admin(
    id: id,
    email: email,
    createdAt: createdAt,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    isActive: isActive ?? this.isActive,
  );

  @override
  Admin withActive(bool active) => copyWith(isActive: active);
}

/// Cities in the Kurdistan Region (and nearby) that Dawat lists. The admin can
/// switch cities on and off in system settings.
const List<String> kCities = ['erbil', 'sulaymaniyah', 'duhok', 'zakho', 'halabja', 'kirkuk'];
