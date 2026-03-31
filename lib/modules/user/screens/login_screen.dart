import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/user/common/auth_validators.dart';
import 'package:smarttrip_ai/modules/user/screens/signup_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_or_divider.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_primary_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_social_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isPrimaryLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isAnyLoading => _isPrimaryLoading || _isGoogleLoading;

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
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

    _navigateToHome();
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

    _navigateToHome();
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Reset password'),
              content: TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@mail.com',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final String email = resetEmailController.text.trim();
                          final String? emailError = validateEmail(email);
                          if (emailError != null) {
                            AppSnackBar.showError(dialogContext, emailError);
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
                              dialogContext,
                              result.message ?? 'Unable to send reset email.',
                            );
                            return;
                          }

                          Navigator.of(dialogContext).pop();
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent.'),
                            ),
                          );
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
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
                                    builder: (_) => const SignupScreen(),
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
