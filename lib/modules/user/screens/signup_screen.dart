import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_colors.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                          label: 'Username',
                          hintText: 'Username',
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 34),
                        AuthTextField(
                          label: 'Password',
                          hintText: 'At least 8 characters',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
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
                        AuthPrimaryButton(label: 'Create', onPressed: () {}),
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
                          onPressed: () {},
                        ),
                        const SizedBox(height: 18),
                        AuthSocialButton(
                          label: 'Continue with Facebook',
                          leading: const Icon(
                            Icons.facebook,
                            color: AppColors.borderGreen,
                            size: 26,
                          ),
                          onPressed: () {},
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
