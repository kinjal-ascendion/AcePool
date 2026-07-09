import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const Color scheduleButtonColor = AppColors.scheduleButtonColor;

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentBlue,
          surface: AppColors.surfaceDark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          bodyLarge: TextStyle(color: AppColors.white70, fontSize: 16),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.accentBlue,
          surface: AppColors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.black87,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          bodyLarge: TextStyle(color: AppColors.black54, fontSize: 16),
        ),
      );
}
