import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/legal.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// The code, short address and effective date of the Terms of Service. Dark on white and a third of the
/// screen tall, so it scans from across a hotel room.
class LegalQr extends StatelessWidget {
  const LegalQr({super.key, required this.effectiveDate});

  /// From /device/config; the line is left off without it.
  final String? effectiveDate;

  static const double size = TvCanvas.designHeight / 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // One path, quiet zone included, so it draws with no seams between modules.
        SvgPicture.asset(
          'assets/images/legal_qr.svg',
          width: size,
          height: size,
          semanticsLabel: 'QR code for $legalAddress',
        ),
        const SizedBox(height: 0.75 * rem),
        Text(
          legalAddress,
          style: TvText.xl.copyWith(
            fontWeight: FontWeight.w700,
            color: TvColors.foreground,
          ),
        ),
        if (effectiveDate case final date?) ...[
          const SizedBox(height: 0.75 * rem),
          Text(
            termsEffectiveLine(date),
            style: TvText.sm.copyWith(color: TvColors.mutedForeground),
          ),
        ],
      ],
    );
  }
}
