import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTypography {
  static TextTheme buildTextTheme(AppPalette p) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        color: p.textPrimary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        color: p.textSecondary,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        color: p.textMuted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 12,
        letterSpacing: 1.2,
        color: p.textMuted,
      ),
    );
  }
}
