import 'dart:convert';

import 'package:smarttrip_ai/modules/ai_generation/models/day_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';

class ResultViewModel {
  ResultViewModel({
    required ItineraryRequest request,
    required String generatedText,
  }) : destination = _safeDestination(request.destination),
       companion = _safeCompanion(request.companion),
       budgetLabel = '\u20B9 ${_formatBudget(request.budget)}',
       dateRangeLabel = _formatDateRange(request.startDate, request.endDate),
       dayPlans = _buildDayPlans(
         request,
         generatedText,
         _safeDestination(request.destination),
       );

  final String destination;
  final String companion;
  final String budgetLabel;
  final String dateRangeLabel;
  final List<DayPlan> dayPlans;

  String get title => '$destination $companion Trip';

  List<DayPlan> visiblePlans(int selectedDay) {
    if (selectedDay == 0) {
      return dayPlans;
    }
    return dayPlans
        .where((DayPlan dayPlan) => dayPlan.dayNumber == selectedDay)
        .toList();
  }

  String dayChipLabel(DayPlan dayPlan) {
    return 'Day ${dayPlan.dayNumber}: $destination';
  }

  String formatDayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static List<DayPlan> _buildDayPlans(
    ItineraryRequest request,
    String generatedText,
    String destination,
  ) {
    final List<DayPlan> parsed = _tryParseDayPlansFromResponse(
      request,
      generatedText,
      destination,
    );
    if (parsed.isNotEmpty) {
      parsed.sort((DayPlan a, DayPlan b) => a.dayNumber.compareTo(b.dayNumber));
      return _ensureUniquePlacesAcrossTrip(parsed, destination);
    }
    return _buildFallbackDayPlans(request, destination);
  }

  static List<DayPlan> _tryParseDayPlansFromResponse(
    ItineraryRequest request,
    String generatedText,
    String destination,
  ) {
    final Map<String, dynamic>? decoded = _decodeJsonMap(generatedText);
    if (decoded == null) {
      return <DayPlan>[];
    }

    final dynamic rawDays =
        decoded['days'] ?? decoded['itinerary'] ?? decoded['plan'];
    if (rawDays is! List) {
      return <DayPlan>[];
    }

    final DateTime baseDate = _parseDate(request.startDate) ?? DateTime.now();
    final List<DayPlan> plans = <DayPlan>[];

    for (int i = 0; i < rawDays.length; i++) {
      final dynamic rawDay = rawDays[i];
      if (rawDay is! Map<String, dynamic>) {
        continue;
      }

      final int dayNumber =
          _asInt(rawDay['day'] ?? rawDay['dayNumber'] ?? rawDay['index']) ??
          (i + 1);
      final DateTime dayDate =
          _asDate(rawDay['date']) ??
          baseDate.add(Duration(days: dayNumber - 1));

      final dynamic rawPlaces =
          rawDay['places'] ??
          rawDay['activities'] ??
          rawDay['stops'] ??
          rawDay['items'];
      final List<PlacePlan> places = _parsePlaces(rawPlaces, destination);
      if (places.isEmpty) {
        continue;
      }

      plans.add(DayPlan(dayNumber: dayNumber, date: dayDate, places: places));
    }

    return plans;
  }

  static Map<String, dynamic>? _decodeJsonMap(String source) {
    final String trimmed = source.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final String withoutFence = trimmed
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    Map<String, dynamic>? map = _decodeAsMap(withoutFence);
    if (map != null) {
      return map;
    }

    final int firstBrace = withoutFence.indexOf('{');
    final int lastBrace = withoutFence.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace <= firstBrace) {
      return null;
    }

