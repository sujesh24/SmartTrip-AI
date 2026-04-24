import 'package:smarttrip_ai/modules/ai_generation/models/day_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';

class SavedItinerary {
  SavedItinerary({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.companion,
    required this.interests,
    required this.budget,
    required this.savedAt,
    required this.dayPlans,
    this.coverImageUrl,
  });

  factory SavedItinerary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawInterests =
        json['interests'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawDayPlans =
        json['dayPlans'] as List<dynamic>? ?? <dynamic>[];

    return SavedItinerary(
      id: (json['id'] as String? ?? '').trim(),
      destination: _safeDestination(json['destination'] as String? ?? ''),
      startDate: (json['startDate'] as String? ?? '').trim(),
      endDate: (json['endDate'] as String? ?? '').trim(),
      companion: _safeCompanion(json['companion'] as String? ?? ''),
      interests: rawInterests
          .map((dynamic value) => value.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
      budget: (json['budget'] as String? ?? '').trim(),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      coverImageUrl: (json['coverImageUrl'] as String?)?.trim(),
      dayPlans: rawDayPlans
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> rawDayPlan) {
            return DayPlan.fromJson(
              rawDayPlan.map(
                (dynamic key, dynamic value) =>
                    MapEntry<String, dynamic>(key.toString(), value),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  factory SavedItinerary.fromRequest({
    required ItineraryRequest request,
    required List<DayPlan> dayPlans,
    String? coverImageUrl,
    DateTime? savedAt,
  }) {
    final String safeDestination = _safeDestination(request.destination);
    final String trimmedStartDate = request.startDate.trim();
    final String trimmedEndDate = request.endDate.trim();

    return SavedItinerary(
      id: buildId(
        destination: safeDestination,
        startDate: trimmedStartDate,
        endDate: trimmedEndDate,
      ),
      destination: safeDestination,
      startDate: trimmedStartDate,
      endDate: trimmedEndDate,
      companion: _safeCompanion(request.companion),
      interests: request.interests
          .map((String interest) => interest.trim())
          .where((String interest) => interest.isNotEmpty)
          .toList(growable: false),
      budget: request.budget.trim(),
      savedAt: savedAt ?? DateTime.now(),
      coverImageUrl: coverImageUrl?.trim(),
      dayPlans: dayPlans,
    );
  }

  final String id;
  final String destination;
  final String startDate;
  final String endDate;
  final String companion;
  final List<String> interests;
  final String budget;
  final DateTime savedAt;
  final String? coverImageUrl;
  final List<DayPlan> dayPlans;

  String get budgetLabel => '\u20B9 ${_formatBudget(budget)}';

  String get dateRangeLabel => _formatDateRange(startDate, endDate);

  String get interestsLabel {
    if (interests.isEmpty) {
      return 'Not selected';
    }
    return interests.join(', ');
  }

  SavedItinerary copyWith({
    String? id,
    String? destination,
    String? startDate,
    String? endDate,
    String? companion,
    List<String>? interests,
    String? budget,
    DateTime? savedAt,
    String? coverImageUrl,
    List<DayPlan>? dayPlans,
  }) {
    return SavedItinerary(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      companion: companion ?? this.companion,
      interests: interests ?? this.interests,
      budget: budget ?? this.budget,
      savedAt: savedAt ?? this.savedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      dayPlans: dayPlans ?? this.dayPlans,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'companion': companion,
      'interests': interests,
      'budget': budget,
      'savedAt': savedAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'dayPlans': dayPlans.map((DayPlan plan) => plan.toJson()).toList(),
    };
  }

  static String buildId({
    required String destination,
    required String startDate,
    required String endDate,
  }) {
    final String normalizedDestination = _normalizeLookup(destination);
    final String normalizedStartDate = startDate.trim().toLowerCase();
    final String normalizedEndDate = endDate.trim().toLowerCase();
    return '$normalizedDestination|$normalizedStartDate|$normalizedEndDate';
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
    final DateTime? start = DateTime.tryParse(startRaw.trim());
    final DateTime? end = DateTime.tryParse(endRaw.trim());
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

  static String _normalizeLookup(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _titleCase(String input) {
    final List<String> words = input
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
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

String savedItineraryHeroTag(String itineraryId) =>
    'saved-itinerary-hero-$itineraryId';
