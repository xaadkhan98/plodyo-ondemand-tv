import 'package:flutter/material.dart';

import 'tv_colors.dart';
import 'tv_typography.dart';

/// The app's only theme. The reference is light-only: there is no dark mode and no toggle.
abstract final class TvTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: TvColors.primary,
      secondary: TvColors.accent,
      surface: TvColors.card,
      onSurface: TvColors.foreground,
      error: TvColors.destructive,
    ),
    fontFamily: TvText.nunito,
    // Screens sit on TvCanvas's wash.
    scaffoldBackgroundColor: Colors.transparent,
    // Focus is drawn by TvFocusable; Material's ink and hover tints would compete with the ring.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    // The reference swaps screens without a transition; each screen animates its own entrance.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: _NoTransition(),
      },
    ),
  );
}

class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(_, _, _, _, Widget child) => child;
}
