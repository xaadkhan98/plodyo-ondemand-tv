import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tv_colors.dart';

/// 10-foot UI typography optimized for TV screen reading distances.
/// Uses GoogleFonts Baloo (bold) for header sections and Nunito for descriptions and text.
class TvTypography {
  TvTypography._();

  /// Section & Screen Headers in GoogleFonts Baloo (bold)
  static TextStyle header({
    double fontSize = 34,
    FontWeight fontWeight = FontWeight.w900,
    Color color = TvColors.primary,
    double? letterSpacing = -0.5,
    double? height,
  }) =>
      GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle get heroTitle => GoogleFonts.baloo2(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: TvColors.textPrimary,
        letterSpacing: -0.6,
        height: 1.15,
      );

  static TextStyle get sectionTitle => GoogleFonts.baloo2(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: TvColors.textPrimary,
        letterSpacing: 0.1,
      );

  /// Descriptions, subtitles, cards, and body text in GoogleFonts Nunito
  static TextStyle description({
    double fontSize = 15.5,
    FontWeight fontWeight = FontWeight.w400,
    Color color = const Color(0xFF4B5563),
    double? height = 1.48,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static TextStyle get cardTitle => GoogleFonts.nunito(
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        color: TvColors.textPrimary,
      );

  static TextStyle get cardSubtitle => GoogleFonts.nunito(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: TvColors.textSecondary,
      );

  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: TvColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get button => GoogleFonts.nunito(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  static TextStyle get badge => GoogleFonts.nunito(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  static TextStyle get sidebarItem => GoogleFonts.nunito(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: TvColors.textSecondary,
      );
}
