import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/legal.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// The code and short address that take a phone to the Terms and both privacy notices. Dark on white and a
/// third of the screen tall, so it scans from across a hotel room.
class LegalQr extends StatelessWidget {
  const LegalQr({super.key});

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
      ],
    );
  }
}
