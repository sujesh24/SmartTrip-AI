import 'package:flutter/material.dart';
import 'package:smarttrip_ai/core/common/app_colors.dart';

class ItineraryStepIndicator extends StatelessWidget {
  const ItineraryStepIndicator({
    super.key,
    required this.activeStep,
    this.totalSteps = 5,
  });

  final int activeStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(totalSteps, (int index) {
        final int step = index + 1;
        final bool isActive = step == activeStep;
        final bool isCompleted = step < activeStep;
        final bool isHighlighted = isActive || isCompleted;

        return Expanded(
          child: Row(
            children: <Widget>[
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHighlighted
                      ? AppColors.primaryGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: isHighlighted
                        ? AppColors.primaryGreen
                        : AppColors.borderGreen,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: TextStyle(
                      color: isHighlighted
                          ? Colors.white
                          : AppColors.borderGreen,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              if (step != totalSteps)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Divider(
                            color: AppColors.primaryGreen,
                            thickness: 1.2,
                            height: 1.2,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.primaryGreen,
                            thickness: 1.2,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
