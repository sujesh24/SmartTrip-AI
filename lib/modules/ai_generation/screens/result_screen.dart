import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.request,
    required this.generatedText,
  });

  final ItineraryRequest request;
  final String generatedText;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Color _accentNavy = Color(0xFF0C1A4B);
  static const Color _mutedChip = Color(0xFFB9BDC3);
  static const Color _timelineLine = Color(0xFFB7BCC2);

  late final List<_DayPlan> _dayPlans;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _dayPlans = _buildDayPlans(widget.request);
  }

  @override
  Widget build(BuildContext context) {
    final String destination = _safeDestination(widget.request.destination);
    final String companion = _safeCompanion(widget.request.companion);
    final String title = '$destination $companion Trip';
    final String budgetLabel = '\$ ${_formatBudget(widget.request.budget)}';
    final String dateRangeLabel = _formatDateRange(
      widget.request.startDate,
      widget.request.endDate,
    );
    final List<_DayPlan> visiblePlans = _selectedDay == 0
        ? _dayPlans
        : _dayPlans
              .where((_DayPlan dayPlan) => dayPlan.dayNumber == _selectedDay)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: <Widget>[
          _ResultHeader(
            title: title,
            companion: companion,
            budgetLabel: budgetLabel,
            dateRangeLabel: dateRangeLabel,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDayTabs(destination),
                  const SizedBox(height: 18),
                  ...visiblePlans.map(_buildDaySection),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(String destination) {
    final List<Widget> chips = <Widget>[
      _DayChip(
        label: 'All',
        selected: _selectedDay == 0,
        onTap: () => setState(() => _selectedDay = 0),
        selectedColor: _accentNavy,
        unselectedColor: _mutedChip,
      ),
    ];

    for (final _DayPlan dayPlan in _dayPlans) {
      chips.add(
        _DayChip(
          label: 'Day ${dayPlan.dayNumber}: $destination',
          selected: _selectedDay == dayPlan.dayNumber,
          onTap: () => setState(() => _selectedDay = dayPlan.dayNumber),
          selectedColor: _accentNavy,
          unselectedColor: _mutedChip,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _buildDaySection(_DayPlan dayPlan) {
    final String dayDate = _formatDayDate(dayPlan.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _DayDot(),
              const SizedBox(width: 10),
              Text(
                'Day ${dayPlan.dayNumber} - $dayDate',
                style: const TextStyle(
                  color: Color(0xFF1A223D),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_square, size: 22, color: Color(0xFF1A223D)),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(dayPlan.places.length, (int index) {
            final _PlacePlan place = dayPlan.places[index];
            final bool isLast = index == dayPlan.places.length - 1;
            return _TimelinePlaceItem(
              place: place,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  List<_DayPlan> _buildDayPlans(ItineraryRequest request) {
    final DateTime now = DateTime.now();
    final DateTime startDate = _parseDate(request.startDate) ?? now;
    final DateTime parsedEnd = _parseDate(request.endDate) ?? startDate;
    final DateTime endDate = parsedEnd.isBefore(startDate) ? startDate : parsedEnd;
    final int totalDays = endDate.difference(startDate).inDays + 1;

    const List<List<_PlacePlan>> templates = <List<_PlacePlan>>[
      <_PlacePlan>[
        _PlacePlan(
          name: 'Tokyo Sky Tree',
          rating: '4.4',
          timing: '10:00 - 22:00',
          price: r'$ 17.86 per person',
        ),
        _PlacePlan(
          name: 'Sensoji Temple',
          rating: '4.5',
          timing: 'Whole Day',
          price: r'$ Free',
        ),
      ],
      <_PlacePlan>[
        _PlacePlan(
          name: 'Tokyo Disney Resort',
          rating: '4.8',
          timing: '08:00 - 22:00',
          price: r'$ 200 per person',
        ),
        _PlacePlan(
          name: 'Ueno Park',
          rating: '4.6',
          timing: '09:00 - 20:00',
          price: r'$ Free',
        ),
      ],
      <_PlacePlan>[
        _PlacePlan(
          name: 'Ginza',
          rating: '4.8',
          timing: 'Whole Day',
          price: r'$ Free',
        ),
        _PlacePlan(
          name: 'Shibuya',
          rating: '4.5',
          timing: 'Whole Day',
          price: r'$ Free',
        ),
      ],
      <_PlacePlan>[
        _PlacePlan(
          name: 'Akihabara',
          rating: '4.7',
          timing: '11:00 - 21:00',
          price: r'$ 10 per person',
        ),
        _PlacePlan(
          name: 'Asakusa Street',
          rating: '4.6',
          timing: 'Whole Day',
          price: r'$ Free',
        ),
      ],
    ];

    final List<_DayPlan> result = <_DayPlan>[];
    for (int i = 0; i < totalDays; i++) {
      final DateTime dayDate = startDate.add(Duration(days: i));
      final List<_PlacePlan> template = templates[i % templates.length];
      result.add(
        _DayPlan(
          dayNumber: i + 1,
          date: dayDate,
          places: template,
        ),
      );
    }
    return result;
  }

  DateTime? _parseDate(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  String _safeDestination(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Tokyo';
    }
    return _titleCase(trimmed);
  }

  String _safeCompanion(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Solo';
    }
    return _titleCase(trimmed);
  }

  String _formatBudget(String value) {
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

  String _formatDateRange(String startRaw, String endRaw) {
    final DateTime? start = _parseDate(startRaw);
    final DateTime? end = _parseDate(endRaw);
    if (start == null && end == null) {
      return '-';
    }

    final String startLabel = _shortMonthDay(start ?? end!);
    final String endLabel = _shortMonthDay(end ?? start!);
    return '$startLabel to $endLabel';
  }

  String _shortMonthDay(DateTime date) {
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

  String _formatDayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _titleCase(String input) {
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

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.title,
    required this.companion,
    required this.budgetLabel,
    required this.dateRangeLabel,
  });

  final String title;
  final String companion;
  final String budgetLabel;
  final String dateRangeLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 278,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: Image.asset(AppAssets.itineraryHeader, fit: BoxFit.cover),
          ),
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x2A000000), Color(0xA6000000)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HeaderMetaRow(icon: Icons.person_outline, value: companion),
                  const SizedBox(height: 4),
                  _HeaderMetaRow(icon: Icons.paid_outlined, value: budgetLabel),
                  const SizedBox(height: 4),
                  _HeaderMetaRow(
                    icon: Icons.calendar_today_outlined,
                    value: dateRangeLabel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetaRow extends StatelessWidget {
  const _HeaderMetaRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF575D6D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF31458A), Color(0xFF0C1A4B)],
        ),
      ),
    );
  }
}

class _TimelinePlaceItem extends StatelessWidget {
  const _TimelinePlaceItem({required this.place, required this.showDivider});

  final _PlacePlan place;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: 1,
                    color: _ResultScreenState._timelineLine,
                  ),
                ),
                if (showDivider)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      '10 mins',
                      style: TextStyle(
                        color: Color(0xFF9AA0AD),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (showDivider)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: _ResultScreenState._timelineLine,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: <Widget>[
                  _PlaceCard(place: place),
                  if (showDivider)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Color(0xFFC4C7CD),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final _PlacePlan place;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC6CBD2)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69A8F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          place.rating,
                          style: const TextStyle(
                            color: Color(0xFF10223F),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A223D),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: Color(0xFF1A223D),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        place.timing,
                        style: const TextStyle(
                          color: Color(0xFF1A223D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.confirmation_number,
                        size: 14,
                        color: Color(0xFF1A223D),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        place.price,
                        style: const TextStyle(
                          color: Color(0xFF1A223D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppAssets.resultPlaceholder,
                width: 85,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPlan {
  const _DayPlan({
    required this.dayNumber,
    required this.date,
    required this.places,
  });

  final int dayNumber;
  final DateTime date;
  final List<_PlacePlan> places;
}

class _PlacePlan {
  const _PlacePlan({
    required this.name,
    required this.rating,
    required this.timing,
    required this.price,
  });

  final String name;
  final String rating;
  final String timing;
  final String price;
}
