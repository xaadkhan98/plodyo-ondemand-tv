import 'package:flutter/material.dart';
import 'tv_colors.dart';

/// 10-foot UI typography optimized for TV screen reading distances.
class TvTypography {
  TvTypography._();

  static const TextStyle heroTitle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: TvColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: TvColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: TvColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: TvColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: TvColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle sidebarItem = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TvColors.textSecondary,
  );
}
