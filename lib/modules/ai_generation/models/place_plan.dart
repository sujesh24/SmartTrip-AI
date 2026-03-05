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
}
