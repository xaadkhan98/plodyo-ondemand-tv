import 'package:flutter/painting.dart';

import 'tv_colors.dart';
import 'tv_scale.dart';

/// The reference's 10-foot type scale and faces, bundled under assets/fonts.
/// Baloo 2 is for page titles only, Fredoka for headings, Nunito for everything else.
abstract final class TvText {
  static const String baloo = 'Baloo2';
  static const String fredoka = 'Fredoka';
  static const String nunito = 'Nunito';

  // Size and line height in rem, as `tv-sm` … `tv-3xl`. Nothing on screen goes below [sm].
  static const TextStyle sm = TextStyle(
    fontSize: 1.125 * rem,
    height: 1.6 / 1.125,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );
  static const TextStyle base = TextStyle(
    fontSize: 1.375 * rem,
    height: 1.9 / 1.375,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );
  static const TextStyle lg = TextStyle(
    fontSize: 1.75 * rem,
    height: 2.25 / 1.75,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );
  static const TextStyle xl = TextStyle(
    fontSize: 2.25 * rem,
    height: 2.75 / 2.25,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );
  static const TextStyle x2l = TextStyle(
    fontSize: 3 * rem,
    height: 3.4 / 3,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );
  static const TextStyle x3l = TextStyle(
    fontSize: 4 * rem,
    height: 4.4 / 4,
    fontFamily: nunito,
    color: TvColors.foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // Tailwind's `leading-tight`, which headings and titles override the step's line height with.
  static const double tight = 1.25;
  // Tailwind's `tracking-tight`, in em: multiply by the font size.
  static const double trackingTight = -0.025;
}
