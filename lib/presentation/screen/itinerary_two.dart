import 'package:flutter/material.dart';
import 'package:smarttrip_ai/core/common/app_colors.dart';
import 'package:smarttrip_ai/core/common/app_snack_bar.dart';
import 'package:smarttrip_ai/presentation/widget/itinerary_header.dart';
import 'package:smarttrip_ai/presentation/widget/itinerary_step_indicator.dart';

enum _DateTarget { from, to }

class ItineraryTwo extends StatefulWidget {
  const ItineraryTwo({super.key});

  @override
  State<ItineraryTwo> createState() => _ItineraryTwoState();
}

class _ItineraryTwoState extends State<ItineraryTwo> {
  late DateTime _visibleMonth;
  late DateTime _today;
  DateTime? _fromDate;
  DateTime? _toDate;
  _DateTarget _activeTarget = _DateTarget.from;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _visibleMonth = DateTime(_today.year, _today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _buildCalendarDays(_visibleMonth);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const Expanded(flex: 40, child: ItineraryHeader()),
          Expanded(
            flex: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ListView(
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                children: <Widget>[
                  const ItineraryStepIndicator(activeStep: 2),
                  const SizedBox(height: 42),
                  const Text(
                    'When do you plan to go?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _DateTargetSwitch(
                    activeTarget: _activeTarget,
                    onTargetChanged: _onTargetChanged,
                  ),
                  const SizedBox(height: 16),
                  _MonthSwitcher(
                    monthLabel: _monthLabel(_visibleMonth),
                    canGoPrevious: _canGoPreviousMonth(_visibleMonth, _today),
                    onPrevious: () {
                      setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month - 1,
                          1,
                        );
                      });
                    },
                    onNext: () {
                      setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                          1,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const _WeekDaysHeader(),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.95,
                        ),
                    itemCount: days.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DateTime day = days[index];
                      final bool inCurrentMonth =
                          day.month == _visibleMonth.month;
                      final bool isDisabled = day.isBefore(_today);
                      final bool isFrom = _isSameDay(day, _fromDate);
                      final bool isTo = _isSameDay(day, _toDate);
                      final bool isInRange = _isInRange(
                        day,
                        _fromDate,
                        _toDate,
                      );

                      return _CalendarDay(
                        day: day.day.toString(),
                        inCurrentMonth: inCurrentMonth,
                        isDisabled: isDisabled,
                        isSelected: isFrom || isTo,
                        isInRange: isInRange,
                        onTap: isDisabled ? null : () => _onDaySelected(day),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                  _NextButton(onPressed: _onNextPressed),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime day) {
    final DateTime selected = _dateOnly(day);
    if (selected.isBefore(_today)) {
      return;
    }

    setState(() {
      if (_activeTarget == _DateTarget.from) {
        _fromDate = selected;
        if (_toDate != null && selected.isAfter(_toDate!)) {
          _toDate = null;
        }
        _activeTarget = _DateTarget.to;
        return;
      }

      if (_fromDate == null) {
        _fromDate = selected;
        _activeTarget = _DateTarget.to;
        return;
      }

      if (selected.isBefore(_fromDate!)) {
        _showValidationMessage('To date cannot be before from date.');
        return;
      }

      _toDate = selected;
    });
  }

  void _onTargetChanged(_DateTarget target) {
    if (target == _DateTarget.to && _fromDate == null) {
      _showValidationMessage('Please choose from date first.');
      return;
    }
    setState(() {
      _activeTarget = target;
    });
  }

  void _onNextPressed() {
    if (_fromDate == null || _toDate == null) {
      _showValidationMessage('Please select both from and to dates.');
      return;
    }
  }

  void _showValidationMessage(String message) {
    AppSnackBar.showError(context, message);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime first, DateTime? second) {
    if (second == null) {
      return false;
    }
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static bool _isInRange(DateTime day, DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      return false;
    }
    return day.isAfter(from) && day.isBefore(to);
  }

  static bool _canGoPreviousMonth(DateTime visibleMonth, DateTime today) {
    final DateTime currentMonthStart = DateTime(today.year, today.month, 1);
    final DateTime visibleMonthStart = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );
    return visibleMonthStart.isAfter(currentMonthStart);
  }

  static List<DateTime> _buildCalendarDays(DateTime visibleMonth) {
    final DateTime firstDayOfMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );
    final int offset = firstDayOfMonth.weekday % 7;
    final DateTime firstVisibleDay = firstDayOfMonth.subtract(
      Duration(days: offset),
    );

    return List<DateTime>.generate(35, (int index) {
      return firstVisibleDay.add(Duration(days: index));
    });
  }

  static String _monthLabel(DateTime date) {
    const List<String> monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }
}

class _DateTargetSwitch extends StatelessWidget {
  const _DateTargetSwitch({
    required this.activeTarget,
    required this.onTargetChanged,
  });

  final _DateTarget activeTarget;
  final ValueChanged<_DateTarget> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.borderGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          _SwitchItem(
            label: 'From',
            selected: activeTarget == _DateTarget.from,
            onTap: () => onTargetChanged(_DateTarget.from),
          ),
          _SwitchItem(
            label: 'To',
            selected: activeTarget == _DateTarget.to,
            onTap: () => onTargetChanged(_DateTarget.to),
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.monthLabel,
    required this.canGoPrevious,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthLabel;
  final bool canGoPrevious;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: canGoPrevious ? onPrevious : null,
          icon: Icon(
            Icons.chevron_left,
            color: canGoPrevious
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withValues(alpha: 0.25),
            size: 22,
          ),
        ),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.75),
              fontSize: 15,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right,
            color: AppColors.primaryGreen,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader();

  @override
  Widget build(BuildContext context) {
    const List<String> weekDays = <String>[
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ];

    return Row(
      children: weekDays.map((String day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.inCurrentMonth,
    required this.isDisabled,
    required this.isSelected,
    required this.isInRange,
    required this.onTap,
  });

  final String day;
  final bool inCurrentMonth;
  final bool isDisabled;
  final bool isSelected;
  final bool isInRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color baseTextColor = isDisabled
        ? AppColors.primaryGreen.withValues(alpha: 0.16)
        : inCurrentMonth
        ? AppColors.primaryGreen.withValues(alpha: 0.9)
        : AppColors.primaryGreen.withValues(alpha: 0.28);

    final Color cellBackground = isSelected
        ? AppColors.primaryGreen
        : isInRange
        ? AppColors.borderGreen.withValues(alpha: 0.24)
        : Colors.transparent;

    final Color textColor = isSelected ? Colors.white : baseTextColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: cellBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(160, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
