import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.accentGold,
      brightness: brightness,
      primary: p.textPrimary,
      surface: p.surface,
      background: p.primaryBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.primaryBackground,
      textTheme: AppTypography.buildTextTheme(p),
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.primaryBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.secondaryBackground,
        indicatorColor: p.surfaceSoft,
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(MaterialState.selected)
                ? p.textPrimary
                : p.textMuted,
            fontSize: 12,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(MaterialState.selected)
                ? p.textPrimary
                : p.textMuted,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.textPrimary,
        foregroundColor: p.primaryBackground,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: p.surfaceSoft,
    );
  }
}
