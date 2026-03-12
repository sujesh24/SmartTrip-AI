import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';

class AddItineraryPopup extends StatefulWidget {
  const AddItineraryPopup({
    super.key,
    required this.onCreatePressed,
    required this.onClosePressed,
  });

  final Future<void> Function() onCreatePressed;
  final Future<void> Function() onClosePressed;

  @override
  State<AddItineraryPopup> createState() => _AddItineraryPopupState();
}

class _AddItineraryPopupState extends State<AddItineraryPopup> {
  static const Duration _closeIconSpinDuration = Duration(milliseconds: 240);
  double _closeIconTurns = 0;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _closeIconTurns = 0.125);
    });
  }

  Future<void> _closeWithSpin() async {
    if (_isClosing) {
      return;
    }

    setState(() {
      _isClosing = true;
      _closeIconTurns = 0;
    });
    await Future<void>.delayed(_closeIconSpinDuration);
    await widget.onClosePressed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 120,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Create Your Itinerary',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 22,
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isClosing ? null : widget.onCreatePressed,
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 21,
                  ),
                  label: const Text(
                    'AI Itinerary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.borderGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              InkWell(
                onTap: _isClosing ? null : _closeWithSpin,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.borderGreen,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 8),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: _closeIconTurns,
                    duration: _closeIconSpinDuration,
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
