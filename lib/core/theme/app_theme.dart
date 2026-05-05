import 'package:flutter/material.dart';

// ── Static colors (same in both themes — primary brand + semantic colors) ───────
class AppColors {
  static const Color primary      = Color(0xFFF5A300);
  static const Color primaryDark  = Color(0xFFC68000);
  static const Color teal         = Color(0xFF00C9A7);
  static const Color green        = Color(0xFF00C853);
  static const Color red          = Color(0xFFE53935);
  // Dark-mode fallbacks — keep for const-context backward compat
  static const Color background   = Color(0xFF1A1E2A);
  static const Color surface      = Color(0xFF222834);
  static const Color inputBg      = Color(0xFF1A2030);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8896A8);
  static const Color border       = Color(0xFF2E3650);
  static const Color iconBg       = Color(0xFF252D3D);
  static const Color navBg        = Color(0xFF1A1E2A);
}

// ── Theme-aware colors — use via context.appColors in widgets ──────────────────
class AppColorsScheme extends ThemeExtension<AppColorsScheme> {
  final Color background;
  final Color surface;
  final Color inputBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color iconBg;
  final Color navBg;

  const AppColorsScheme({
    required this.background,
    required this.surface,
    required this.inputBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.iconBg,
    required this.navBg,
  });

  factory AppColorsScheme.dark() => const AppColorsScheme(
        background:    Color(0xFF1A1E2A),
        surface:       Color(0xFF222834),
        inputBg:       Color(0xFF1A2030),
        textPrimary:   Color(0xFFFFFFFF),
        textSecondary: Color(0xFF8896A8),
        border:        Color(0xFF2E3650),
        iconBg:        Color(0xFF252D3D),
        navBg:         Color(0xFF1A1E2A),
      );

  // High-contrast light theme — optimised for outdoor sun and elderly users
  factory AppColorsScheme.light() => const AppColorsScheme(
        background:    Color(0xFFFFFFFF),
        surface:       Color(0xFFF2F4F7),
        inputBg:       Color(0xFFE9EDF3),
        textPrimary:   Color(0xFF0D0F14),
        textSecondary: Color(0xFF52596B),
        border:        Color(0xFFC8CDD8),
        iconBg:        Color(0xFFFFF3D6),
        navBg:         Color(0xFFFFFFFF),
      );

  @override
  AppColorsScheme copyWith({
    Color? background,
    Color? surface,
    Color? inputBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? iconBg,
    Color? navBg,
  }) =>
      AppColorsScheme(
        background:    background    ?? this.background,
        surface:       surface       ?? this.surface,
        inputBg:       inputBg       ?? this.inputBg,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        border:        border        ?? this.border,
        iconBg:        iconBg        ?? this.iconBg,
        navBg:         navBg         ?? this.navBg,
      );

  @override
  AppColorsScheme lerp(ThemeExtension<AppColorsScheme>? other, double t) {
    if (other is! AppColorsScheme) return this;
    return AppColorsScheme(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      inputBg:       Color.lerp(inputBg,       other.inputBg,       t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      iconBg:        Color.lerp(iconBg,        other.iconBg,        t)!,
      navBg:         Color.lerp(navBg,         other.navBg,         t)!,
    );
  }
}

// Convenience getter — use `context.appColors.background` etc. in any widget
extension AppColorsContext on BuildContext {
  AppColorsScheme get appColors =>
      Theme.of(this).extension<AppColorsScheme>()!;
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
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
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        extensions: const [AppColorsScheme(
          background:    Color(0xFF1A1E2A),
          surface:       Color(0xFF222834),
          inputBg:       Color(0xFF1A2030),
          textPrimary:   Color(0xFFFFFFFF),
          textSecondary: Color(0xFF8896A8),
          border:        Color(0xFF2E3650),
          iconBg:        Color(0xFF252D3D),
          navBg:         Color(0xFF1A1E2A),
        )],
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.teal,
          surface: Color(0xFFF2F4F7),
          onSurface: Color(0xFF0D0F14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Color(0xFF0D0F14),
              fontSize: 20,
              fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF0D0F14)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF2F4F7),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dividerColor: const Color(0xFFC8CDD8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFE9EDF3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF52596B)),
        ),
        extensions: const [AppColorsScheme(
          background:    Color(0xFFFFFFFF),
          surface:       Color(0xFFF2F4F7),
          inputBg:       Color(0xFFE9EDF3),
          textPrimary:   Color(0xFF0D0F14),
          textSecondary: Color(0xFF52596B),
          border:        Color(0xFFC8CDD8),
          iconBg:        Color(0xFFFFF3D6),
          navBg:         Color(0xFFFFFFFF),
        )],
      );
}
