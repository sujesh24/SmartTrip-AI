import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step2.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class ItineraryOne extends StatefulWidget {
  const ItineraryOne({super.key});

  @override
  State<ItineraryOne> createState() => _ItineraryOneState();
}

class _ItineraryOneState extends State<ItineraryOne> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 1),
          const SizedBox(height: 42),
          const ItinerarySectionTitle(
            text: 'Where do you want to go for\nyour holiday?',
          ),
          const SizedBox(height: 50),
          _DestinationInputField(controller: _destinationController),
          const SizedBox(height: 140),
          ItineraryPrimaryButton(label: 'Next', onPressed: _goToStepTwo),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  void _goToStepTwo() {
    final String destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      AppSnackBar.showError(
        context,
        'Please enter destination before continuing.',
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ItineraryTwo()));
  }
}

class _DestinationInputField extends StatelessWidget {
  const _DestinationInputField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(color: AppColors.primaryGreen, fontSize: 18),
      decoration: InputDecoration(
        constraints: const BoxConstraints(minHeight: 70),
        hintText: 'i.e, Sydney, London etc.',
        hintStyle: TextStyle(
          color: AppColors.primaryGreen.withValues(alpha: 0.45),
          fontSize: 18,
        ),
        prefixIcon: const Icon(
          Icons.place_outlined,
          color: AppColors.borderGreen,
          size: 22,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 60,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
