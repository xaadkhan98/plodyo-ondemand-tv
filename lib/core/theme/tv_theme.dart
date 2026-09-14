import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tv_colors.dart';

/// App theme configured for TV navigation and 10-ft viewing experience.
class TvTheme {
  TvTheme._();

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TvColors.background,
      primaryColor: TvColors.primary,
      canvasColor: TvColors.sidebarBackground,
      cardColor: TvColors.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      focusColor: TvColors.focusGlow,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: TvColors.primary,
        secondary: TvColors.secondary,
        surface: TvColors.surface,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(baseTheme.textTheme),
    );
  }
}
