import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.surface,
    required this.surfaceSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentGold,
    required this.accentSteel,
    required this.shadowSoft,
  });

  final Color primaryBackground;
  final Color secondaryBackground;
  final Color surface;
  final Color surfaceSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentGold;
  final Color accentSteel;
  final Color shadowSoft;

  static const dark = AppPalette(
    primaryBackground: Color(0xFF070707),
    secondaryBackground: Color(0xFF0E0E0E),
    surface: Color(0xFF141414),
    surfaceSoft: Color(0xFF1C1C1C),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB3B3B3),
    textMuted: Color(0xFF6E6E6E),
    accentGold: Color(0xFFC6A96A),
    accentSteel: Color(0xFF8A8F98),
    shadowSoft: Color(0x33000000),
  );

  static const light = AppPalette(
    primaryBackground: Color(0xFFEFEDE7),
    secondaryBackground: Color(0xFFF6F4EE),
    surface: Color(0xFFFBF9F4),
    surfaceSoft: Color(0xFFE3E0D8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF4F4F4F),
    textMuted: Color(0xFF8A8A8A),
    accentGold: Color(0xFFB08A40),
    accentSteel: Color(0xFF5C636E),
    shadowSoft: Color(0x1A000000),
  );

  @override
  AppPalette copyWith({
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? surface,
    Color? surfaceSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentGold,
    Color? accentSteel,
    Color? shadowSoft,
  }) {
    return AppPalette(
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentGold: accentGold ?? this.accentGold,
      accentSteel: accentSteel ?? this.accentSteel,
      shadowSoft: shadowSoft ?? this.shadowSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryBackground:
          Color.lerp(primaryBackground, other.primaryBackground, t)!,
      secondaryBackground:
          Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      accentSteel: Color.lerp(accentSteel, other.accentSteel, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
