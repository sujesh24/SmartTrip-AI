import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';
import 'package:smarttrip_ai/modules/admin/screens/admin_dashboard_screen.dart';
import 'package:smarttrip_ai/modules/admin/services/admin_session_service.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/user/screens/login_screen.dart';
import 'package:smarttrip_ai/modules/user/services/auth_service.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({
    super.key,
    required this.authService,
    this.sessionService,
  });

  final AuthServiceBase authService;
  final AdminSessionService? sessionService;

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  late final AdminSessionService _sessionService;
  final List<TextEditingController> _digitControllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes = List<FocusNode>.generate(
    6,
    (_) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _sessionService = widget.sessionService ?? AdminSessionService();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _digitControllers) {
      controller.dispose();
    }
    for (final FocusNode focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code {
    return _digitControllers
        .map((TextEditingController controller) => controller.text.trim())
        .join();
  }

  void _handleDigitChanged(int index, String value) {
    final String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 1) {
      _applyPastedCode(digitsOnly);
      return;
    }

    if (digitsOnly.isEmpty) {
      _digitControllers[index].clear();
      if (index > 0) {
        _digitFocusNodes[index - 1].requestFocus();
      }
      return;
    }

    _digitControllers[index].text = digitsOnly;
    _digitControllers[index].selection = TextSelection.collapsed(
      offset: digitsOnly.length,
    );

    if (index < _digitFocusNodes.length - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    } else {
      _digitFocusNodes[index].unfocus();
      if (_code.length == 6) {
        _verifyCode();
      }
    }
  }

  void _applyPastedCode(String rawCode) {
    final String code = rawCode.length > 6 ? rawCode.substring(0, 6) : rawCode;
    for (int index = 0; index < _digitControllers.length; index += 1) {
      final String digit = index < code.length ? code[index] : '';
      _digitControllers[index].text = digit;
      _digitControllers[index].selection = TextSelection.collapsed(
        offset: digit.length,
      );
    }

    final int nextIndex = code.length >= 6 ? 5 : code.length;
    _digitFocusNodes[nextIndex].requestFocus();
    if (code.length == 6) {
      _digitFocusNodes[nextIndex].unfocus();
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) {
      return;
    }

    final String code = _code;
    if (code.length != 6) {
      AppSnackBar.showError(context, 'Enter the 6-digit safe code.');
      return;
    }

    setState(() => _isVerifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    if (code != AdminCredentials.safeCode) {
      setState(() => _isVerifying = false);
      AppSnackBar.showError(context, 'Safe code is incorrect.');
      return;
    }

    try {
      await _sessionService.saveVerifiedAdminSession(
        widget.authService.currentUserEmail ?? AdminCredentials.email,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AdminDashboardScreen(
            authService: widget.authService,
            sessionService: _sessionService,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isVerifying = false);
      AppSnackBar.showError(
        context,
        'Unable to save admin session. Please try again.',
      );
    }
  }

  Future<void> _returnToLogin() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);
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
      AppSnackBar.showError(context, 'Unable to return to login right now.');
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

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'Return to login',
            onPressed: _isSigningOut ? null : _returnToLogin,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.logout_rounded, color: primaryTextColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: primaryTextColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontFamily: 'Times New Roman',
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit safe code to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.68),
                          fontFamily: 'Times New Roman',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          6,
                          (int index) => _CodeDigitBox(
                            controller: _digitControllers[index],
                            focusNode: _digitFocusNodes[index],
                            enabled: !_isVerifying && !_isSigningOut,
                            onChanged: (String value) =>
                                _handleDigitChanged(index, value),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying || _isSigningOut
                              ? null
                              : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTextColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_user_outlined),
                          label: Text(
                            _isVerifying ? 'Verifying...' : 'Verify',
                            style: const TextStyle(
                              fontFamily: 'Times New Roman',
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeDigitBox extends StatelessWidget {
  const _CodeDigitBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color fillColor = isDarkMode
        ? AppColors.darkBackground
        : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.borderGreen;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AspectRatio(
          aspectRatio: 0.82,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              color: primaryTextColor,
              fontFamily: 'Times New Roman',
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: fillColor,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryTextColor, width: 1.7),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: borderColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}
