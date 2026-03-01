import 'package:smarttrip_ai/modules/ai_generation/models/date_target.dart';

class ItineraryDateRangeViewModel {
  ItineraryDateRangeViewModel({DateTime? now})
    : _today = _dateOnly(now ?? DateTime.now()),
      activeTarget = DateTarget.from {
    visibleMonth = DateTime(_today.year, _today.month, 1);
  }

  final DateTime _today;
  late DateTime visibleMonth;
  DateTime? fromDate;
  DateTime? toDate;
  DateTarget activeTarget;

  DateTime get today => _today;

  List<DateTime> get calendarDays {
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

  String get monthLabel {
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
    return '${monthNames[visibleMonth.month - 1]} ${visibleMonth.year}';
  }

  bool get canGoPreviousMonth {
    final DateTime currentMonthStart = DateTime(_today.year, _today.month, 1);
    final DateTime visibleMonthStart = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    );
    return visibleMonthStart.isAfter(currentMonthStart);
  }

  void goToPreviousMonth() {
    if (!canGoPreviousMonth) {
      return;
    }
    visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1, 1);
  }

  void goToNextMonth() {
    visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 1);
  }

  bool isDayInCurrentMonth(DateTime day) => day.month == visibleMonth.month;

  bool isDayDisabled(DateTime day) => _dateOnly(day).isBefore(_today);

  bool isDaySelected(DateTime day) =>
      _isSameDay(day, fromDate) || _isSameDay(day, toDate);

  bool isDayInSelectedRange(DateTime day) {
    if (fromDate == null || toDate == null) {
      return false;
    }
    return day.isAfter(fromDate!) && day.isBefore(toDate!);
  }

  String? changeTarget(DateTarget target) {
    if (target == DateTarget.to && fromDate == null) {
      return 'Please choose from date first.';
    }
    activeTarget = target;
    return null;
  }

  String? selectDay(DateTime day) {
    final DateTime selected = _dateOnly(day);
    if (selected.isBefore(_today)) {
      return null;
    }

    if (activeTarget == DateTarget.from) {
      fromDate = selected;
      if (toDate != null && selected.isAfter(toDate!)) {
        toDate = null;
      }
      activeTarget = DateTarget.to;
      return null;
    }

    if (fromDate == null) {
      fromDate = selected;
      activeTarget = DateTarget.to;
      return null;
    }

    if (selected.isBefore(fromDate!)) {
      return 'To date cannot be before from date.';
    }

    toDate = selected;
    return null;
  }

  String? validateBeforeNext() {
    if (fromDate == null || toDate == null) {
      return 'Please select both from and to dates.';
    }
    return null;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isSameDay(DateTime first, DateTime? second) {
    if (second == null) {
      return false;
    }
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
