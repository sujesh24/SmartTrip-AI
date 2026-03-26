import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: AppColors.borderGreen.withValues(alpha: 0.55),
            thickness: 1.3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.9),
              fontFamily: 'Times New Roman',
              fontSize: 29,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.borderGreen.withValues(alpha: 0.55),
            thickness: 1.3,
          ),
        ),
      ],
    );
  }
}
