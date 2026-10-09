import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/filled_icon.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/story_models.dart';
import '../story_play.dart';
import 'guest_page.dart';
import 'story_image.dart';

/// Opens a video or a page's narration; tests hand in a fake, since there is no media platform there.
typedef MediaOpener = VideoPlayerController Function(Uri url);

/// The remote's transport keys, which drive whatever is playing on a story screen.
const transportKeys = [
  SingleActivator(LogicalKeyboardKey.mediaPlayPause),
  SingleActivator(LogicalKeyboardKey.mediaPlay),
  SingleActivator(LogicalKeyboardKey.mediaPause),
];

/// mm:ss. A page's narration runs about a minute, so there is no hours branch.
String _clock(Duration time) =>
    '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';

/// The picture book, for a story whose video was never made, which is most of the catalogue: one page
/// at a time, the illustration beside its words, that page's narration under them, and a star per page
/// so a child can see how much is left without reading the count. It owns the whole pane, Back included.
class StoryReader extends StatefulWidget {
  const StoryReader({
    super.key,
    required this.title,
    required this.pages,
    required this.play,
    this.openMedia = VideoPlayerController.networkUrl,
  });

  final String title;
  final List<StoryPage> pages;
  final StoryPlay play;
  final MediaOpener openMedia;

  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> {
  /// A page's narration runs about a minute, so a page left open stops counting as reading after this.
  static const _pageReadCap = 120;
  static const _turnIn = Duration(milliseconds: 300);

  final _previous = FocusNode();
  final _next = FocusNode();
  final _narration = FocusNode();
  int _index = 0;
  Timer? _reading;
  VideoPlayerController? _voice;
  Future<void>? _voiceReady;

  int get _last => widget.pages.length - 1;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _reading?.cancel();
    // Leaving a story must not leave the voice reading under the next screen.
    _voice?.dispose();
    _previous.dispose();
    _next.dispose();
    _narration.dispose();
    super.dispose();
  }

  /// Restarts the reading clock, so the cap is per page and a turn always counts again; swaps the voice.
  void _open() {
    var counted = 0;
    _reading?.cancel();
    _reading = Timer.periodic(const Duration(seconds: 1), (_) {
      final onScreen = switch (WidgetsBinding.instance.lifecycleState) {
        AppLifecycleState.hidden || AppLifecycleState.paused => false,
        _ => true,
      };
      if (!onScreen || counted >= _pageReadCap) return;
      counted++;
      widget.play.watch(1);
      if (_index == _last) widget.play.complete();
    });
    _voice?.dispose();
    final audio = widget.pages[_index].audioUrl;
    final voice = _voice = audio == null
        ? null
        : widget.openMedia(Uri.parse(audio));
    // Metadata only, as `preload="metadata"`; a voice that fails to load leaves the bar at 0:00.
    _voiceReady = voice?.initialize()?..ignore();
  }

  void _turn(int to) {
    final page = to.clamp(0, _last);
    if (page == _index) return;
    // A control that is about to disable or vanish hands the ring on first, rather than leaving none.
    final keeps = switch (FocusManager.instance.primaryFocus) {
      final node when node == _next => page != _last,
      final node when node == _previous => page != 0,
      final node when node == _narration => widget.pages[page].audioUrl != null,
      _ => true,
    };
    if (!keeps) (page == _last ? _previous : _next).requestFocus();
    setState(() => _index = page);
    _open();
  }

  Future<void> _toggleVoice() async {
    final voice = _voice;
    if (voice == null) return;
    if (voice.value.isPlaying) return voice.pause();
    try {
      await _voiceReady;
      // The page may have turned while the voice was still loading.
      if (voice == _voice) await voice.play();
    } on Object {
      // A voice that will not start leaves the bar showing play, which is the truth.
    }
  }

