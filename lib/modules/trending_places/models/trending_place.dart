import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingPlace {
  const TrendingPlace({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.imageUrl,
    required this.bestTime,
    required this.budget,
    required this.rating,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String country;
  final String description;
  final String imageUrl;
  final String bestTime;
  final String budget;
  final double rating;
  final String category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    if (country.isEmpty) {
      return name;
    }
    return '$name, $country';
  }

  factory TrendingPlace.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    return TrendingPlace(
      id: document.id,
      name: _readString(data['placeName'] ?? data['name'] ?? data['title']),
      country: _readString(data['country'] ?? data['location'] ?? data['flag']),
      description: _readString(data['description']),
      imageUrl: _readString(
        data['imageUrl'] ?? data['image_url'] ?? data['imageURL'],
      ),
      bestTime: _readString(data['bestTime'] ?? data['best_time']),
      budget: _readString(data['budget']),
      rating: _readDouble(data['rating'], fallback: 0),
      category: _readString(data['category'] ?? data['tag']),
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, Object?> toFirestore({bool includeCreatedAt = false}) {
    return <String, Object?>{
      'placeName': name.trim(),
      'country': country.trim(),
      'description': description.trim(),
      'imageUrl': imageUrl.trim(),
      'bestTime': bestTime.trim(),
      'budget': budget.trim(),
      'rating': rating,
      'category': category.trim(),
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

String trendingPlaceHeroTag(String placeId) => 'trending-place-hero-$placeId';

String _readString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

double _readDouble(Object? value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
