import 'package:flutter/material.dart';

class AppColors {
  static const Color background   = Color(0xFF1A1E2A);
  static const Color surface      = Color(0xFF222834);
  static const Color inputBg      = Color(0xFF1A2030);
  static const Color primary      = Color(0xFFF5A300);
  static const Color primaryDark  = Color(0xFFC68000);
  static const Color teal         = Color(0xFF00C9A7);
  static const Color green        = Color(0xFF00C853);
  static const Color red          = Color(0xFFE53935);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8896A8);
  static const Color border       = Color(0xFF2E3650);
  static const Color iconBg       = Color(0xFF252D3D);
  static const Color navBg        = Color(0xFF1A1E2A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.teal,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
