import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tv_colors.dart';

/// One reference `rem`. The reference is 20px at 1920×1080; the design canvas below is that frame halved.
const double rem = 10;

/// Overscan gutters (the reference's `px-safe` 3.5vw and `py-safe-y` 3vh): older panels clip ~5% of each edge.
abstract final class TvInsets {
  static const double safeX = 0.035 * TvCanvas.designWidth;
  static const double safeY = 0.03 * TvCanvas.designHeight;
}

/// Lays the app out on a fixed design canvas and scales it uniformly to the screen, so every TV —
/// any resolution, density or vendor display override — shows the same layout, as the reference's
/// viewport-relative root font size does.
class TvCanvas extends StatelessWidget {
  const TvCanvas({super.key, required this.child});

  static const double designWidth = 960;
  static const double designHeight = 540;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // min() fits both axes, like the reference's clamp(…, min(1.0417vw, 1.8519vh), …).
    final scale = math.min(
      media.size.width / designWidth,
      media.size.height / designHeight,
    );
    // The canvas keeps the screen's aspect ratio, so non-16:9 panels gain room rather than letterboxing.
    final canvas = media.size / scale;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: TvColors.canvas),
      child: FittedBox(
        child: SizedBox.fromSize(
          size: canvas,
          child: MediaQuery(
            data: media.copyWith(
              size: canvas,
              devicePixelRatio: media.devicePixelRatio * scale,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
              // Matches the reference's `text-size-adjust: 100%`: a TV font setting must not reflow a fixed canvas.
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
