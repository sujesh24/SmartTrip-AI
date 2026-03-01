import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/interest_option.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step5.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/itinerary_interest_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class ItineraryFour extends StatefulWidget {
  const ItineraryFour({super.key, required this.request});

  final ItineraryRequest request;

  @override
  State<ItineraryFour> createState() => _ItineraryFourState();
}

class _ItineraryFourState extends State<ItineraryFour> {
  final ItineraryInterestViewModel _viewModel = ItineraryInterestViewModel();

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 4),
          const SizedBox(height: 25),
          const ItinerarySectionTitle(text: 'What are you interest in?'),
          const SizedBox(height: 8),
          Text(
            '*Choose all that applied!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryGreen.withValues(alpha: 0.55),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ..._buildInterestOptions(),
          const SizedBox(height: 10),
          ItineraryPrimaryButton(label: 'Next', onPressed: _onNextPressed),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  List<Widget> _buildInterestOptions() {
    return _viewModel.options.map((InterestOption option) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _InterestOptionTile(
          label: option.label,
          selected: _viewModel.isSelected(option),
          onTap: () {
            setState(() {
              _viewModel.toggle(option);
            });
          },
        ),
      );
    }).toList();
  }

  void _onNextPressed() {
    final String? message = _viewModel.validateBeforeNext();
    if (message != null) {
      AppSnackBar.showError(context, message);
      return;
    }

    widget.request.interests = _viewModel.selectedOptions
        .map((InterestOption option) => option.label)
        .toList();

    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<void>(
        builder: (_) => ItineraryFive(request: widget.request),
      ),
    );
  }
}

class _InterestOptionTile extends StatelessWidget {
  const _InterestOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGreen, width: 1),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 16),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: selected ? AppColors.primaryGreen : Colors.transparent,
                  border: Border.all(color: AppColors.borderGreen, width: 1),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 20),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
