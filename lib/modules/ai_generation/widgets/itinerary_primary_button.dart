import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ItineraryPrimaryButton extends StatelessWidget {
  const ItineraryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(160, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: AppColors.primaryGreen,
        disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.7),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Center(
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Align(child: button);
  }
}
