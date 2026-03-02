import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/day_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_timeline_item.dart';

class ResultDaySection extends StatelessWidget {
  const ResultDaySection({
    super.key,
    required this.dayPlan,
    required this.formattedDate,
  });

  final DayPlan dayPlan;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const _DayDot(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Day ${dayPlan.dayNumber} - $formattedDate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A223D),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_square, size: 22, color: Color(0xFF1A223D)),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(dayPlan.places.length, (int index) {
            final bool isLast = index == dayPlan.places.length - 1;
            return ResultTimelineItem(
              place: dayPlan.places[index],
              showDivider: !isLast,
            );
          }),
        ],
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
