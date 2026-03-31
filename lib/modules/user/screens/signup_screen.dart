import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/home/screens/home_screen.dart';
import 'package:smarttrip_ai/modules/user/common/auth_validators.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_or_divider.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_primary_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_social_button.dart';
import 'package:smarttrip_ai/modules/user/widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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

  Future<void> _handleEmailSignup() async {
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
    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isPrimaryLoading = false);

    if (!result.isSuccess) {
      AppSnackBar.showError(
        context,
        result.message ?? 'Unable to create account.',
      );
      return;
    }

    _navigateToHome();
  }

  Future<void> _handleGoogleSignup() async {
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
                          'Create Account',
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
                          'Let\'s start with creating an account!',
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
                        const SizedBox(height: 46),
                        AuthTextField(
                          label: 'Email',
                          hintText: 'example@mail.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          enabled: !_isAnyLoading,
                        ),
                        const SizedBox(height: 34),
                        AuthTextField(
                          label: 'Password',
                          hintText: 'At least 8 characters',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
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
                        const SizedBox(height: 34),
                        AuthPrimaryButton(
                          label: 'Create',
                          onPressed: _handleEmailSignup,
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
                          onPressed: _handleGoogleSignup,
                          isLoading: _isGoogleLoading,
                        ),
                        const SizedBox(height: 28),
                        Column(
                          children: <Widget>[
                            Text(
                              'Already have an account? Switch',
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
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'to Login',
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
