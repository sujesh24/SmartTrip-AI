import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_session_service.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/theme/app_theme_controller.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({
    super.key,
    required this.authService,
    this.sessionService,
  });

  final AuthServiceBase authService;
  final AdminSessionService? sessionService;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final AdminSessionService _sessionService;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService ?? AdminSessionService();
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await _sessionService.clearAdminSession();
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to logout. Please try again.');
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : const Color(0x338DA180);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Settings',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        children: <Widget>[
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.dark_mode_outlined, color: primaryTextColor),
              title: Text(
                'Theme',
                style: TextStyle(
                  color: primaryTextColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (bool value) {
                  AppThemeController.instance.setDarkMode(value);
                },
                activeThumbColor: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            child: ElevatedButton(
              key: const Key('admin_logout_button'),
              onPressed: _isLoggingOut ? null : _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : const Color(0x338DA180);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: child,
    );
  }
}
