import 'package:flutter/material.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class AppThemeData {
  const AppThemeData._();

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme.copyWith(
        primary: AppColors.primaryGreen,
        secondary: AppColors.borderGreen,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimaryGreen,
      onPrimary: Colors.white,
      secondary: AppColors.accentGreen,
      onSecondary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.accentGreen,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      dividerColor: AppColors.darkBorder,
      cardColor: AppColors.darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
