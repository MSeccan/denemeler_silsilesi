import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getTheme(String role) {
    switch (role) {

      case "dietitian":
        return _theme(const Color(0xFF2E7D32)); // yeşil

      case "admin":
        return _theme(const Color(0xFF1565C0)); // mavi

      case "pregnant":
        return _theme(const Color(0xFF673AB7)); // 💜 deep purple

      case "gynecologist":
        return _theme(const Color(0xFF00695C)); // teal

      default:
        return _theme(const Color(0xFF673AB7));
    }
  }

  static ThemeData _theme(Color primaryColor) {
    return ThemeData(
      useMaterial3: false,

      colorScheme: ColorScheme(
        brightness: Brightness.light,

        primary: primaryColor,
        onPrimary: Colors.white,

        secondary: primaryColor.withOpacity(0.9),
        onSecondary: Colors.white,

        surface: Colors.white,
        onSurface: const Color(0xFF1A1A1A),

        error: Colors.red,
        onError: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}