import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.request,
    required this.generatedText,
  });

  final ItineraryRequest request;
  final String generatedText;

  @override
  Widget build(BuildContext context) {
    final String plainTextOutput = generatedText.trim().isEmpty
        ? 'No itinerary text returned.\n\nRequest destination: ${request.destination}'
        : generatedText;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              plainTextOutput,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
