import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/itinerary_request.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step4.dart';
import 'package:smarttrip_ai/modules/ai_generation/models/travel_companion.dart';
import 'package:smarttrip_ai/modules/ai_generation/viewmodels/itinerary_companion_view_model.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_page_layout.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_primary_button.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_section_title.dart';
import 'package:smarttrip_ai/modules/ai_generation/widgets/itinerary_step_indicator.dart';

class ItineraryThree extends StatefulWidget {
  const ItineraryThree({super.key, required this.request});

  final ItineraryRequest request;

  @override
  State<ItineraryThree> createState() => _ItineraryThreeState();
}

class _ItineraryThreeState extends State<ItineraryThree> {
  final ItineraryCompanionViewModel _viewModel = ItineraryCompanionViewModel();

  @override
  Widget build(BuildContext context) {
    return ItineraryPageLayout(
      body: ListView(
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: <Widget>[
          const ItineraryStepIndicator(activeStep: 3),
          const SizedBox(height: 42),
          const ItinerarySectionTitle(text: 'Who is going with you?'),
          const SizedBox(height: 36),
          _CompanionTile(
            label: 'Solo',
            icon: Icons.person,
            style: _styleFor(TravelCompanion.solo),
            onTap: () => _onCompanionSelected(TravelCompanion.solo),
          ),
          const SizedBox(height: 12),
          _CompanionTile(
            label: 'Friends',
            icon: Icons.group,
            style: _styleFor(TravelCompanion.friends),
            onTap: () => _onCompanionSelected(TravelCompanion.friends),
          ),
          const SizedBox(height: 12),
          _CompanionTile(
            label: 'Family',
            icon: Icons.family_restroom,
            style: _styleFor(TravelCompanion.family),
            onTap: () => _onCompanionSelected(TravelCompanion.family),
          ),
          const SizedBox(height: 60),
          ItineraryPrimaryButton(label: 'Next', onPressed: _onNextPressed),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _onCompanionSelected(TravelCompanion companion) {
    setState(() {
      _viewModel.select(companion);
    });
  }

  void _onNextPressed() {
    final String? message = _viewModel.validateBeforeNext();
    if (message != null) {
      AppSnackBar.showError(context, message);
      return;
    }

    widget.request.companion = _companionLabel(_viewModel.selectedCompanion!);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItineraryFour(request: widget.request),
      ),
    );
  }

  String _companionLabel(TravelCompanion companion) {
    switch (companion) {
      case TravelCompanion.solo:
        return 'Solo';
      case TravelCompanion.friends:
        return 'Friends';
      case TravelCompanion.family:
        return 'Family';
    }
  }

  _CompanionTileStyle _styleFor(TravelCompanion companion) {
    final bool isSelected = _viewModel.selectedCompanion == companion;
    if (isSelected) {
      return const _CompanionTileStyle(
        backgroundColor: AppColors.primaryGreen,
        borderColor: AppColors.primaryGreen,
        textColor: Colors.white,
        iconColor: Colors.white,
      );
    }

    return const _CompanionTileStyle(
      backgroundColor: Colors.transparent,
      borderColor: AppColors.borderGreen,
      textColor: AppColors.primaryGreen,
      iconColor: AppColors.borderGreen,
    );
  }
}

class _CompanionTile extends StatelessWidget {
  const _CompanionTile({
    required this.label,
    required this.icon,
    required this.style,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final _CompanionTileStyle style;
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
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: style.borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: style.textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 14),
              Icon(icon, color: style.iconColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionTileStyle {
  const _CompanionTileStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
}
