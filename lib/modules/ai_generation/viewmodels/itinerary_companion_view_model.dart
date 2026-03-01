import 'package:smarttrip_ai/modules/ai_generation/models/travel_companion.dart';

class ItineraryCompanionViewModel {
  TravelCompanion? selectedCompanion = TravelCompanion.solo;

  void select(TravelCompanion companion) {
    selectedCompanion = companion;
  }

  String? validateBeforeNext() {
    if (selectedCompanion == null) {
      return 'Please choose who is travelling with you.';
    }
    return null;
  }
}
