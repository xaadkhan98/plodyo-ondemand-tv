import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

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
  const StoryImage({super.key, required this.url, this.videoUrl});

  final String? url;

  /// A film's own video: a still from it stands in when there is no artwork.
  final String? videoUrl;

  /// Opens a card's still; tests hand in a fake, since there is no media platform there.
  static VideoPlayerController Function(Uri url) openStill =
      VideoPlayerController.networkUrl;

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
    final film = videoUrl;
    Widget missing() => film == null ? _fallback() : _VideoStill(url: film);
    if (src == null) return missing();
    return LayoutBuilder(
      builder: (context, constraints) => Image.network(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth:
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .ceil(),
        errorBuilder: (_, _, _) => missing(),
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

/// Past the film's title card, so the still is a scene from the film itself.
const _stillAt = Duration(seconds: 6);

/// How near the screen a card comes before its still loads.
const _stillMargin = 300 * px;

/// One frame of the film, loaded only once its card is near the screen, and let go while a screen covers it.
class _VideoStill extends StatefulWidget {
  const _VideoStill({required this.url});

  final String url;

  @override
  State<_VideoStill> createState() => _VideoStillState();
}

class _VideoStillState extends State<_VideoStill> {
  final _scrolls = <ScrollPosition>[];
  VideoPlayerController? _video;
  bool _near = false;
  bool _failed = false;

  // False while another screen covers this one, so the film opened over it gets the decoder.
  bool _onScreen = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onScreen = TickerMode.valuesOf(context).enabled;
    _watch();
    _sync();
  }

  @override
  void dispose() {
    _unwatch();
    _video?.dispose();
    super.dispose();
  }

  void _unwatch() {
    for (final position in _scrolls) {
      position.removeListener(_checkSoon);
    }
    _scrolls.clear();
  }

  // Every list the card sits in, a rail inside the page included, until the card first comes near.
  void _watch() {
    _unwatch();
    if (_near) return;
    for (
      var scrollable = Scrollable.maybeOf(context);
      scrollable != null;
      scrollable = Scrollable.maybeOf(scrollable.context)
    ) {
      _scrolls.add(scrollable.position..addListener(_checkSoon));
    }
    _checkSoon();
  }

  // After the frame, once the card's place on screen is laid out.
  void _checkSoon() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());

  void _check() {
    if (_near || !mounted) return;
    final card = context.findRenderObject();
    final screen = Overlay.maybeOf(
      context,
      rootOverlay: true,
    )?.context.findRenderObject();
    if (card is! RenderBox || !card.hasSize || screen is! RenderBox) return;
    final rect = MatrixUtils.transformRect(
      card.getTransformTo(screen),
      Offset.zero & card.size,
    );
    if (!rect.overlaps((Offset.zero & screen.size).inflate(_stillMargin))) {
      return;
    }
    _near = true;
    _unwatch();
    _sync();
  }

  void _sync() {
    final open = _video;
    if (!_near || !_onScreen || _failed) {
      _video = null;
      open?.dispose();
      return;
    }
    if (open != null) return;
    // ponytail: a paused player per card near the screen; a poster made at render time if low-end TVs run short of decoders.
    final video = _video = StoryImage.openStill(Uri.parse(widget.url));
    video
        .initialize()
        .then((_) => video.seekTo(_stillAt))
        .then(
          (_) {
            if (mounted && video == _video) setState(() {});
          },
          onError: (Object _) {
            if (!mounted || video != _video) return;
            setState(() => _failed = true);
            _sync();
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return StoryImage._fallback();
    final video = _video;
    final size = video?.value.size ?? Size.zero;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: storyWash),
      child: SizedBox.expand(
        child: video == null || !video.value.isInitialized || size.isEmpty
            ? null
            // Scaled from the top, so the captions along the bottom sit outside the frame.
            : Transform.scale(
                scale: 1.3,
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox.fromSize(
                    size: size,
                    child: VideoPlayer(video),
                  ),
                ),
              ),
      ),
    );
  }
}
