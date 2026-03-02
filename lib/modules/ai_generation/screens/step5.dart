import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/loading_screen.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/itinerary_budget_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class ItineraryFive extends StatefulWidget {
  const ItineraryFive({super.key, required this.request});

  final ItineraryRequest request;

  @override
  State<ItineraryFive> createState() => _ItineraryFiveState();
}

class _ItineraryFiveState extends State<ItineraryFive> {
  final TextEditingController _budgetController = TextEditingController();
  final ItineraryBudgetViewModel _viewModel = ItineraryBudgetViewModel();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 5),
          const SizedBox(height: 42),
          const ItinerarySectionTitle(text: 'What is your estimate\nbudget?'),
          const SizedBox(height: 40),
          _BudgetInputField(controller: _budgetController),
          const SizedBox(height: 130),
          ItineraryPrimaryButton(label: 'Submit', onPressed: _onSubmitPressed),
          const SizedBox(height: 34),
        ],
      ),
    );
  }

  void _onSubmitPressed() {
    final String? message = _viewModel.validateBudget(_budgetController.text);
    if (message != null) {
      AppSnackBar.showError(context, message);
      return;
    }

    widget.request.budget = _budgetController.text.trim();
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoadingScreen(request: widget.request),
      ),
    );
  }
}

class _BudgetInputField extends StatelessWidget {
  const _BudgetInputField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(color: AppColors.primaryGreen, fontSize: 18),
      decoration: InputDecoration(
        constraints: const BoxConstraints(minHeight: 55),
        hintText: 'i.e.5,000 (numbers only)',
        hintStyle: TextStyle(
          color: AppColors.primaryGreen.withValues(alpha: 0.45),
          fontSize: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 10),
          child: Center(
            widthFactor: 1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.borderGreen.withValues(alpha: 0.95),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '\u20B9',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
