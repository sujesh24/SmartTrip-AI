class PlacePlan {
  const PlacePlan({
    required this.name,
    required this.rating,
    required this.timing,
    required this.price,
    required this.travelToNext,
    this.imageUrl,
  });

  final String name;
  final String rating;
  final String timing;
  final String price;
  final String travelToNext;
  final String? imageUrl;

  factory PlacePlan.fromJson(Map<String, dynamic> json) {
    return PlacePlan(
      name: (json['name'] as String? ?? '').trim(),
      rating: (json['rating'] as String? ?? '').trim(),
      timing: (json['timing'] as String? ?? '').trim(),
      price: (json['price'] as String? ?? '').trim(),
      travelToNext: (json['travelToNext'] as String? ?? '').trim(),
      imageUrl: (json['imageUrl'] as String?)?.trim(),
    );
  }

  PlacePlan copyWith({
    String? name,
    String? rating,
    String? timing,
    String? price,
    String? travelToNext,
    String? imageUrl,
  }) {
    return PlacePlan(
      name: name ?? this.name,
      rating: rating ?? this.rating,
      timing: timing ?? this.timing,
      price: price ?? this.price,
      travelToNext: travelToNext ?? this.travelToNext,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'rating': rating,
      'timing': timing,
      'price': price,
      'travelToNext': travelToNext,
      'imageUrl': imageUrl,
    };
  }
}
