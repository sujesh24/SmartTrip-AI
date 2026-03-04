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
       budgetLabel = '₹ ${_formatBudget(request.budget)}',
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

  // Combines destination and companion into a display title for the trip.
  String get title => '$destination $companion Trip';

  // Returns all day plans or filters to a single day if a specific day is selected.
  List<DayPlan> visiblePlans(int selectedDay) {
    if (selectedDay == 0) {
      return dayPlans;
    }
    return dayPlans
        .where((DayPlan dayPlan) => dayPlan.dayNumber == selectedDay)
        .toList();
  }

  // Builds the label text shown on each day chip.
  String dayChipLabel(DayPlan dayPlan) {
    return 'Day ${dayPlan.dayNumber}: $destination';
  }

  // Formats a DateTime into a dd/mm/yyyy string for display.
  String formatDayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  // Entry point for building day plans: tries parsing AI response, falls back to templates if parsing fails.
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
      return parsed;
    }
    return _buildFallbackDayPlans(request, destination);
  }

  // Attempts to parse a structured list of DayPlans from the AI-generated JSON response.
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

  // Cleans markdown fences from the AI response and decodes the JSON into a map.
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

  // Safely decodes a JSON string into a Map, wrapping bare lists under the 'days' key.
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

  // Converts a raw list of place objects from JSON into a typed list of PlacePlan models.
  static List<PlacePlan> _parsePlaces(dynamic rawPlaces, String destination) {
    if (rawPlaces is! List) {
      return <PlacePlan>[];
    }

    final List<PlacePlan> places = <PlacePlan>[];
    for (int i = 0; i < rawPlaces.length; i++) {
      final dynamic rawPlace = rawPlaces[i];
      if (rawPlace is! Map<String, dynamic>) {
        continue;
      }

      final String name =
          _asString(
            rawPlace['name'] ??
                rawPlace['title'] ??
                rawPlace['place'] ??
                rawPlace['spot'],
          ) ??
          'Place ${i + 1} - $destination';
      final String rating = _normalizeRating(
        rawPlace['rating'] ?? rawPlace['score'] ?? rawPlace['stars'],
      );
      final String timing =
          _asString(
            rawPlace['timing'] ??
                rawPlace['time'] ??
                rawPlace['hours'] ??
                rawPlace['duration'],
          ) ??
          'Whole Day';
      final String price = _normalizePrice(
        _asString(
          rawPlace['price'] ??
              rawPlace['cost'] ??
              rawPlace['entryFee'] ??
              rawPlace['entry_fee'],
        ),
      );
      final String travelToNext =
          _asString(
            rawPlace['travel_to_next'] ??
                rawPlace['travelToNext'] ??
                rawPlace['transfer_time'] ??
                rawPlace['transferTime'] ??
                rawPlace['nextTravelTime'] ??
                rawPlace['time_to_next'],
          ) ??
          _defaultTravelToNext(i, name);

      places.add(
        PlacePlan(
          name: name,
          rating: rating,
          timing: timing,
          price: price,
          travelToNext: travelToNext,
        ),
      );
    }

    return places;
  }

  // Generates generic placeholder day plans when the AI response cannot be parsed.
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

    final List<List<PlacePlan>> templates = <List<PlacePlan>>[
      <PlacePlan>[
        PlacePlan(
          name: '$destination Main Beach',
          rating: '4.4',
          timing: '09:00 - 12:00',
          price: 'Free',
          travelToNext: '14 mins',
        ),
        PlacePlan(
          name: '$destination Old Town',
          rating: '4.5',
          timing: '13:00 - 18:00',
          price: 'Free',
          travelToNext: '16 mins',
        ),
      ],
      <PlacePlan>[
        PlacePlan(
          name: '$destination Fort',
          rating: '4.8',
          timing: '10:00 - 15:00',
          price: '₹ 800 per person',
          travelToNext: '22 mins',
        ),
        PlacePlan(
          name: '$destination Food Street',
          rating: '4.6',
          timing: '18:00 - 22:00',
          price: '₹ 1500 per person',
          travelToNext: '11 mins',
        ),
      ],
      <PlacePlan>[
        PlacePlan(
          name: '$destination Market',
          rating: '4.8',
          timing: '10:00 - 14:00',
          price: '₹ 500 per person',
          travelToNext: '13 mins',
        ),
        PlacePlan(
          name: '$destination Sunset Point',
          rating: '4.5',
          timing: '16:30 - 19:00',
          price: 'Free',
          travelToNext: '17 mins',
        ),
      ],
      <PlacePlan>[
        PlacePlan(
          name: '$destination Museum',
          rating: '4.7',
          timing: '10:00 - 13:00',
          price: '₹ 1200 per person',
          travelToNext: '10 mins',
        ),
        PlacePlan(
          name: '$destination Night Walk',
          rating: '4.6',
          timing: '19:00 - 21:00',
          price: '₹ 600 per person',
          travelToNext: '8 mins',
        ),
      ],
    ];

    final List<DayPlan> result = <DayPlan>[];
    for (int i = 0; i < totalDays; i++) {
      final DateTime dayDate = startDate.add(Duration(days: i));
      final List<PlacePlan> template = templates[i % templates.length];
      result.add(DayPlan(dayNumber: i + 1, date: dayDate, places: template));
    }
    return result;
  }

  // Safely casts a dynamic value (int, num, or String) to int.
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

  // Converts a dynamic string value to a DateTime using _parseDate.
  static DateTime? _asDate(dynamic value) {
    if (value is String) {
      return _parseDate(value);
    }
    return null;
  }

  // Converts any dynamic value to a trimmed String, returning null if empty.
  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  // Normalizes a rating value from various formats to a one-decimal string (e.g. "4.5").
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

  // Normalizes price strings to the ₹ format, replacing foreign currency symbols and handling 'Free'.
  static String _normalizePrice(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Free';
    }

    String value = input.trim();
    value = value.replaceAll('\$', '₹');
    value = value.replaceAll(RegExp('usd', caseSensitive: false), '₹');
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

    if (!value.contains('₹')) {
      final RegExpMatch? number = RegExp(r'\d[\d,]*\.?\d*').firstMatch(value);
      if (number != null) {
        final String amount = number.group(0)!;
        value = value.replaceFirst(amount, '₹ $amount');
      } else {
        value = '₹ $value';
      }
    }

    return value;
  }

  // Returns a deterministic default travel-time string when none is provided in the AI response.
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

  // Parses an ISO date string into a DateTime, returning null if blank or invalid.
  static DateTime? _parseDate(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  // Returns a title-cased destination name, falling back to 'Destination' if empty.
  static String _safeDestination(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Destination';
    }
    return _titleCase(trimmed);
  }

  // Returns a title-cased companion label, falling back to 'Solo' if empty.
  static String _safeCompanion(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Solo';
    }
    return _titleCase(trimmed);
  }

  // Formats a raw budget string into an Indian comma-separated number (e.g. "1,00,000").
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

  // Builds a human-readable date range label like "Jan 5 to Jan 10".
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

  // Formats a DateTime to a short "Mon D" string (e.g. "Jan 5").
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

  // Converts a string to title case (first letter of each word capitalized).
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
