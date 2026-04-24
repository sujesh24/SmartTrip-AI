import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/theme/app_theme_controller.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/settings/screens/manage_account_screen.dart';
import 'package:smarttrip_ai/modules/settings/services/settings_preferences_service.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
    this.preferencesService,
    this.launchSupportUri,
  });

  final AuthServiceBase authService;
  final SettingsPreferencesService? preferencesService;
  final Future<bool> Function(Uri uri)? launchSupportUri;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsPreferencesService _preferencesService;
  late final Future<bool> Function(Uri uri) _launchSupportUri;

  bool _isLoadingNotifications = true;
  bool _notificationsEnabled = true;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _preferencesService =
        widget.preferencesService ?? SharedPrefsSettingsPreferencesService();
    _launchSupportUri = widget.launchSupportUri ?? _defaultLaunchSupportUri;
    _loadNotificationsPreference();
  }

  Future<bool> _defaultLaunchSupportUri(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadNotificationsPreference() async {
    try {
      final bool isEnabled = await _preferencesService
          .loadNotificationsEnabled();
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationsEnabled = isEnabled;
        _isLoadingNotifications = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingNotifications = false);
      AppSnackBar.showError(
        context,
        'Unable to load notification preference right now.',
      );
    }
  }

  Future<void> _toggleNotifications(bool isEnabled) async {
    setState(() => _notificationsEnabled = isEnabled);

    try {
      await _preferencesService.saveNotificationsEnabled(isEnabled);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _notificationsEnabled = !isEnabled);
      AppSnackBar.showError(
        context,
        'Unable to save notification preference. Please try again.',
      );
    }
  }

  Future<void> _toggleTheme(bool isDarkMode) async {
    try {
      await AppThemeController.instance.setDarkMode(isDarkMode);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        'Unable to update theme. Please try again.',
      );
    }
  }

  void _openManageAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageAccountScreen(authService: widget.authService),
      ),
    );
  }

  Future<void> _openHelpAndSupport() async {
    final Uri supportUri = Uri(
      scheme: 'mailto',
      path: 'support@planmytrip.ai',
      queryParameters: <String, String>{
        'subject': 'PlanMyTrip AI Support',
        'body': 'Hi PlanMyTrip AI team,',
      },
    );

    try {
      final bool didLaunch = await _launchSupportUri(supportUri);
      if (!didLaunch && mounted) {
        AppSnackBar.showError(context, 'Unable to open your email app.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to open your email app.');
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => SignupScreen(authService: widget.authService),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to sign out. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
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
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : const Color(0x338DA180);
    final Color accentColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.borderGreen;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: <Widget>[
          _SettingsCard(
            backgroundColor: cardColor,
            borderColor: borderColor,
            child: Column(
              children: <Widget>[
                ListTile(
                  key: const Key('settings_account_tile'),
                  onTap: _openManageAccount,
                  leading: Icon(Icons.person_outline, color: primaryTextColor),
                  title: Text(
                    'Account',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    widget.authService.currentUserEmail ??
                        'Manage your account details',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.7),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: primaryTextColor),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(
                    Icons.notifications_none,
                    color: primaryTextColor,
                  ),
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Receive trip reminders and updates',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.7),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: _isLoadingNotifications
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          key: const Key('settings_notifications_toggle'),
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeColor: accentColor,
                          activeTrackColor: accentColor.withValues(alpha: 0.45),
                          inactiveThumbColor: primaryTextColor.withValues(
                            alpha: 0.85,
                          ),
                          inactiveTrackColor: borderColor.withValues(
                            alpha: 0.65,
                          ),
                        ),
                ),
                Divider(height: 1, color: borderColor),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable:
                      AppThemeController.instance.themeModeListenable,
                  builder:
                      (
                        BuildContext context,
                        ThemeMode themeMode,
                        Widget? child,
                      ) {
                        final bool isDarkMode = themeMode == ThemeMode.dark;
                        return ListTile(
                          leading: Icon(
                            Icons.dark_mode_outlined,
                            color: primaryTextColor,
                          ),
                          title: Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontFamily: 'Times New Roman',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isDarkMode
                                ? 'Dark theme is enabled'
                                : 'Light theme is enabled',
                            style: TextStyle(
                              color: primaryTextColor.withValues(alpha: 0.7),
                              fontFamily: 'Times New Roman',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Switch(
                            key: const Key('settings_theme_toggle'),
                            value: isDarkMode,
                            onChanged: _toggleTheme,
                            activeColor: accentColor,
                            activeTrackColor: accentColor.withValues(
                              alpha: 0.45,
                            ),
                            inactiveThumbColor: primaryTextColor.withValues(
                              alpha: 0.85,
                            ),
                            inactiveTrackColor: borderColor.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        );
                      },
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  key: const Key('settings_help_support_tile'),
                  onTap: _openHelpAndSupport,
                  leading: Icon(
                    Icons.support_agent_outlined,
                    color: primaryTextColor,
                  ),
                  title: Text(
                    'Help & Support',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Contact support@planmytrip.ai',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.7),
                      fontFamily: 'Times New Roman',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          key: const Key('settings_logout_button'),
          onPressed: _isSigningOut ? null : _signOut,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTextColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSigningOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
