import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/place_plan.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/result/result_place_card.dart';

class ResultTimelineItem extends StatelessWidget {
  const ResultTimelineItem({
    super.key,
    required this.place,
    required this.showDivider,
    this.timelineLineColor = const Color(0xFFB7BCC2),
  });

  final PlacePlan place;
  final bool showDivider;
  final Color timelineLineColor;

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
                  child: Container(width: 1, color: timelineLineColor),
                ),
                if (showDivider)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      place.travelToNext,
                      style: const TextStyle(
                        color: Color(0xFF9AA0AD),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (showDivider)
                  Expanded(
                    child: Container(width: 1, color: timelineLineColor),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: <Widget>[
                  ResultPlaceCard(place: place),
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
