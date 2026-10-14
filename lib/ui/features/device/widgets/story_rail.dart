import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/story_models.dart';
import 'story_card.dart';

/// A horizontal row of stories under a heading. Scrolling is driven by focus alone, since a remote has
/// neither scrollbar nor drag; the rail itself is not focusable, its cards are.
class StoryRail extends StatefulWidget {
  const StoryRail({
    super.key,
    required this.title,
    required this.stories,
    required this.onSelect,
    this.subtitle,
    this.error,
    this.autofocus = false,
  });

  final String title;

  /// One line under the title saying what is in the row.
  final String? subtitle;

  /// Null while loading.
  final List<Story>? stories;
  final Object? error;
  final ValueChanged<Story> onSelect;

  /// Gives the first card first focus, for a screen with nothing above the rail to take it.
  final bool autofocus;

  @override
  State<StoryRail> createState() => _StoryRailState();
}

class _StoryRailState extends State<StoryRail>
    with SingleTickerProviderStateMixin {
  static const _cardIn = Duration(milliseconds: 350);
  static const _step = Duration(milliseconds: 40);

  // Capped so a long rail does not take seconds to settle.
  static const _maxDelay = Duration(milliseconds: 400);
  static const _stagger = Duration(milliseconds: 750);

  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: _stagger,
  );

  @override
  void initState() {
    super.initState();
    if (widget.stories != null) _arrival.forward();
  }

  @override
  void didUpdateWidget(StoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Each fresh load staggers in once, as its first paint.
    if (oldWidget.stories == null && widget.stories != null) {
      _arrival.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  /// Card [index]'s slice of the stagger: a delay of 40ms a card, then 350ms of fade and slide.
  Animation<double> _cardAnimation(int index) {
    final delay = _step * index > _maxDelay ? _maxDelay : _step * index;
    final start = delay.inMilliseconds / _stagger.inMilliseconds;
    final end = (delay + _cardIn).inMilliseconds / _stagger.inMilliseconds;
    return CurvedAnimation(
      parent: _arrival,
      curve: Interval(start, end, curve: TvMotion.focus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;
    final error = widget.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.5 * rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: TvInsets.safeX),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 0.75 * rem,
                children: [
                  // A gradient tick gives each rail a brand anchor without extra chrome.
                  Container(
                    width: 0.375 * rem,
                    margin: const EdgeInsets.only(top: 0.25 * rem),
                    decoration: const BoxDecoration(
                      gradient: TvColors.brandBold,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TvText.lg.copyWith(
                          fontFamily: TvText.fredoka,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.subtitle case final subtitle?)
                        Padding(
                          padding: const EdgeInsets.only(top: 0.125 * rem),
                          child: Text(
                            subtitle,
                            style: TvText.sm.copyWith(
                              color: TvColors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: rem),
          // The vertical padding is load-bearing: a focused card scales and casts a shadow, which the
          // scroll view would otherwise clip.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              0.25 * rem,
              0.75 * rem,
              TvInsets.safeX,
              1.5 * rem,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1.5 * rem,
              children: [
                if (stories == null)
                  for (var i = 0; i < 8; i++) const StoryCardSkeleton()
                else
                  for (final (index, story) in stories.indexed)
                    _Arrival(
                      animation: _cardAnimation(index),
                      child: StoryCard(
                        story: story,
                        autofocus: widget.autofocus && index == 0,
                        onSelect: () => widget.onSelect(story),
                      ),
                    ),
                if (stories != null && error != null) _RailError(error),
                if (stories != null && error == null && stories.isEmpty)
                  Text(
                    'Nothing here yet.',
                    style: TvText.base.copyWith(
                      color: TvColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades a card in while it slides 24px from the right.
class _Arrival extends StatelessWidget {
  const _Arrival({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(24 * px * (1 - animation.value), 0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _RailError extends StatelessWidget {
  const _RailError(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 1.75 * rem,
        vertical: 1.5 * rem,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(rem)),
        border: Border.all(color: TvColors.border, width: px),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Couldn’t load stories.',
            style: TvText.base.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 0.25 * rem),
          Text(
            messageOf(error, 'Something went wrong.'),
            style: TvText.sm.copyWith(color: TvColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
