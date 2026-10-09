import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/play_icon.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/device_models.dart';
import '../../../../data/models/story_models.dart';
import 'story_card.dart';
import 'story_image.dart';

/// The auto-rotating featured banner over Home. Portrait art has to fill a wide frame, so it is used twice:
/// blurred as a full-bleed backdrop, sharp on top. Rotation pauses while the CTA is focused: the viewer
/// is deciding, and swapping the story under them is hostile.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.stories,
    required this.onSelect,
  });

  /// Null while loading; the first five are featured.
  final List<Story>? stories;
  final ValueChanged<Story> onSelect;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  static const _rotate = Duration(seconds: 7);
  static const _radius = BorderRadius.all(Radius.circular(1.5 * rem));

  Timer? _timer;
  int _index = 0;
  bool _paused = false;

  List<Story> get _slides => (widget.stories ?? const []).take(5).toList();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final count = _slides.length;
    _timer = _paused || count <= 1
        ? null
        : Timer.periodic(
            _rotate,
            (_) => setState(() => _index = (_index + 1) % count),
          );
  }

  void _setPaused(bool paused) {
    _paused = paused;
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = 0.52 * MediaQuery.sizeOf(context).height;
    if (widget.stories == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3 * rem),
        child: Skeleton(height: height, borderRadius: _radius),
      );
    }
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    // Derived rather than corrected in state: the list can shrink between builds.
    final active = _index % slides.length;
    final story = slides[active];

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 3 * rem),
      decoration: BoxDecoration(
        color: TvColors.card,
        borderRadius: _radius,
        border: Border.all(
          color: TvColors.border.withValues(alpha: 0.6),
          width: px,
        ),
        boxShadow: TvShadows.xl(TvColors.primary.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _Backdrop(key: ValueKey(story.id), url: story.artworkUrl),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5 * rem),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  spacing: 2.5 * rem,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 0.52 * constraints.maxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WaitSwitcher(
                            alignment: Alignment.topLeft,
                            duration: const Duration(milliseconds: 450),
                            enter: (t) => Matrix4.translationValues(
                              -24 * px * (1 - t),
                              0,
                              0,
                            ),
                            exit: (t) => Matrix4.translationValues(
                              16 * px * (1 - t),
                              0,
                              0,
                            ),
                            child: _Caption(
                              key: ValueKey(story.id),
                              story: story,
                            ),
                          ),
                          const SizedBox(height: 1.75 * rem),
                          Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onFocusChange: _setPaused,
                            child: _ReadNow(
                              onSelect: () => widget.onSelect(story),
                            ),
                          ),
                          if (slides.length > 1) ...[
                            const SizedBox(height: 1.75 * rem),
                            _Dots(count: slides.length, active: active),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    _WaitSwitcher(
                      duration: const Duration(milliseconds: 550),
                      enter: (t) =>
                          Matrix4.translationValues(0, 28 * px * (1 - t), 0)
                            ..rotateZ(_degrees(2 + (-3 - 2) * t)),
                      exit: (t) =>
                          Matrix4.translationValues(0, -20 * px * (1 - t), 0)
                            ..rotateZ(_degrees(2 + (-3 - 2) * t)),
                      child: _Cover(key: ValueKey(story.id), story: story),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _degrees(double degrees) => degrees * math.pi / 180;

/// framer-motion's `AnimatePresence mode="wait"`: the old child leaves over the first half, then the new
/// one enters, each with its own transform at [t] from 0 (hidden) to 1 (in place).
class _WaitSwitcher extends StatelessWidget {
  const _WaitSwitcher({
    required this.duration,
    required this.enter,
    required this.exit,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Duration duration;
  final Alignment alignment;
  final Matrix4 Function(double t) enter;
  final Matrix4 Function(double t) exit;
  final Widget child;

  static const _half = Interval(0.5, 1, curve: TvMotion.focus);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration * 2,
      switchInCurve: _half,
      switchOutCurve: _half,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          final leaving = animation.status == AnimationStatus.reverse;
          return Opacity(
            opacity: t,
            child: Transform(
              alignment: Alignment.center,
              transform: leaving ? exit(t) : enter(t),
              child: child,
            ),
          );
        },
        child: child,
      ),
      child: child,
    );
  }
}

/// The blurred artwork, slowly zooming, over the brand wash and under a white fade that keeps text legible.
class _Backdrop extends StatelessWidget {
  const _Backdrop({super.key, required this.url});

  final String? url;

