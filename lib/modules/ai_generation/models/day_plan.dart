import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';

class DayPlan {
  const DayPlan({
    required this.dayNumber,
    required this.date,
    required this.places,
  });

  final int dayNumber;
  final DateTime date;
  final List<PlacePlan> places;

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPlaces =
        json['places'] as List<dynamic>? ?? <dynamic>[];

    return DayPlan(
      dayNumber: json['dayNumber'] as int? ?? 1,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      places: rawPlaces
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> rawPlace) {
            return PlacePlan.fromJson(
              rawPlace.map(
                (dynamic key, dynamic value) =>
                    MapEntry<String, dynamic>(key.toString(), value),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  DayPlan copyWith({int? dayNumber, DateTime? date, List<PlacePlan>? places}) {
    return DayPlan(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      places: places ?? this.places,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayNumber': dayNumber,
      'date': date.toIso8601String(),
      'places': places.map((PlacePlan place) => place.toJson()).toList(),
    };
  }
}
