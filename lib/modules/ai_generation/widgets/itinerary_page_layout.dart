import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_header.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_top_app_bar.dart';

class ItineraryPageLayout extends StatelessWidget {
  const ItineraryPageLayout({
    super.key,
    required this.body,
    this.headerFlex = 40,
    this.bodyFlex = 60,
    this.bodyPadding = const EdgeInsets.symmetric(horizontal: 28),
    this.onClose,
  });

  final Widget body;
  final int headerFlex;
  final int bodyFlex;
  final EdgeInsets bodyPadding;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.lightBackground,
      appBar: ItineraryTopAppBar(
        onClose: onClose ?? () => _goHome(context),
      ),
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

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }
}

