import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.request});

  final ItineraryRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Success',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Step 1 Destination: ${request.destination}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
              Text(
                'Step 2 Dates: ${request.startDate} to ${request.endDate}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
              Text(
                'Step 3 Companion: ${request.companion}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
              Text(
                'Step 4 Interests: ${request.interests.join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
              Text(
                'Step 5 Budget: ${request.budget}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
