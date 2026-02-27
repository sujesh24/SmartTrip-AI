import 'package:flutter/material.dart';
import 'package:smarttrip_ai/core/common/app_colors.dart';
import 'package:smarttrip_ai/core/common/app_snack_bar.dart';
import 'package:smarttrip_ai/presentation/widget/itinerary_header.dart';
import 'package:smarttrip_ai/presentation/screen/itinerary_two.dart';
import 'package:smarttrip_ai/presentation/widget/itinerary_step_indicator.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 40, child: const ItineraryHeader()),
          Expanded(
            flex: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                children: <Widget>[
                  const ItineraryStepIndicator(activeStep: 1),
                  const SizedBox(height: 42),
                  const _HolidayQuestion(),
                  const SizedBox(height: 50),
                  _DestinationInputField(controller: _destinationController),
                  const SizedBox(height: 140),
                  _NextButton(onPressed: _goToStepTwo),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
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

class _HolidayQuestion extends StatelessWidget {
  const _HolidayQuestion();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Where do you want to go for\nyour holiday?',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.primaryGreen,
        fontSize: 25,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
    );
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

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(160, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
