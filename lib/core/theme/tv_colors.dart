import 'package:flutter/material.dart';

/// TV-optimized high contrast color palette for 10-foot viewing distance.
class TvColors {
  TvColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF161922);
  static const Color surfaceElevated = Color(0xFF212634);
  static const Color sidebarBackground = Color(0xFF080A0E);

  // Accents & Focus
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan Focus
  static const Color primaryVariant = Color(0xFF00B0FF);
  static const Color secondary = Color(0xFFFF9100); // Amber highlight
  static const Color focusGlow = Color(0x6600E5FF); // Glow effect for focused elements
  static const Color focusBorder = Color(0xFF00E5FF);
  static const Color focusCardBackground = Color(0xFF282E3E);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnFocus = Color(0xFF000000);

  // Badges & Status
  static const Color ratingBadge = Color(0xFFFFB703);
  static const Color hdBadge = Color(0xFF334155);
  static const Color liveIndicator = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x880D0F12),
      Color(0xFF0D0F12),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC000000),
    ],
  );

  static const LinearGradient focusBorderGradient = LinearGradient(
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF80D8FF),
    ],
  );
}
