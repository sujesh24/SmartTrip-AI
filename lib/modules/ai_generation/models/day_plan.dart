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
}