  // Left and right turn pages once the ring has nowhere to go inside the reader, so the controls hold
  // the D-pad on x: from Previous, left is a page back rather than the side rail.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final forward = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => true,
      LogicalKeyboardKey.arrowLeft => false,
      _ => null,
    };
    if (forward == null) return KeyEventResult.ignored;
    if (forward && _previous.hasFocus && _index < _last) {
      _next.requestFocus();
    } else if (!forward && _next.hasFocus && _index > 0) {
      _previous.requestFocus();
    } else {
      _turn(_index + (forward ? 1 : -1));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.pages[_index];
    final voice = _voice;
    return CallbackShortcuts(
      bindings: {for (final key in transportKeys) key: _toggleVoice},
      child: GuestPage.fill(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvInsets.safeX,
            0,
            TvInsets.safeX,
            TvInsets.safeY,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 93.75 * rem),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outline, not quiet: it is the only way out of a story, and grey text is no exit to a child.
                    TvButton(
                      label: 'Back',
                      icon: LucideIcons.arrowLeft,
                      variant: TvButtonVariant.outline,
                      size: TvButtonSize.md,
                      autofocus: true,
                      onSelect: () => goBack(context),
                    ),
                    const SizedBox(height: rem),
                    // 8:3 across two columns and a gap is 4:3 a side, the illustration's own shape. It gives up
                    // height first, so the page controls never fall off a set that cannot scroll.
                    Flexible(
                      child: SizedBox(
                        height: constraints.maxWidth * 3 / 8,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 2 * rem,
                          children: [
                            Expanded(
                              child: _Art(page: page, duration: _turnIn),
                            ),
                            Expanded(
                              child: _Words(
                                title: widget.title,
                                page: page,
                                duration: _turnIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: _onKey,
                      child: Column(
                        children: [
                          // Unkeyed, so it stays mounted across a turn and the ring stays on it.
                          if (voice != null)
                            _Narration(
                              title: widget.title,
                              voice: voice,
                              focusNode: _narration,
                              onSelect: _toggleVoice,
                            ),
                          const SizedBox(height: 1.25 * rem),
                          _Progress(index: _index, pages: widget.pages),
                          const SizedBox(height: rem),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 1.25 * rem,
                            children: [
                              TvButton(
                                label: 'Previous',
                                icon: LucideIcons.skipBack,
                                variant: TvButtonVariant.quiet,
                                size: TvButtonSize.md,
                                focusNode: _previous,
                                disabled: _index == 0,
                                onSelect: () => _turn(_index - 1),
                              ),
                              TvButton(
                                label: 'Next',
                                trailingIcon: LucideIcons.skipForward,
                                size: TvButtonSize.md,
                                focusNode: _next,
                                disabled: _index == _last,
                                onSelect: () => _turn(_index + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plays [child] in when [page] changes: the old page goes at once, the new one fades in, so a turn on a
/// big set never reads as a glitch.
class _TurnIn extends StatelessWidget {
  const _TurnIn({
    required this.page,
    required this.duration,
    required this.builder,
  });

  final StoryPage page;
  final Duration duration;
  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(page.pageNumber),
    tween: Tween(begin: 0, end: 1),
    duration: duration,
    curve: TvMotion.focus,
    builder: (context, t, _) => builder(t),
  );
}

class _Art extends StatelessWidget {
  const _Art({required this.page, required this.duration});

  final StoryPage page;
  final Duration duration;

  @override
  Widget build(BuildContext context) => _TurnIn(
    page: page,
    duration: duration,
    builder: (t) => Opacity(
      opacity: t,
      child: Transform.scale(
        scale: 0.985 + 0.015 * t,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(rem),
          child: ColoredBox(
            color: TvColors.muted,
            child: StoryImage(url: page.imageUrl),
          ),
        ),
      ),
    ),
  );
}

class _Words extends StatelessWidget {
  const _Words({
    required this.title,
    required this.page,
    required this.duration,
  });

  final String title;
  final StoryPage page;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final heading = TvText.lg.copyWith(
      fontFamily: TvText.fredoka,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: const EdgeInsets.all(1.75 * rem),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rem),
        border: Border.all(
          color: TvColors.border.withValues(alpha: 0.4),
          width: px,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 0.75 * rem,
            children: [
              // An emoji, not an icon: it is the one mark on the page a pre-reader knows as "a book".
              Text('📖', style: heading.copyWith(height: 1)),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: rem),
          // A long page scrolls inside the card rather than stretching the row past the illustration.
          Expanded(
            child: _TurnIn(
              page: page,
              duration: duration,
              builder: (t) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 10 * px * (1 - t)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: rem,
                      children: [
                        for (final paragraph in page.text.split(
                          RegExp(r'\n\s*\n'),
                        ))
                          Text(
                            paragraph,
                            style: TvText.base.copyWith(height: 1.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The narration bar for the page on screen. The whole bar is the target, so a pointer remote can hit
/// it without aiming, and it reads as the control from across a room.
class _Narration extends StatelessWidget {
  const _Narration({
    required this.title,
    required this.voice,
    required this.focusNode,
    required this.onSelect,
  });

  final String title;
  final VideoPlayerController voice;
  final FocusNode focusNode;
  final VoidCallback onSelect;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    final time = TvText.sm.copyWith(
      color: TvColors.mutedForeground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 1.25 * rem),
      child: TvFocusable(
        focusNode: focusNode,
        borderRadius: _radius,
        semanticLabel: 'Listen to $title',
        onSelect: onSelect,
        builder: (context, focused) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 1.75 * rem,
            vertical: rem,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: _radius,
            border: Border.all(
              color: TvColors.border.withValues(alpha: 0.4),
              width: px,
            ),
          ),
          child: ValueListenableBuilder(
            valueListenable: voice,
            builder: (context, value, _) {
              final length = value.duration;
              final progress = length > Duration.zero
                  ? math.min(
                      1.0,
                      value.position.inMilliseconds / length.inMilliseconds,
                    )
                  : 0.0;
              return Row(
                spacing: 1.5 * rem,
                children: [
                  AnimatedScale(
                    scale: focused ? 1.08 : 1,
                    duration: TvMotion.focusDuration,
                    curve: TvMotion.focus,
                    child: AnimatedContainer(
                      duration: TvMotion.focusDuration,
                      width: 3.5 * rem,
                      height: 3.5 * rem,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: focused ? TvColors.brandBold : TvColors.brand,
                        boxShadow: focused
                            ? TvShadows.xl(
                                TvColors.primary.withValues(alpha: 0.4),
                              )
                            : TvShadows.lg(
                                TvColors.primary.withValues(alpha: 0.25),
                              ),
                      ),
                      child: FilledIcon(
                        value.isPlaying ? FilledGlyph.pause : FilledGlyph.play,
                        size: 1.75 * rem,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: TvText.sm.copyWith(
                            fontWeight: FontWeight.w500,
                            color: TvColors.primaryInk,
                          ),
                          child: Row(
                            spacing: 0.5 * rem,
                            children: [
                              const ExcludeSemantics(child: Text('🔊')),
                              Flexible(
                                child: Text(
                                  'Listen — $title',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 0.75 * rem),
                        Row(
                          spacing: rem,
                          children: [
                            SizedBox(
                              width: 3.5 * rem,
                              child: Text(_clock(value.position), style: time),
                            ),
                            // A bar, not a slider: nothing can scrub it on a remote, so a handle would promise
                            // an interaction that is not there. The dot is where the voice has reached.
                            Expanded(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: progress),
                                duration: TvMotion.focusDuration,
                                builder: (context, at, _) => CustomPaint(
                                  size: const Size.fromHeight(0.875 * rem),
                                  painter: _VoiceBar(at),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 3.5 * rem,
                              child: Text(
                                _clock(length),
                                textAlign: TextAlign.right,
                                style: time,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VoiceBar extends CustomPainter {
  const _VoiceBar(this.progress);

  final double progress;

  static const _track = 0.375 * rem;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;
    RRect track(double right) => RRect.fromLTRBR(
      0,
      middle - _track / 2,
      right,
      middle + _track / 2,
      const Radius.circular(_track),
    );
    final fill = Paint()..color = TvColors.primary;
    canvas
      ..drawRRect(
        track(size.width),
        Paint()..color = TvColors.primary.withValues(alpha: 0.15),
      )
      ..drawRRect(track(size.width * progress), fill)
      ..drawCircle(Offset(size.width * progress, middle), middle, fill);
  }

  @override
  bool shouldRepaint(_VoiceBar oldDelegate) => oldDelegate.progress != progress;
}

/// A star per page, lit up to the one on screen, over the page count.
class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.pages});

  final int index;
  final List<StoryPage> pages;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 0.25 * rem,
      children: [
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 0.5 * rem,
            children: [
              for (final (i, page) in pages.indexed)
                AnimatedSwitcher(
                  key: ValueKey(page.pageNumber),
                  duration: const Duration(milliseconds: 300),
                  child: i <= index
                      ? const FilledIcon(
                          FilledGlyph.star,
                          key: ValueKey(true),
                          size: 1.75 * rem,
                          color: TvColors.sun,
                        )
                      : Icon(
                          LucideIcons.star,
                          key: const ValueKey(false),
                          size: 1.75 * rem,
                          color: TvColors.mutedForeground.withValues(
                            alpha: 0.3,
                          ),
                        ),
                ),
            ],
          ),
        ),
        Text(
          'Page ${index + 1} of ${pages.length} 🌟',
          style: TvText.sm.copyWith(
            fontWeight: FontWeight.w500,
            color: TvColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
