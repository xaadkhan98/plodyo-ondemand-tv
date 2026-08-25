import 'package:flutter/material.dart';
import 'tv_colors.dart';

/// App theme configured for TV navigation and 10-ft viewing experience.
class TvTheme {
  TvTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
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
      fontFamily: null, // Uses default system typography
    );
  }
}
