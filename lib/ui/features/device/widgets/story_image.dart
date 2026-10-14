import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/skeleton.dart';

/// violet-50 → fuchsia-50 → pink-50: reads as intentional where a grey box reads as broken.
const storyWash = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF5F3FF), Color(0xFFFDF4FF), Color(0xFFFDF2F8)],
);

/// Cover art that never leaves a blank box: no URL or a failed one shows the wash and a book, and a slow
/// network holds a pulsing wash until the bitmap paints. Decoded at its drawn size, not the upload's.
class StoryImage extends StatelessWidget {
  const StoryImage({super.key, required this.url});

  final String? url;

  static const _fadeIn = Duration(milliseconds: 500);

  static Widget _fallback() => DecoratedBox(
    decoration: const BoxDecoration(gradient: storyWash),
    child: Center(
      child: Icon(
        LucideIcons.bookOpen300,
        size: 3 * rem,
        color: TvColors.primary.withValues(alpha: 0.3),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null) return _fallback();
    return LayoutBuilder(
      builder: (context, constraints) => Image.network(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth:
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .ceil(),
        errorBuilder: (_, _, _) => _fallback(),
        frameBuilder: (context, child, frame, synchronous) => Stack(
          fit: StackFit.expand,
          children: [
            if (frame == null)
              const Pulse(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: storyWash),
                ),
              ),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: synchronous ? Duration.zero : _fadeIn,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
