import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_assets.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/result_screen.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 5),
          const SizedBox(height: 30),
          const ItinerarySectionTitle(text: 'Working In Progress'),
          const SizedBox(height: 8),
          Text(
            'Please wait a little bit while our AI\nassistance is working on your itinerary.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppAssets.loadingPreviewImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    AppAssets.loadingPreviewImages[index],
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
