class Destination {
  Destination({
    required this.id,
    required this.name,
    required this.country,
    this.region,
    this.description,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String country;
  final String? region;
  final String? description;
  final List<String> imageUrls;

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
        region: json['region'] as String?,
        description: json['description'] as String?,
        imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? const [],
      );
}

class Listing {
  Listing({
    required this.id,
    required this.title,
    required this.listingType,
    required this.basePrice,
    required this.currency,
    this.description,
    this.heroImageUrl,
    this.destinationName,
    this.averageRating,
    this.reviewCount,
    this.capacity,
    this.durationHours,
    this.inclusions = const [],
  });

  final String id;
  final String title;
  final String listingType;
  final double basePrice;
  final String currency;
  final String? description;
  final String? heroImageUrl;
  final String? destinationName;
  final double? averageRating;
  final int? reviewCount;
  final int? capacity;
  final int? durationHours;
  final List<String> inclusions;

  String get formattedPrice {
    final amount = basePrice.toStringAsFixed(0);
    return '\$$amount';
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['base_price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '0') ?? 0;
    final ratingRaw = json['average_rating'];
    final rating = ratingRaw is num ? ratingRaw.toDouble() : null;

    final media = json['media'] as Map?;
    final mediaUrls = (media?['urls'] as List?)?.cast<String>();
    final hero = (json['hero_image_url'] as String?) ??
        (mediaUrls != null && mediaUrls.isNotEmpty ? mediaUrls.first : null);

    return Listing(
      id: json['id'] as String,
      title: json['title'] as String,
      listingType: json['listing_type'] as String? ?? 'experience',
      basePrice: price,
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String?,
      heroImageUrl: hero,
      destinationName: json['destination_name'] as String?,
      averageRating: rating,
      reviewCount: json['review_count'] as int?,
      capacity: json['capacity'] as int?,
      durationHours: json['duration_hours'] as int?,
      inclusions: (json['inclusions'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class Booking {
  Booking({
    required this.id,
    required this.listingTitle,
    required this.status,
    required this.travelDate,
    required this.guests,
    required this.totalAmount,
    required this.currency,
  });

  final String id;
  final String listingTitle;
  final String status;
  final String travelDate;
  final int guests;
  final double totalAmount;
  final String currency;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['total_amount'];
    final amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0;
    return Booking(
      id: json['id'] as String,
      listingTitle: json['listing_title'] as String? ?? 'Booking',
      status: json['status'] as String? ?? 'pending',
      travelDate: json['travel_date'] as String? ??
          json['created_at'] as String? ??
          '',
      guests: json['guests'] as int? ?? 1,
      totalAmount: amount,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
