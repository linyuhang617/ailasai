import 'package:flutter/material.dart';

class AppColorScheme {
  final String id;
  final Color primary;
  final Color primaryLight;
  final Color primaryMuted;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const AppColorScheme({
    required this.id,
    required this.primary,
    required this.primaryLight,
    required this.primaryMuted,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  ThemeData toThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.5)
              : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}

// ── 5 個主題定義 ────────────────────────────────────────────

const kThemePurple = AppColorScheme(
  id: 'purple',
  primary: Color(0xFF7C6FE0),
  primaryLight: Color(0xFFEDE9F8),
  primaryMuted: Color(0xFFC4BAF5),
  background: Color(0xFFEDEAF7),
  surface: Colors.white,
  textPrimary: Color(0xFF3A3358),
  textSecondary: Color(0xFFB0A8CC),
  border: Color(0xFFDCD7EF),
);

const kThemeCoral = AppColorScheme(
  id: 'coral',
  primary: Color(0xFFE05C5C),
  primaryLight: Color(0xFFFDEAEA),
  primaryMuted: Color(0xFFF5AAAA),
  background: Color(0xFFF7EDEE),
  surface: Colors.white,
  textPrimary: Color(0xFF3A2828),
  textSecondary: Color(0xFFCCA8A8),
  border: Color(0xFFEFD7D7),
);

const kThemeTeal = AppColorScheme(
  id: 'teal',
  primary: Color(0xFF2BBBAD),
  primaryLight: Color(0xFFE0F5F3),
  primaryMuted: Color(0xFF8FD9D3),
  background: Color(0xFFE8F5F4),
  surface: Colors.white,
  textPrimary: Color(0xFF1E3533),
  textSecondary: Color(0xFF8FBFBB),
  border: Color(0xFFC5E8E5),
);

const kThemeAmber = AppColorScheme(
  id: 'amber',
  primary: Color(0xFFE0933A),
  primaryLight: Color(0xFFFEF3E2),
  primaryMuted: Color(0xFFF5C47A),
  background: Color(0xFFF7F0E6),
  surface: Colors.white,
  textPrimary: Color(0xFF3A2E1A),
  textSecondary: Color(0xFFCCB07A),
  border: Color(0xFFEFDEC5),
);

const kThemeBlue = AppColorScheme(
  id: 'blue',
  primary: Color(0xFF4A7FE2),
  primaryLight: Color(0xFFE5EDFB),
  primaryMuted: Color(0xFF96B9F0),
  background: Color(0xFFEAEFF7),
  surface: Colors.white,
  textPrimary: Color(0xFF1E2A3A),
  textSecondary: Color(0xFF8AAAD0),
  border: Color(0xFFCDD9EF),
);

// ── 查表 ────────────────────────────────────────────────────

const List<AppColorScheme> kAllThemes = [
  kThemePurple,
  kThemeCoral,
  kThemeTeal,
  kThemeAmber,
  kThemeBlue,
];

AppColorScheme themeById(String id) {
  return kAllThemes.firstWhere((t) => t.id == id, orElse: () => kThemePurple);
}