  static const _wash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE9FE), Color(0xFFFAE8FF), Color(0xFFFCE7F3)],
  );
  static const _fade = LinearGradient(
    colors: [Colors.white, Color(0xE0FFFFFF), Color(0x33FFFFFF)],
  );

  // CSS saturate(150%).
  static const _saturate = ColorFilter.matrix([
    1.6420, -0.5360, -0.1060, 0, 0, //
    -0.1080, 1.1580, -0.0500, 0, 0, //
    -0.1080, -0.5360, 1.6440, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final src = url;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Never bare white, whether the art is loading or failed outright.
        const DecoratedBox(decoration: BoxDecoration(gradient: _wash)),
        if (src != null)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 1.14),
            duration: const Duration(seconds: 9),
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Opacity(
              opacity: 0.7,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40 * px, sigmaY: 40 * px),
                child: ColorFiltered(
                  colorFilter: _saturate,
                  // A failed backdrop must not leave a broken box behind the text; the wash shows instead.
                  child: Image.network(
                    src,
                    fit: BoxFit.cover,
                    cacheWidth: 480,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        const DecoratedBox(decoration: BoxDecoration(gradient: _fade)),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final age = AgeGroup.parse(story.ageGroup ?? '');
    final meta = TvText.sm.copyWith(color: TvColors.mutedForeground);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Not "Featured today": the shelf really is this room's, cut to its languages and ages by the venue.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: rem,
            vertical: 0.375 * rem,
          ),
          decoration: BoxDecoration(
            gradient: TvColors.brand,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            boxShadow: TvShadows.lg(TvColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.5 * rem,
            children: [
              const Icon(LucideIcons.sparkles, size: rem, color: Colors.white),
              Text(
                'Picked for this room',
                style: TvText.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1.25 * rem),
        Text(
          story.title.isEmpty ? 'Untitled' : story.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TvText.x3l.copyWith(
            fontFamily: TvText.fredoka,
            fontWeight: FontWeight.w600,
            height: TvText.tight,
          ),
        ),
        if (age != null || story.duration != null) ...[
          const SizedBox(height: rem),
          Row(
            spacing: rem,
            children: [
              if (age != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.75 * rem,
                    vertical: 0.25 * rem,
                  ),
                  decoration: const BoxDecoration(
                    color: TvColors.secondary,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    age.label,
                    style: meta.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              // A bucket, not a running time: the API never sends seconds.
              if (story.duration case final duration?)
                Row(
                  spacing: 0.375 * rem,
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      size: rem,
                      color: TvColors.mutedForeground,
                    ),
                    Text(capitalize(duration), style: meta),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Read now": the hero's one control, so it takes the screen's first focus.
class _ReadNow extends StatelessWidget {
  const _ReadNow({required this.onSelect});

  final VoidCallback onSelect;

  static const _pill = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: true,
      borderRadius: _pill,
      onSelect: onSelect,
      builder: (context, focused) => AnimatedScale(
        scale: focused ? 1.06 : 1,
        duration: TvMotion.focusDuration,
        curve: TvMotion.focus,
        child: AnimatedContainer(
          duration: TvMotion.focusDuration,
          constraints: const BoxConstraints(minHeight: 64 * px),
          padding: const EdgeInsets.symmetric(
            horizontal: 2.25 * rem,
            vertical: rem,
          ),
          decoration: BoxDecoration(
            gradient: focused ? TvColors.brandBold : TvColors.brand,
            borderRadius: _pill,
            boxShadow: focused
                ? TvShadows.xl(TvColors.primary.withValues(alpha: 0.3))
                : TvShadows.lg(TvColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.75 * rem,
            children: [
              const PlayIcon(size: 1.5 * rem, color: Colors.white),
              Text(
                'Read now',
                style: TvText.base.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress dots that double as a position indicator.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 0.625 * rem,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: i == active ? 2.5 * rem : 0.375 * rem,
            height: 0.375 * rem,
            decoration: BoxDecoration(
              color: i == active
                  ? null
                  : TvColors.foreground.withValues(alpha: 0.25),
              gradient: i == active ? TvColors.brand : null,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
          ),
      ],
    );
  }
}

/// The sharp cover, 4:3 and tilted, wider than a card: there is room here to show more of the frame.
class _Cover extends StatelessWidget {
  const _Cover({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26 * rem,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(rem)),
        boxShadow: TvShadows.x2l(),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(rem)),
        border: Border.all(color: const Color(0x0D000000), width: px),
      ),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(rem)),
          child: StoryImage(url: story.artworkUrl),
        ),
      ),
    );
  }
}
