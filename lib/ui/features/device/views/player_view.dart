import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/filled_icon.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/device_models.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../../../../data/repositories/usage_queue.dart';
import '../device_controller.dart';
import '../story_play.dart';
import '../widgets/guest_message.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_card.dart';
import '../widgets/story_image.dart';
import '../widgets/story_reader.dart';

/// Further than playback moves between two position reports, so a bigger jump is a seek, not watching.
const _maxPlaybackStep = Duration(seconds: 2);

/// Plays one story. The detail call is made here and nowhere else, since only it mints a playable URL.
/// A story with no film yet is read as a picture book instead, which is most of the catalogue.
class PlayerView extends StatefulWidget {
  const PlayerView({
    super.key,
    required this.storyId,
    this.deviceRepository,
    this.usage,
    this.openMedia = VideoPlayerController.networkUrl,
  });

  final String storyId;
  final DeviceRepository? deviceRepository;
  final UsageQueue? usage;
  final MediaOpener openMedia;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late final StoryPlay _play = StoryPlay(widget.storyId, usage: widget.usage);
  StoryDetail? _detail;
  Object? _error;
  VideoPlayerController? _video;
  Future<void>? _videoReady;

  // A dead URL is the same story as a missing one, so both fall back to the book or the art.
  bool _mediaFailed = false;
  bool _finished = false;
  String? _playbackError;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // A TV that navigates away mid-story must not keep playing under the next screen.
    _video?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = await catalogueRead(
        () => (widget.deviceRepository ?? sharedDeviceRepository).getStory(
          widget.storyId,
        ),
      );
      if (!mounted) return;
      setState(() => _detail = detail);
      if (detail.mediaUrl case final url?) {
        final video = _video = widget.openMedia(Uri.parse(url))
          ..addListener(_onVideo);
        // Metadata only, as `preload="metadata"`: the poster holds until the guest presses play.
        _videoReady = video.initialize().catchError((Object _) => _fail());
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _fail() {
    if (mounted && !_mediaFailed) setState(() => _mediaFailed = true);
  }

  void _onVideo() {
    final value = _video!.value;
    if (value.hasError) return _fail();
    // Counts played time only: paused time never moves, and a seek is too big a step.
    final step = value.position - _position;
    _position = value.position;
    if (value.isPlaying && step > Duration.zero && step < _maxPlaybackStep) {
      _play.watch(step.inMicroseconds / Duration.microsecondsPerSecond);
    }
    // The end is the one moment the app has to feel earned; playing again lifts it.
    if (value.isCompleted != _finished) {
      if (value.isCompleted) _play.complete();
      setState(() => _finished = value.isCompleted);
    }
    if (value.isPlaying && _playbackError != null) {
      setState(() => _playbackError = null);
    }
  }

  Future<void> _toggle() async {
    final video = _video;
    if (video == null) return;
    if (video.value.isPlaying) return video.pause();
    try {
      await _videoReady;
      await video.play();
    } on Object {
      // Surfaced rather than swallowed: a still frame with no message reads as a broken video.
      if (mounted) {
        setState(
          () => _playbackError =
              'This TV would not start the video. Try selecting play again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      // A 404 covers an unknown id, a story out of the catalogue and one with no film; the API never says which.
      final notFound = error is AuthException && error.statusCode == 404;
      return GuestMessage(
        title: notFound ? 'Story not found' : 'Couldn’t open this story',
        body: notFound
            ? 'It may have been removed, or it has no video yet.'
            : messageOf(error, 'Something went wrong.'),
        onBack: () => goBack(context),
      );
    }
    final detail = _detail;
    if (detail == null) return const GuestPage.fill(child: Spinner());

    final video = _mediaFailed ? null : _video;
    // No film, but the story was written and illustrated: reading it is the story, not a consolation.
    if (video == null && detail.pages.isNotEmpty) {
      return StoryReader(
        title: detail.story.title,
        pages: detail.pages,
        play: _play,
        openMedia: widget.openMedia,
      );
    }

    return CallbackShortcuts(
      bindings: {for (final key in transportKeys) key: _toggle},
      child: GuestPage(
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
              child: Column(
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5 * rem),
                      boxShadow: TvShadows.x2l(),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1.5 * rem),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ColoredBox(
                          color: Colors.black,
                          child: video == null
                              ? _Unfilmed(artworkUrl: detail.story.artworkUrl)
                              : _Screen(
                                  video: video,
                                  posterUrl: detail.story.artworkUrl,
                                  finished: _finished,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1.5 * rem),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2 * rem,
                    children: [
                      Expanded(
                        child: _About(
                          story: detail.story,
                          playbackError: _playbackError,
                        ),
                      ),
                      if (video != null)
                        _PlayButton(video: video, onSelect: _toggle),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The film, its poster until the first frame plays, how far it has got, and the curtain call at the end.
class _Screen extends StatelessWidget {
  const _Screen({
    required this.video,
    required this.posterUrl,
    required this.finished,
  });

  final VideoPlayerController video;
  final String? posterUrl;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder(
          valueListenable: video,
          builder: (context, value, _) => Stack(
            fit: StackFit.expand,
            children: [
              if (value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(video),
                  ),
                ),
              if (!value.isPlaying && value.position == Duration.zero)
                StoryImage(url: posterUrl),
              // The timeline a browser's own controls show; nothing on a remote can scrub it.
              if (value.isInitialized)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VideoProgressIndicator(
                    video,
                    allowScrubbing: false,
                    padding: EdgeInsets.zero,
                    colors: VideoProgressColors(
                      playedColor: TvColors.primary,
                      bufferedColor: Colors.white.withValues(alpha: 0.3),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: finished
              ? _StoryEnd(onAgain: video.play)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The art in place of a film still being made: stated over the picture, which is what the child came for.
class _Unfilmed extends StatelessWidget {
  const _Unfilmed({required this.artworkUrl});

  final String? artworkUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        StoryImage(url: artworkUrl),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              2 * rem,
              4 * rem,
              2 * rem,
              1.75 * rem,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Color(0x00000000)],
              ),
            ),
            child: Text(
              'The video for this story is still on its way.',
              style: TvText.base.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The curtain call: three fixed stars rather than a score, since there is no progress the server keeps.
/// Drawn straight over the last frame: the reference's `/90` gradient modifier generates no CSS there.
class _StoryEnd extends StatefulWidget {
  const _StoryEnd({required this.onAgain});

  final VoidCallback onAgain;

  @override
  State<_StoryEnd> createState() => _StoryEndState();
}

class _StoryEndState extends State<_StoryEnd>
    with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 1500);
  static const _starPop = Duration(milliseconds: 900);
  static final _pop = SpringCurve(
    stiffness: 320,
    damping: 11,
    duration: _starPop,
  );

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _length,
  )..forward();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// A slice of the clock: [length] of [curve], starting [delay] in.
  Animation<double> _after(Duration delay, Duration length, Curve curve) {
    final total = _length.inMilliseconds;
    return CurvedAnimation(
      parent: _clock,
      curve: Interval(
        delay.inMilliseconds / total,
        (delay + length).inMilliseconds / total,
        curve: curve,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _after(
      const Duration(milliseconds: 550),
      const Duration(milliseconds: 400),
      TvMotion.focus,
    );
    final actions = _after(
      const Duration(milliseconds: 750),
      const Duration(milliseconds: 300),
      Curves.linear,
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.75 * rem,
            children: [
              for (var i = 0; i < 3; i++)
                _PoppingStar(
                  animation: _after(
                    Duration(milliseconds: 120 + i * 140),
                    _starPop,
                    _pop,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 1.75 * rem),
          AnimatedBuilder(
            animation: text,
            builder: (context, child) => Opacity(
              opacity: text.value,
              child: Transform.translate(
                offset: Offset(0, 14 * px * (1 - text.value)),
                child: child,
              ),
            ),
            child: Text(
              'The end!',
              style: TvText.x3l.copyWith(
                fontFamily: TvText.baloo,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2 * rem),
          FadeTransition(
            opacity: actions,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: rem,
              children: [
                // Playing again from the end restarts the film, and playing lifts this overlay.
                TvButton(
                  label: 'Again',
                  icon: LucideIcons.rotateCcw,
                  onSelect: widget.onAgain,
                ),
                TvButton(
                  label: 'Pick another',
                  variant: TvButtonVariant.outline,
                  onSelect: () => context.go('/'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoppingStar extends StatelessWidget {
  const _PoppingStar({required this.animation});

  final Animation<double> animation;

  static const _size = 5 * rem;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.rotate(
        angle: -60 * math.pi / 180 * (1 - animation.value),
        child: Transform.scale(scale: animation.value, child: child),
      ),
      // Tailwind's drop-shadow-lg: a soft copy of the star a few pixels below it.
      child: Stack(
        children: [
          Transform.translate(
            offset: const Offset(0, 4 * px),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.5 * px, sigmaY: 1.5 * px),
              child: const FilledIcon(
                FilledGlyph.star,
                size: _size,
                color: Color(0x1A000000),
              ),
            ),
          ),
          const FilledIcon(FilledGlyph.star, size: _size, color: TvColors.sun),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.story, required this.playbackError});

  final Story story;
  final String? playbackError;

  @override
  Widget build(BuildContext context) {
    final muted = TvText.base.copyWith(color: TvColors.mutedForeground);
    final measure = 70 * TvText.ch(muted);
    final age = AgeGroup.parse(story.ageGroup);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.title,
          style: TvText.x2l.copyWith(
            fontFamily: TvText.fredoka,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 0.5 * rem),
        DefaultTextStyle(
          style: TvText.sm.copyWith(color: TvColors.mutedForeground),
          child: Wrap(
            spacing: 0.75 * rem,
            runSpacing: 0.75 * rem,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              // A bucket, not a running time: the API never sends seconds.
              if (story.duration case final duration?)
                Text(capitalize(duration)),
              if (story.language case final language?) Text(language),
            ],
          ),
        ),
        if (story.description case final description?)
          Padding(
            padding: const EdgeInsets.only(top: rem),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: measure),
              child: Text(description, style: muted),
            ),
          ),
        if (playbackError case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 1.25 * rem),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: measure),
              child: StatusMessage(tone: StatusTone.error, message: message),
            ),
          ),
      ],
    );
  }
}

/// Play and pause, solid violet at rest so it reads as the main control before focus reaches it.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.video, required this.onSelect});

  final VideoPlayerController video;
  final VoidCallback onSelect;

  static const _pill = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
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
            color: focused ? null : TvColors.primaryInk,
            gradient: focused ? TvColors.brandBold : null,
            borderRadius: _pill,
            boxShadow: focused
                ? TvShadows.xl(TvColors.primary.withValues(alpha: 0.3))
                : TvShadows.lg(TvColors.primary.withValues(alpha: 0.2)),
          ),
          child: ValueListenableBuilder(
            valueListenable: video,
            builder: (context, value, _) => Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 0.75 * rem,
              children: [
                FilledIcon(
                  value.isPlaying ? FilledGlyph.pause : FilledGlyph.play,
                  size: 1.5 * rem,
                  color: Colors.white,
                ),
                Text(
                  value.isPlaying ? 'Pause' : 'Play',
                  style: TvText.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
