import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/user/models/delete_account_result.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key, required this.authService});

  final AuthServiceBase authService;

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  bool _isDeleting = false;

  Future<void> _handleDeleteAccount() async {
    if (_isDeleting) {
      return;
    }

    final bool didConfirmDelete = await _showDeleteConfirmationDialog();
    if (!didConfirmDelete || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    bool shouldResetLoading = true;

    try {
      final DeleteAccountResult result = await widget.authService
          .deleteCurrentUser();
      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        shouldResetLoading = false;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => SignupScreen(authService: widget.authService),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }

      if (result.requiresRecentLogin) {
        final bool shouldRelogin = await _showReloginDialog(
          result.message ??
              'Please log in again to verify your identity before deleting your account.',
        );

        if (!mounted) {
          return;
        }

        if (shouldRelogin) {
          final bool didNavigate = await _goToLoginForRelogin();
          if (didNavigate) {
            shouldResetLoading = false;
            return;
          }
        }
        return;
      }

      AppSnackBar.showError(
        context,
        result.message ?? 'Unable to delete account. Please try again.',
      );
    } finally {
      if (shouldResetLoading && mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool> _goToLoginForRelogin() async {
    try {
      await widget.authService.signOut();
      if (!mounted) {
        return false;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(authService: widget.authService),
        ),
        (Route<dynamic> route) => false,
      );
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      AppSnackBar.showError(
        context,
        'Unable to continue to re-login. Please try again.',
      );
      return false;
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBackground = isDarkMode
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;
    final Color inputFillColor = isDarkMode
        ? AppColors.darkBackground
        : Colors.white;

    final TextEditingController deleteController = TextEditingController();
    bool canDelete = false;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: borderColor, width: 1.2),
              ),
              title: Text(
                'Delete Account',
                style: TextStyle(
                  color: primaryTextColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'This action is permanent and cannot be undone. Type DELETE to confirm.',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.75),
                      fontFamily: 'Times New Roman',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('delete_account_confirmation_input'),
                    controller: deleteController,
                    cursorColor: primaryTextColor,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE',
                      hintStyle: TextStyle(
                        color: primaryTextColor.withValues(alpha: 0.45),
                        fontFamily: 'Times New Roman',
                      ),
                      filled: true,
                      fillColor: inputFillColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1.3),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: primaryTextColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (String value) {
                      final bool nextCanDelete = value.trim() == 'DELETE';
                      if (nextCanDelete == canDelete) {
                        return;
                      }
                      setDialogState(() => canDelete = nextCanDelete);
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  key: const Key('delete_account_confirm_button'),
                  onPressed: canDelete
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.shade200,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    deleteController.dispose();
    return shouldDelete ?? false;
  }

  Future<bool> _showReloginDialog(String message) async {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBackground = isDarkMode
        ? AppColors.darkSurface
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;

    final bool? shouldRelogin = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1.2),
          ),
          title: Text(
            'Re-login Required',
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          content: Text(
            '$message\n\nTap Re-login to sign in again and then retry deleting your account.',
            style: TextStyle(
              color: primaryTextColor.withValues(alpha: 0.76),
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: primaryTextColor,
                  fontFamily: 'Times New Roman',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.borderGreen,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Re-login',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return shouldRelogin ?? false;
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

    final String email = widget.authService.currentUserEmail ?? 'Not available';
    final String provider = widget.authService.currentUserProviderLabel;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage Account',
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
          _AccountCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.email_outlined, color: primaryTextColor),
                  title: Text(
                    'Email',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.7),
                      fontFamily: 'Times New Roman',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: Icon(Icons.login_rounded, color: primaryTextColor),
                  title: Text(
                    'Sign-in Method',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    provider,
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.7),
                      fontFamily: 'Times New Roman',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AccountCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontFamily: 'Times New Roman',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account permanently removes your data from this app.',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.73),
                      fontFamily: 'Times New Roman',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    key: const Key('manage_delete_account_button'),
                    onPressed: _isDeleting ? null : _handleDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      _isDeleting ? 'Deleting...' : 'Delete Account',
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : const Color(0x338DA180),
        ),
      ),
      child: child,
    );
  }
}
