import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/date_target.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step3.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/itinerary_date_range_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class ItineraryTwo extends StatefulWidget {
  const ItineraryTwo({super.key});

  @override
  State<ItineraryTwo> createState() => _ItineraryTwoState();
}

class _ItineraryTwoState extends State<ItineraryTwo> {
  late final ItineraryDateRangeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ItineraryDateRangeViewModel();
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = _viewModel.calendarDays;

    return ItineraryPageLayout(
      body: ListView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 2),
          const SizedBox(height: 42),
          const ItinerarySectionTitle(text: 'When do you plan to go?'),
          const SizedBox(height: 30),
          _DateTargetSwitch(
            activeTarget: _viewModel.activeTarget,
            onTargetChanged: _onTargetChanged,
          ),
          const SizedBox(height: 16),
          _MonthSwitcher(
            monthLabel: _viewModel.monthLabel,
            canGoPrevious: _viewModel.canGoPreviousMonth,
            onPrevious: () {
              setState(_viewModel.goToPreviousMonth);
            },
            onNext: () {
              setState(_viewModel.goToNextMonth);
            },
          ),
          const SizedBox(height: 12),
          const _WeekDaysHeader(),
          const SizedBox(height: 0),
          GridView.builder(
            primary: false,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 8,
              mainAxisExtent: 36,
            ),
            itemCount: days.length,
            itemBuilder: (BuildContext context, int index) {
              final DateTime day = days[index];
              final bool isDisabled = _viewModel.isDayDisabled(day);

              return _CalendarDay(
                day: day.day.toString(),
                inCurrentMonth: _viewModel.isDayInCurrentMonth(day),
                isDisabled: isDisabled,
                isSelected: _viewModel.isDaySelected(day),
                isInRange: _viewModel.isDayInSelectedRange(day),
                onTap: isDisabled ? null : () => _onDaySelected(day),
              );
            },
          ),
          const SizedBox(height: 50),
          ItineraryPrimaryButton(label: 'Next', onPressed: _onNextPressed),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      final String? message = _viewModel.selectDay(day);
      if (message != null) {
        _showValidationMessage(message);
      }
    });
  }

  void _onTargetChanged(DateTarget target) {
    setState(() {
      final String? message = _viewModel.changeTarget(target);
      if (message != null) {
        _showValidationMessage(message);
      }
    });
  }

  void _onNextPressed() {
    final String? message = _viewModel.validateBeforeNext();
    if (message != null) {
      _showValidationMessage(message);
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ItineraryThree()));
  }

  void _showValidationMessage(String message) {
    AppSnackBar.showError(context, message);
  }
}

class _DateTargetSwitch extends StatelessWidget {
  const _DateTargetSwitch({
    required this.activeTarget,
    required this.onTargetChanged,
  });

  final DateTarget activeTarget;
  final ValueChanged<DateTarget> onTargetChanged;

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
            selected: activeTarget == DateTarget.from,
            onTap: () => onTargetChanged(DateTarget.from),
          ),
          _SwitchItem(
            label: 'To',
            selected: activeTarget == DateTarget.to,
            onTap: () => onTargetChanged(DateTarget.to),
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
