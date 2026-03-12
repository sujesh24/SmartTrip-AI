import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/screens/step1.dart';
import 'package:smarttrip_ai/modules/home/widgets/add_itinerary_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popupAnimationController;
  bool _isPopupOpen = false;
  bool _isOpeningPopup = false;

  static const Duration _homeIconSpinDuration = Duration(milliseconds: 240);

  @override
  void initState() {
    super.initState();
    _popupAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _popupAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showAddPopup() async {
    if (_isPopupOpen || _isOpeningPopup) {
      return;
    }

    setState(() {
      _isPopupOpen = true;
      _isOpeningPopup = true;
    });
    await Future<void>.delayed(_homeIconSpinDuration);
    if (!mounted) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _popupAnimationController,
      builder: (BuildContext sheetContext) {
        return AddItineraryPopup(
          onCreatePressed: () async {
            await _dismissPopup(sheetContext);
            if (!mounted) {
              return;
            }
            navigator.push(
              MaterialPageRoute<void>(builder: (_) => const ItineraryOne()),
            );
          },
          onClosePressed: () => _dismissPopup(sheetContext),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPopupOpen = false;
        _isOpeningPopup = false;
      });
    }
  }

  Future<void> _dismissPopup(BuildContext sheetContext) async {
    if (mounted && _isPopupOpen) {
      setState(() => _isPopupOpen = false);
    }
    Navigator.of(sheetContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: const Center(
        child: Text(
          'HOME SCREEN',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontFamily: 'Times New Roman',
            fontSize: 34,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBar: _HomeBottomNavigationBar(
        onAddPressed: _showAddPopup,
        isPopupOpen: _isPopupOpen,
      ),
    );
  }
}

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.onAddPressed,
    required this.isPopupOpen,
  });

  final VoidCallback onAddPressed;
  final bool isPopupOpen;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        height: 82,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.near_me,
                  label: 'Discover',
                  selected: true,
                ),
              ),
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Notification',
                ),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: onAddPressed,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.borderGreen,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: isPopupOpen ? 0.125 : 0,
                        duration: _HomeScreenState._homeIconSpinDuration,
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.menu_book_outlined,
                  label: 'My Items',
                ),
              ),
              const Expanded(
                child: _BottomNavItem(
                  icon: Icons.settings_outlined,
                  label: 'Setting',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? AppColors.borderGreen
        : AppColors.primaryGreen.withValues(alpha: 0.55);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'Times New Roman',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
