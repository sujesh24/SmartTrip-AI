import 'package:flutter/material.dart';
import 'package:smarttrip_ai/core/common/app_colors.dart';

class ItinerarySectionTitle extends StatelessWidget {
  const ItinerarySectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 25,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
  }
}
