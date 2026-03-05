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

  DayPlan copyWith({
    int? dayNumber,
    DateTime? date,
    List<PlacePlan>? places,
  }) {
    return DayPlan(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      places: places ?? this.places,
    );
  }
}
