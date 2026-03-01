import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_header.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_top_app_bar.dart';

class ItineraryPageLayout extends StatelessWidget {
  const ItineraryPageLayout({
    super.key,
    required this.body,
    this.headerFlex = 40,
    this.bodyFlex = 60,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 28),
  });

  final Widget body;
  final int headerFlex;
  final int bodyFlex;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.lightBackground,
      appBar: const ItineraryTopAppBar(),
      body: Column(
        children: <Widget>[
          Expanded(flex: headerFlex, child: const ItineraryHeader()),
          Expanded(
            flex: bodyFlex,
            child: Padding(padding: bodyPadding, child: body),
          ),
        ],
      ),
    );
  }
}
