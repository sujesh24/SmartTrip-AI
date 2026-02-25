import 'package:flutter/material.dart';
import 'package:smarttrip_ai/core/common/app_colors.dart';
import 'package:smarttrip_ai/presentation/widget/itinerary_header.dart';
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryGreen),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close, color: AppColors.primaryGreen),
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
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: _ItineraryBody(
                  destinationController: _destinationController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryBody extends StatelessWidget {
  const _ItineraryBody({required this.destinationController});

  final TextEditingController destinationController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 48),
        const ItineraryStepIndicator(activeStep: 1),
        const SizedBox(height: 42),
        const _HolidayQuestion(),
        const SizedBox(height: 72),
        _DestinationInputField(controller: destinationController),
        const SizedBox(height: 120),
        const _NextButton(),
        const SizedBox(height: 34),
      ],
    );
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
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppColors.primaryGreen, fontSize: 18),
        decoration: InputDecoration(
          isDense: true,
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
            minWidth: 38,
            minHeight: 39,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
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
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 49,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
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
