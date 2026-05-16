import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: Colors.redAccent);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: const Color(0xFF4A7A42));
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    final ScaffoldMessengerState? messenger =
        messengerKey.currentState ??
        (context.mounted
            ? context.findAncestorStateOfType<ScaffoldMessengerState>()
            : null);
    if (messenger == null) {
      return;
    }

    void showSnackBar() {
      if (!messenger.mounted) {
        return;
      }
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
          elevation: 0,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => showSnackBar());
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
