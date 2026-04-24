import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  AppThemeController._();

  static const String _isDarkModeKey = 'settings.theme.is_dark_mode';
  static final AppThemeController instance = AppThemeController._();

  final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  ValueNotifier<ThemeMode> get themeModeListenable => _themeModeNotifier;
  ThemeMode get themeMode => _themeModeNotifier.value;

  Future<void> loadThemeMode() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool isDarkMode = preferences.getBool(_isDarkModeKey) ?? false;
    _themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final ThemeMode nextThemeMode = isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
    if (_themeModeNotifier.value != nextThemeMode) {
      _themeModeNotifier.value = nextThemeMode;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_isDarkModeKey, isDarkMode);
  }
}
