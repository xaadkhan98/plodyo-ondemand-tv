import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/languages.dart';

/// Flag for a language code, or [fallback] where none is mapped. SVGs are country-flag-icons (MIT).
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({
    super.key,
    required this.code,
    this.width = 22.5,
    this.height = 15,
    this.radius = 2.5,
    this.fallback = const SizedBox.shrink(),
  });

  final String? code;
  final double width;
  final double height;
  final double radius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final asset = flagAssetFor(code);
    if (asset == null) return fallback;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Hairline so white-edged flags (Japan, Korea) keep a shape on a white tile.
        border: Border.all(color: const Color(0x1A000000), width: 0.5),
      ),
      child: SvgPicture.asset(asset, fit: BoxFit.cover),
    );
  }
}
