import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryGreen = Color(0xFF1B8A3F);
  static const Color _accentBlue = Color(0xFF2D6CDF);
  static const Color _darkBg = Color(0xFF0D1117);
  static const Color _surfaceDark = Color(0xFF161B22);

  static const Color scheduleButtonColor = Color(0xFF111317);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBg,
        colorScheme: const ColorScheme.dark(
          primary: _primaryGreen,
          secondary: _accentBlue,
          surface: _surfaceDark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: const ColorScheme.light(
          primary: _primaryGreen,
          secondary: _accentBlue,
          surface: Color(0xFFFFFFFF),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.black87,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          bodyLarge: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
}
