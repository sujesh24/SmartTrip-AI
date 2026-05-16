import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/user/models/delete_account_result.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key, required this.authService});

  final AuthServiceBase authService;

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  bool _isDeleting = false;
  bool _isUpdatingProfile = false;
  bool _isUploadingAvatar = false;
  late TextEditingController _usernameController;
  String? _customUsername;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final String? userId = widget.authService.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (!mounted) {
        return;
      }
      final String? name = snapshot.data()?['name'] as String?;
      final String? avatarPath = snapshot.data()?['avatarPath'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _customUsername = name.trim();
          _usernameController.text = _customUsername!;
        });
      }
      if (avatarPath != null && avatarPath.trim().isNotEmpty) {
        setState(() => _localAvatarPath = avatarPath.trim());
      }
    } catch (_) {
      // Silently fail; leave username empty.
    }
  }

  Future<void> _updateUsername() async {
    if (_isUpdatingProfile) {
      return;
    }

    final String newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      AppSnackBar.showError(context, 'Username cannot be empty.');
      return;
    }

    setState(() => _isUpdatingProfile = true);
    try {
      await widget.authService.updateUserProfile(
        name: newUsername,
        avatarPath: _localAvatarPath,
      );
      if (!mounted) {
        return;
      }
      setState(() => _customUsername = newUsername);
      AppSnackBar.showSuccess(context, 'Username updated.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to update username right now.');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
      }
    }
  }

  Future<void> _pickAndSaveAvatar() async {
    if (_isUploadingAvatar) return;
    final String? userId = widget.authService.currentUserId;
    if (userId == null) return;

    try {
      setState(() => _isUploadingAvatar = true);
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
      );
      if (picked == null) return;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String avatarsDirPath =
          '${appDocDir.path}${Platform.pathSeparator}avatars';
      final Directory avatarsDir = Directory(avatarsDirPath);
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      final String fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File saved = await File(
        picked.path,
      ).copy('${avatarsDir.path}${Platform.pathSeparator}$fileName');
      final String savedPath = saved.path;
      await widget.authService.updateUserProfile(
        avatarPath: savedPath,
        name: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _localAvatarPath = savedPath);
      AppSnackBar.showSuccess(context, 'Profile picture updated.');
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Unable to update profile picture.');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

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
        shouldResetLoading = false;
        setState(() => _isDeleting = false);

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

    await Future<void>.delayed(const Duration(milliseconds: 300));
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isDarkMode
                            ? AppColors.darkBackground
                            : Colors.grey.shade200,
                        backgroundImage:
                            _localAvatarPath != null &&
                                _localAvatarPath!.isNotEmpty
                            ? FileImage(File(_localAvatarPath!))
                                  as ImageProvider
                            : null,
                        child: _localAvatarPath == null
                            ? Icon(
                                Icons.person,
                                color: primaryTextColor,
                                size: 36,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploadingAvatar
                              ? null
                              : _pickAndSaveAvatar,
                          icon: _isUploadingAvatar
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.photo_library),
                          label: const Text('Change Profile Picture'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTextColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('manage_account_username_input'),
                    controller: _usernameController,
                    cursorColor: primaryTextColor,
                    enabled: !_isUpdatingProfile,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      labelStyle: TextStyle(
                        color: primaryTextColor,
                        fontFamily: 'Times New Roman',
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.darkBackground
                          : Colors.white,
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
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1.3),
                      ),
                    ),
                    style: TextStyle(
                      color: primaryTextColor,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('manage_account_save_username_button'),
                    onPressed: _isUpdatingProfile ? null : _updateUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTextColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isUpdatingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Username',
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontFamily: 'Times New Roman',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deleting your account permanently removes your data from this app.',
                    style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.73),
                      fontFamily: 'Times New Roman',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    key: const Key('manage_delete_account_button'),
                    onPressed: _isDeleting ? null : _handleDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                        fontSize: 15,
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
