// Service (class diagram) / SERVICES table (ER diagram).

enum ServiceCategory { hall, catering, photography, decoration, music, dress, makeup, cars, other }

enum PriceUnit { perEvent, perPerson, perHour }

class Service {
  const Service({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.title,
    required this.category,
    required this.price,
    required this.city,
    this.priceUnit = PriceUnit.perEvent,
    this.description = '',
    this.capacity,
    this.rating = 0,
    this.ratingCount = 0,
    this.blockedDates = const [],
    this.imageUrls = const [],
    this.isActive = true,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String title;
  final ServiceCategory category;
  final double price;
  final PriceUnit priceUnit;
  final String city;
  final String description;

  /// Guest capacity, for halls.
  final int? capacity;
  final double rating;
  final int ratingCount;

  /// Dates the provider is already booked or closed (date only, no time).
  final List<DateTime> blockedDates;
  final List<String> imageUrls;

  /// Providers can pause a listing without deleting it.
  final bool isActive;

  /// `checkAvailability()` from the class diagram.
  bool checkAvailability(DateTime date) {
    if (!isActive) return false;
    return !blockedDates.any((d) => _sameDay(d, date));
  }

  Map<String, dynamic> toMap() => {
    'providerId': providerId,
    'providerName': providerName,
    'title': title,
    'category': category.name,
    'price': price,
    'priceUnit': priceUnit.name,
    'city': city,
    'description': description,
    'capacity': capacity,
    'rating': rating,
    'ratingCount': ratingCount,
    'blockedDates': blockedDates.map(dateKey).toList(),
    'imageUrls': imageUrls,
    'isActive': isActive,
  };

  factory Service.fromMap(String id, Map<String, dynamic> m) => Service(
    id: id,
    providerId: m['providerId'] as String,
    providerName: (m['providerName'] as String?) ?? '',
    title: (m['title'] as String?) ?? '',
    category: ServiceCategory.values.byName((m['category'] as String?) ?? 'other'),
    price: ((m['price'] as num?) ?? 0).toDouble(),
    priceUnit: PriceUnit.values.byName((m['priceUnit'] as String?) ?? 'perEvent'),
    city: (m['city'] as String?) ?? 'erbil',
    description: (m['description'] as String?) ?? '',
    capacity: (m['capacity'] as num?)?.toInt(),
    rating: ((m['rating'] as num?) ?? 0).toDouble(),
    ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
    blockedDates: ((m['blockedDates'] as List?) ?? const []).map((e) => DateTime.parse(e as String)).toList(),
    imageUrls: ((m['imageUrls'] as List?) ?? const []).cast<String>(),
    isActive: (m['isActive'] as bool?) ?? true,
  );

  Service copyWith({
    String? title,
    ServiceCategory? category,
    double? price,
    PriceUnit? priceUnit,
    String? city,
    String? description,
    int? capacity,
    List<DateTime>? blockedDates,
    bool? isActive,
    String? providerName,
  }) => Service(
    id: id,
    providerId: providerId,
    rating: rating,
    ratingCount: ratingCount,
    imageUrls: imageUrls,
    providerName: providerName ?? this.providerName,
    title: title ?? this.title,
    category: category ?? this.category,
    price: price ?? this.price,
    priceUnit: priceUnit ?? this.priceUnit,
    city: city ?? this.city,
    description: description ?? this.description,
    capacity: capacity ?? this.capacity,
    blockedDates: blockedDates ?? this.blockedDates,
    isActive: isActive ?? this.isActive,
  );
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool sameDay(DateTime a, DateTime b) => _sameDay(a, b);

/// `2026-06-14`: the storage format for date-only values.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
