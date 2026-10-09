import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/story_models.dart';
import 'story_image.dart';

/// A face per age bucket, so a parent reads the age before the words.
const _ageTags = {'0-2': '🍼', '2-4': '🧸', '5-7': '🎒'};

/// CSS `capitalize`: the first letter of every word.
String capitalize(String text) =>
    text.replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());

/// A story as a sticker: artwork and caption in one white frame, with the length and age stuck on the art.
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.onSelect,
    this.autofocus = false,
    this.fullWidth = false,
  });

  /// A rail card's width; a grid card fills its cell instead.
  static const double width = 20 * rem;
  static const _frameRadius = BorderRadius.all(Radius.circular(1.9 * rem));
  static const _artRadius = BorderRadius.all(Radius.circular(1.4 * rem));
  static final _lift = SpringCurve(
    stiffness: 320,
    damping: 26,
    duration: const Duration(milliseconds: 400),
  );

  // Kept tight to the card: a wide coloured glow smeared onto the wash and read as a print error.
  static final _focusedShadow = [
    TvShadows.css(const Color(0x804C1D95), 10, 22, -12),
    BoxShadow(color: TvColors.ring, spreadRadius: 2 * px),
  ];
  static final _restingShadow = [
    TvShadows.css(const Color(0x2E0F0A1E), 6, 16, -8),
    BoxShadow(color: const Color(0x0F000000), spreadRadius: px),
  ];
  static final _stickerShadow = [
    TvShadows.css(const Color(0x0D000000), 1, 2, 0),
  ];

  final Story story;
  final VoidCallback onSelect;
  final bool autofocus;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    // The API falls back to the idea text; this guards a row from elsewhere.
    final title = story.title.isEmpty ? 'Untitled' : story.title;
    final ageTag = _ageTags[story.ageGroup];

    return TvFocusable(
      autofocus: autofocus,
      // The frame draws its own ring, tight to the card.
      ring: false,
      borderRadius: _frameRadius,
      semanticLabel: title,
      onSelect: onSelect,
      // Scale only: a tilt would skew the D-pad's sense of where neighbouring cards are.
      builder: (context, focused) => AnimatedScale(
        scale: focused ? 1.05 : 1,
        duration: _lift.duration,
        curve: _lift,
        child: AnimatedContainer(
          duration: TvMotion.focusDuration,
          width: fullWidth ? null : width,
          padding: const EdgeInsets.all(0.625 * rem),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _frameRadius,
            boxShadow: focused ? _focusedShadow : _restingShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 6 / 5,
                child: ClipRRect(
                  borderRadius: _artRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StoryImage(url: story.artworkUrl),
                      // A bucket ("short") or an episode count, which frees the caption for the title alone.
                      if (story.duration case final duration?)
                        Positioned(
                          left: 0.625 * rem,
                          bottom: 0.625 * rem,
                          child: _Sticker(
                            color: TvColors.purple,
                            shadows: _stickerShadow,
                            child: Text(
                              capitalize(duration),
                              style: TvText.sm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // Opposite the duration, so neither covers a face.
                      if (ageTag != null)
                        Positioned(
                          right: 0.625 * rem,
                          top: 0.625 * rem,
                          child: _Sticker(
                            color: Colors.white.withValues(alpha: 0.95),
                            shadows: [..._stickerShadow, _restingShadow.last],
                            horizontal: 0.625 * rem,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: ageTag),
                                  const WidgetSpan(
                                    child: SizedBox(width: 0.375 * rem),
                                  ),
                                  TextSpan(text: story.ageGroup),
                                ],
                              ),
                              style: TvText.sm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: TvColors.pinkInk,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0.375 * rem,
                  0.75 * rem,
                  0.375 * rem,
                  0.25 * rem,
                ),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TvText.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TvColors.pinkInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({
    required this.color,
    required this.shadows,
    required this.child,
    this.horizontal = 0.75 * rem,
  });

  final Color color;
  final List<BoxShadow> shadows;
  final double horizontal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: 0.25 * rem,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