    final String jsonPart = withoutFence.substring(firstBrace, lastBrace + 1);
    return _decodeAsMap(jsonPart);
  }

  static Map<String, dynamic>? _decodeAsMap(String rawJson) {
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is List) {
        return <String, dynamic>{'days': decoded};
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static List<PlacePlan> _parsePlaces(dynamic rawPlaces, String destination) {
    if (rawPlaces is! List) {
      return <PlacePlan>[];
    }

    final List<PlacePlan> places = <PlacePlan>[];
    for (int i = 0; i < rawPlaces.length; i++) {
      final dynamic rawPlace = rawPlaces[i];
      final Map<String, dynamic>? rawPlaceMap = _asMap(rawPlace);

      final String? rawName = rawPlaceMap == null
          ? _asString(rawPlace)
          : _asString(
              rawPlaceMap['name'] ??
                  rawPlaceMap['title'] ??
                  rawPlaceMap['place'] ??
                  rawPlaceMap['spot'],
            );
      final String name = _normalizePlaceName(
        rawName ?? 'Top Attraction ${i + 1}',
      );
      if (_isLowQualityPlaceName(name, destination)) {
        continue;
      }

      final String rating = _normalizeRating(
        rawPlaceMap?['rating'] ?? rawPlaceMap?['score'] ?? rawPlaceMap?['stars'],
      );
      final String timing =
          _asString(
            rawPlaceMap?['timing'] ??
                rawPlaceMap?['time'] ??
                rawPlaceMap?['hours'] ??
                rawPlaceMap?['duration'],
          ) ??
          'Whole Day';
      final String price = _normalizePrice(
        _asString(
          rawPlaceMap?['price'] ??
              rawPlaceMap?['cost'] ??
              rawPlaceMap?['entryFee'] ??
              rawPlaceMap?['entry_fee'],
        ),
      );
      final String travelToNext =
          _asString(
            rawPlaceMap?['travel_to_next'] ??
                rawPlaceMap?['travelToNext'] ??
                rawPlaceMap?['transfer_time'] ??
                rawPlaceMap?['transferTime'] ??
                rawPlaceMap?['nextTravelTime'] ??
                rawPlaceMap?['time_to_next'],
          ) ??
          _defaultTravelToNext(places.length, name);
      final String? imageUrl = _asString(
        rawPlaceMap?['imageUrl'] ??
            rawPlaceMap?['image_url'] ??
            rawPlaceMap?['image'] ??
            rawPlaceMap?['photo'],
      );

      places.add(
        PlacePlan(
          name: name,
          rating: rating,
          timing: timing,
          price: price,
          travelToNext: travelToNext,
          imageUrl: imageUrl,
        ),
      );
    }

    return places;
  }

  static List<DayPlan> _buildFallbackDayPlans(
    ItineraryRequest request,
    String destination,
  ) {
    final DateTime now = DateTime.now();
    final DateTime startDate = _parseDate(request.startDate) ?? now;
    final DateTime parsedEnd = _parseDate(request.endDate) ?? startDate;
    final DateTime endDate = parsedEnd.isBefore(startDate)
        ? startDate
        : parsedEnd;
    final int totalDays = endDate.difference(startDate).inDays + 1;
    final List<PlacePlan> placePool = _fallbackPlacePoolForDestination(
      destination,
    );

    final List<DayPlan> result = <DayPlan>[];
    for (int i = 0; i < totalDays; i++) {
      final DateTime dayDate = startDate.add(Duration(days: i));
      final int firstIndex = (i * 2) % placePool.length;
      final int secondIndex = (firstIndex + 1) % placePool.length;
      final int thirdIndex = (firstIndex + 2) % placePool.length;

      final List<PlacePlan> daySeeds = <PlacePlan>[
        placePool[firstIndex],
        placePool[secondIndex],
        if (totalDays == 1 || i.isEven) placePool[thirdIndex],
      ];

      final List<PlacePlan> dayPlaces = List<PlacePlan>.generate(
        daySeeds.length,
        (int index) {
          final PlacePlan source = daySeeds[index];
          return source.copyWith(
            travelToNext: _defaultTravelToNext(index, source.name),
          );
        },
      );

      result.add(DayPlan(dayNumber: i + 1, date: dayDate, places: dayPlaces));
    }
    return _ensureUniquePlacesAcrossTrip(result, destination);
  }

  static List<DayPlan> _ensureUniquePlacesAcrossTrip(
    List<DayPlan> plans,
    String destination,
  ) {
    final List<PlacePlan> fallbackPool = _fallbackPlacePoolForDestination(
      destination,
    );
    final Set<String> usedAcrossTrip = <String>{};
    int fallbackCursor = 0;

    final List<DayPlan> result = <DayPlan>[];
    for (final DayPlan dayPlan in plans) {
      final int targetCount = dayPlan.places.length.clamp(2, 4) as int;
      final Set<String> usedInDay = <String>{};
      final List<PlacePlan> uniquePlaces = <PlacePlan>[];

      for (final PlacePlan place in dayPlan.places) {
        final String cleanName = _normalizePlaceName(place.name);
        final String key = _placeIdentityKey(cleanName);
        if (key.isEmpty) {
          continue;
        }
        if (usedInDay.contains(key) || usedAcrossTrip.contains(key)) {
          continue;
        }

        uniquePlaces.add(place.copyWith(name: cleanName));
        usedInDay.add(key);
        usedAcrossTrip.add(key);
        if (uniquePlaces.length >= targetCount) {
          break;
        }
      }

      int attempts = 0;
      while (uniquePlaces.length < targetCount && attempts < fallbackPool.length) {
        final PlacePlan seed = fallbackPool[fallbackCursor % fallbackPool.length];
        fallbackCursor++;
        attempts++;

        final String key = _placeIdentityKey(seed.name);
        if (key.isEmpty ||
            usedInDay.contains(key) ||
            usedAcrossTrip.contains(key)) {
          continue;
        }

        uniquePlaces.add(seed);
        usedInDay.add(key);
        usedAcrossTrip.add(key);
      }

      if (uniquePlaces.isEmpty) {
        continue;
      }

      final List<PlacePlan> normalizedTravelPlaces = List<PlacePlan>.generate(
        uniquePlaces.length,
        (int index) {
          final PlacePlan source = uniquePlaces[index];
          if (index == uniquePlaces.length - 1) {
            return source;
          }

          final String travelToNext = source.travelToNext.trim().isEmpty
              ? _defaultTravelToNext(index, source.name)
              : source.travelToNext;
          return source.copyWith(travelToNext: travelToNext);
        },
      );

      result.add(
        DayPlan(
          dayNumber: dayPlan.dayNumber,
          date: dayPlan.date,
          places: normalizedTravelPlaces,
        ),
      );
    }

    return result;
  }

  static List<PlacePlan> _fallbackPlacePoolForDestination(String destination) {
    final String lookup = _normalizeLookup(destination);

    if (lookup.contains('japan') || lookup.contains('japn')) {
      return const <PlacePlan>[
        PlacePlan(
          name: 'Senso-ji Temple (Tokyo)',
          rating: '4.7',
          timing: '09:00 - 11:30',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Tokyo Skytree (Tokyo)',
          rating: '4.6',
          timing: '12:30 - 15:00',
          price: '\u20B9 1,300 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Meiji Jingu Shrine (Tokyo)',
          rating: '4.7',
          timing: '16:00 - 18:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Fushimi Inari Taisha (Kyoto)',
          rating: '4.8',
          timing: '08:30 - 11:30',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Kiyomizu-dera Temple (Kyoto)',
          rating: '4.7',
          timing: '13:00 - 15:30',
          price: '\u20B9 300 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Arashiyama Bamboo Grove (Kyoto)',
          rating: '4.6',
          timing: '16:00 - 18:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Osaka Castle (Osaka)',
          rating: '4.6',
          timing: '09:30 - 12:00',
          price: '\u20B9 350 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Dotonbori (Osaka)',
          rating: '4.6',
          timing: '17:00 - 20:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Nara Park (Nara)',
          rating: '4.7',
          timing: '10:00 - 13:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Todai-ji Temple (Nara)',
          rating: '4.7',
          timing: '14:00 - 16:30',
          price: '\u20B9 450 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Hiroshima Peace Memorial Park (Hiroshima)',
          rating: '4.7',
          timing: '09:30 - 12:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Itsukushima Shrine (Miyajima)',
          rating: '4.8',
          timing: '14:00 - 17:00',
          price: '\u20B9 350 per person',
          travelToNext: '',
        ),
      ];
    }

    if (lookup.contains('china')) {
      return const <PlacePlan>[
        PlacePlan(
          name: 'Forbidden City (Beijing)',
          rating: '4.8',
          timing: '09:00 - 12:00',
          price: '\u20B9 700 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Mutianyu Great Wall (Beijing)',
          rating: '4.8',
          timing: '13:30 - 17:00',
          price: '\u20B9 1,600 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Temple of Heaven (Beijing)',
          rating: '4.7',
          timing: '09:00 - 11:30',
          price: '\u20B9 400 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Summer Palace (Beijing)',
          rating: '4.7',
          timing: '14:00 - 17:30',
          price: '\u20B9 500 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'The Bund (Shanghai)',
          rating: '4.7',
          timing: '17:00 - 20:00',
          price: 'Free',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Yu Garden (Shanghai)',
          rating: '4.6',
          timing: '10:00 - 13:00',
          price: '\u20B9 350 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'Terracotta Army Museum (Xi\'an)',
          rating: '4.8',
          timing: '09:30 - 13:30',
          price: '\u20B9 1,100 per person',
          travelToNext: '',
        ),
        PlacePlan(
          name: 'West Lake (Hangzhou)',
          rating: '4.7',
          timing: '15:00 - 18:30',
          price: 'Free',
          travelToNext: '',
        ),
      ];
    }

    return const <PlacePlan>[
      PlacePlan(
        name: 'Historic City Center',
        rating: '4.6',
        timing: '09:00 - 12:00',
        price: 'Free',
        travelToNext: '',
      ),
      PlacePlan(
        name: 'National Museum',
        rating: '4.7',
        timing: '13:00 - 16:00',
        price: '\u20B9 500 per person',
        travelToNext: '',
      ),
      PlacePlan(
        name: 'Riverside Promenade',
        rating: '4.5',
        timing: '17:00 - 19:00',
        price: 'Free',
        travelToNext: '',
      ),
      PlacePlan(
        name: 'Central Art District',
        rating: '4.6',
        timing: '10:30 - 13:00',
        price: '\u20B9 700 per person',
        travelToNext: '',
      ),
      PlacePlan(
        name: 'Botanical Garden',
        rating: '4.6',
        timing: '14:30 - 17:30',
        price: '\u20B9 400 per person',
        travelToNext: '',
      ),
      PlacePlan(
        name: 'Panorama Viewpoint',
        rating: '4.5',
        timing: '18:00 - 20:00',
        price: 'Free',
        travelToNext: '',
      ),
    ];
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is String) {
      return _parseDate(value);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final Map<String, dynamic> converted = <String, dynamic>{};
      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        converted[entry.key.toString()] = entry.value;
      }
      return converted;
    }
    return null;
  }

  static String _normalizePlaceName(String value) {
    String normalized = value.trim();
    normalized = normalized.replaceAll(RegExp(r'^[\-\*\s]+'), '');
    normalized = normalized.replaceAll(RegExp(r'^\d+[\)\.\-\s]+'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  static String _placeIdentityKey(String name) {
    String normalized = name.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'\(.*?\)'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  static bool _isLowQualityPlaceName(String name, String destination) {
    final String normalizedName = _normalizeLookup(name);
    if (normalizedName.isEmpty) {
      return true;
    }

    if (normalizedName.startsWith('place ') ||
        normalizedName.startsWith('spot ') ||
        normalizedName.startsWith('location ')) {
      return true;
    }

    final String normalizedDestination = _normalizeLookup(destination);
    if (normalizedDestination.isEmpty) {
      return false;
    }

    if (normalizedName == normalizedDestination) {
      return true;
    }

    if (!normalizedName.startsWith('$normalizedDestination ')) {
      return false;
    }

    final String suffix = normalizedName
        .substring(normalizedDestination.length)
        .trim();
    if (suffix.isEmpty) {
      return true;
    }

    const Set<String> genericSuffixes = <String>{
      'market',
      'beach',
      'hall',
      'old town',
      'food street',
      'fort',
      'museum',
      'night walk',
      'sunset point',
      'city center',
      'downtown',
      'park',
      'viewpoint',
      'view point',
    };
    return genericSuffixes.contains(suffix);
  }

  static String _normalizeLookup(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeRating(dynamic value) {
    if (value == null) {
      return '4.5';
    }
    if (value is num) {
      return value.toDouble().toStringAsFixed(1);
    }

    final String text = value.toString().trim();
    if (text.isEmpty) {
      return '4.5';
    }

    final RegExpMatch? match = RegExp(r'\d+(\.\d+)?').firstMatch(text);
    if (match == null) {
      return '4.5';
    }

    final double? parsed = double.tryParse(match.group(0)!);
    if (parsed == null) {
      return '4.5';
    }
    return parsed.toStringAsFixed(1);
  }

  static String _normalizePrice(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Free';
    }

    String value = input.trim();
    value = value.replaceAll('\$', '\u20B9');
    value = value.replaceAll(RegExp('usd', caseSensitive: false), '\u20B9');
    value = value.replaceAll(RegExp('dollars?', caseSensitive: false), '');
    value = value.replaceAll(RegExp('rupees?', caseSensitive: false), '');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    final RegExpMatch? numberMatch = RegExp(
      r'\d[\d,]*\.?\d*',
    ).firstMatch(value);
    if (numberMatch != null) {
      final String numberText = numberMatch.group(0)!.replaceAll(',', '');
      final double? parsed = double.tryParse(numberText);
      if (parsed != null && parsed == 0) {
        return 'Free';
      }
    }

    if (value.toLowerCase().contains('free')) {
      return 'Free';
    }

    if (!value.contains('\u20B9')) {
      final RegExpMatch? number = RegExp(r'\d[\d,]*\.?\d*').firstMatch(value);
      if (number != null) {
        final String amount = number.group(0)!;
        value = value.replaceFirst(amount, '\u20B9 $amount');
      } else {
        value = '\u20B9 $value';
      }
    }

    return value;
  }

  static String _defaultTravelToNext(int placeIndex, String seed) {
    const List<String> values = <String>[
      '12 mins',
      '18 mins',
      '9 mins',
      '15 mins',
      '20 mins',
    ];
    final int offset = seed.hashCode.abs() % values.length;
    final int index = (placeIndex + offset) % values.length;
    return values[index];
  }

  static DateTime? _parseDate(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  static String _safeDestination(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Destination';
    }
    return _titleCase(trimmed);
  }

  static String _safeCompanion(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Solo';
    }
    return _titleCase(trimmed);
  }

  static String _formatBudget(String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return '0';
    }

    final String reversed = digitsOnly.split('').reversed.join();
    final List<String> grouped = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      final int end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      grouped.add(reversed.substring(i, end));
    }
    return grouped.join(',').split('').reversed.join();
  }

  static String _formatDateRange(String startRaw, String endRaw) {
    final DateTime? start = _parseDate(startRaw);
    final DateTime? end = _parseDate(endRaw);
    if (start == null && end == null) {
      return '-';
    }

    final String startLabel = _shortMonthDay(start ?? end!);
    final String endLabel = _shortMonthDay(end ?? start!);
    return '$startLabel to $endLabel';
  }

  static String _shortMonthDay(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static String _titleCase(String input) {
    final List<String> words = input
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return input;
    }

    return words
        .map((String word) {
          if (word.length == 1) {
            return word.toUpperCase();
          }
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
