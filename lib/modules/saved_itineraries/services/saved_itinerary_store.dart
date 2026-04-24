import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttrip_ai/modules/saved_itineraries/models/saved_itinerary.dart';

abstract class SavedItineraryStore {
  Future<List<SavedItinerary>> loadSavedItineraries();
  Future<void> saveItinerary(SavedItinerary itinerary);
  Future<void> deleteItinerary(String itineraryId);
}

class SharedPrefsSavedItineraryStore implements SavedItineraryStore {
  static const String _savedTripsKey = 'saved_itineraries.items.v1';

  @override
  Future<List<SavedItinerary>> loadSavedItineraries() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return _loadFromPreferences(preferences);
  }

  @override
  Future<void> saveItinerary(SavedItinerary itinerary) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedItinerary> items = _loadFromPreferences(preferences);
    final int existingIndex = items.indexWhere(
      (SavedItinerary item) => item.id == itinerary.id,
    );

    if (existingIndex >= 0) {
      items[existingIndex] = itinerary;
    } else {
      items.add(itinerary);
    }

    items.sort(
      (SavedItinerary a, SavedItinerary b) => b.savedAt.compareTo(a.savedAt),
    );
    await preferences.setStringList(
      _savedTripsKey,
      items.map((SavedItinerary item) => jsonEncode(item.toJson())).toList(),
    );
  }

  @override
  Future<void> deleteItinerary(String itineraryId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedItinerary> items = _loadFromPreferences(preferences)
      ..removeWhere((SavedItinerary item) => item.id == itineraryId);

    await preferences.setStringList(
      _savedTripsKey,
      items.map((SavedItinerary item) => jsonEncode(item.toJson())).toList(),
    );
  }

  List<SavedItinerary> _loadFromPreferences(SharedPreferences preferences) {
    final List<String> rawItems =
        preferences.getStringList(_savedTripsKey) ?? <String>[];
    final List<SavedItinerary> items = <SavedItinerary>[];

    for (final String rawItem in rawItems) {
      try {
        final dynamic decoded = jsonDecode(rawItem);
        if (decoded is Map<String, dynamic>) {
          items.add(SavedItinerary.fromJson(decoded));
        }
      } catch (_) {
        continue;
      }
    }

    items.sort(
      (SavedItinerary a, SavedItinerary b) => b.savedAt.compareTo(a.savedAt),
    );
    return items;
  }
}
