import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';
import 'package:smarttrip_ai/modules/admin/screens/admin_verification_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/user/common/auth_validators.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_or_divider.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_primary_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_social_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_text_field.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';
import 'package:smarttrip_ai/firebase_options.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  final AuthServiceBase? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  late final AuthServiceBase _authService;

  bool _obscurePassword = true;
  bool _isPrimaryLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  bool get _isAnyLoading => _isPrimaryLoading || _isGoogleLoading;

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(authService: _authService),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateAfterLogin(String? email) {
    if (AdminCredentials.isAdminEmail(email)) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AdminVerificationScreen(authService: _authService),
        ),
        (Route<dynamic> route) => false,
      );
      return;
    }

    _navigateToHome();
  }

  Future<void> _handleEmailLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    final String? emailError = validateEmail(email);
    if (emailError != null) {
      AppSnackBar.showError(context, emailError);
      return;
    }

    final String? passwordError = validatePassword(password);
    if (passwordError != null) {
      AppSnackBar.showError(context, passwordError);
      return;
    }

    setState(() => _isPrimaryLoading = true);
    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isPrimaryLoading = false);
    if (!result.isSuccess) {
      AppSnackBar.showError(context, result.message ?? 'Unable to login.');
      return;
    }

    // Debug: show detected signed-in email and whether it's treated as admin.
    final String detectedEmail = _authService.currentUserEmail ?? email;
    final bool isAdmin = AdminCredentials.isAdminEmail(detectedEmail);
    AppSnackBar.showSuccess(
      context,
      'Signed in as $detectedEmail — admin: ${isAdmin ? 'yes' : 'no'}',
    );

    _navigateAfterLogin(detectedEmail);
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    final result = await _authService.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _isGoogleLoading = false);
    if (!result.isSuccess) {
      AppSnackBar.showError(
        context,
        result.message ?? 'Google sign-in failed.',
      );
      return;
    }

    // Debug: show detected signed-in email and whether it's treated as admin.
    final String detectedEmail = _authService.currentUserEmail ?? '';
    final bool isAdmin = AdminCredentials.isAdminEmail(detectedEmail);
    AppSnackBar.showSuccess(
      context,
      'Signed in as $detectedEmail — admin: ${isAdmin ? 'yes' : 'no'}',
    );

    _navigateAfterLogin(detectedEmail);
  }

  Future<void> _showForgotPasswordDialog() async {
    final BuildContext pageContext = context;
    _resetEmailController.text = _emailController.text.trim();
    bool isSending = false;

    final bool? didSend = await showDialog<bool>(
      context: pageContext,
      barrierDismissible: !isSending,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: AppColors.lightBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(
                  color: AppColors.borderGreen,
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Reset Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.borderGreen,
                        fontFamily: 'Times New Roman',
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your email to receive a reset link.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryGreen.withValues(alpha: 0.68),
                        fontFamily: 'Times New Roman',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _resetEmailController,
                      enabled: !isSending,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const <String>[AutofillHints.email],
                      cursorColor: AppColors.primaryGreen,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontFamily: 'Times New Roman',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'example@mail.com',
                        hintStyle: TextStyle(
                          color: AppColors.primaryGreen.withValues(alpha: 0.45),
                          fontFamily: 'Times New Roman',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderGreen,
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.borderGreen,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    final String email = _resetEmailController
                                        .text
                                        .trim();
                                    final String? emailError = validateEmail(
                                      email,
                                    );
                                    if (emailError != null) {
                                      AppSnackBar.showError(
                                        pageContext,
                                        emailError,
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSending = true);
                                    final result = await _authService
                                        .sendPasswordResetEmail(email);

                                    if (!dialogContext.mounted) {
                                      return;
                                    }
                                    setDialogState(() => isSending = false);

                                    if (!result.isSuccess) {
                                      AppSnackBar.showError(
                                        pageContext,
                                        result.message ??
                                            'Unable to send reset email.',
                                      );
                                      return;
                                    }

                                    Navigator.of(dialogContext).pop(true);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.borderGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Send',
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (didSend == true) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Password reset email sent.',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Times New Roman',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.borderGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 54, 26, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 84,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.borderGreen,
                            fontFamily: 'Times New Roman',
                            fontSize: 50,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let\'s start with login to your account!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.62,
                            ),
                            fontFamily: 'Times New Roman',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 44),
                        AuthTextField(
                          label: 'Email',
                          hintText: 'example@mail.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          enabled: !_isAnyLoading,
                        ),
                        const SizedBox(height: 30),
                        AuthTextField(
                          label: 'Password',
                          hintText: 'At least 8 characters',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const <String>[AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          enabled: !_isAnyLoading,
                          trailing: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.borderGreen,
                            size: 25,
                          ),
                          onTrailingTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              Text(
                                'Forget your password?',
                                style: TextStyle(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.62,
                                  ),
                                  fontFamily: 'Times New Roman',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              InkWell(
                                onTap: _isAnyLoading
                                    ? null
                                    : _showForgotPasswordDialog,
                                child: Text(
                                  'Click me',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.8,
                                    ),
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryGreen
                                        .withValues(alpha: 0.8),
                                    fontFamily: 'Times New Roman',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthPrimaryButton(
                          label: 'Login',
                          onPressed: _handleEmailLogin,
                          isLoading: _isPrimaryLoading,
                        ),
                        const SizedBox(height: 32),
                        const AuthOrDivider(),
                        const SizedBox(height: 32),
                        AuthSocialButton(
                          label: 'Continue with Google',
                          leading: const Text(
                            'G',
                            style: TextStyle(
                              color: AppColors.borderGreen,
                              fontFamily: 'Times New Roman',
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 0.8,
                            ),
                          ),
                          onPressed: _handleGoogleLogin,
                          isLoading: _isGoogleLoading,
                        ),
                        if (kDebugMode) ...<Widget>[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              TextButton(
                                onPressed: () {
                                  final String email =
                                      _authService.currentUserEmail ??
                                      'No email';
                                  final String provider =
                                      _authService.currentUserProviderLabel;
                                  final String project = DefaultFirebaseOptions
                                      .currentPlatform
                                      .projectId;
                                  AppSnackBar.showSuccess(
                                    context,
                                    'Email: $email | Provider: $provider | Project: $project',
                                  );
                                },
                                child: const Text('Show Auth Info (debug)'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => AdminVerificationScreen(
                                        authService: _authService,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Force Admin Verify'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 28),
                        Column(
                          children: <Widget>[
                            Text(
                              'Not have an account yet? Switch to',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.72,
                                ),
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SignupScreen(authService: _authService),
                                  ),
                                );
                              },
                              child: const Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontFamily: 'Times New Roman',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
