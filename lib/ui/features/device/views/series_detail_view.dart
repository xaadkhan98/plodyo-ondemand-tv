import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/device_models.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/card_grid.dart';
import '../widgets/guest_message.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_card.dart';
import '../widgets/story_image.dart';

/// A cover paper and the ink that reads on it at AA or better.
typedef _Paper = ({Color sheet, Color ink});

/// Tints of the kid-surface hues, so a show is recognised by its colour the way a picture book is.
const _papers = <_Paper>[
  (sheet: Color(0xFFFFE7A3), ink: Color(0xFF7A4708)),
  (sheet: Color(0xFFC4F0DC), ink: Color(0xFF0A5A42)),
  (sheet: Color(0xFFCBE4FF), ink: Color(0xFF0B4A87)),
  (sheet: Color(0xFFFFD6E7), ink: Color(0xFF8C1B55)),
  (sheet: Color(0xFFE2D8FF), ink: Color(0xFF4B2C9B)),
];

/// A show keeps one paper for good, picked from its id.
_Paper _paperFor(String id) =>
    _papers[id.codeUnits.fold(0, (sum, unit) => sum + unit) % _papers.length];

/// One series as a picture book: its cover on a sheet of paper, then its servable episodes in order.
/// The detail is type-agnostic, so a learning series lands here too.
class SeriesDetailView extends StatefulWidget {
  const SeriesDetailView({
    super.key,
    required this.seriesId,
    this.deviceRepository,
  });

  final String seriesId;
  final DeviceRepository? deviceRepository;

  @override
  State<SeriesDetailView> createState() => _SeriesDetailViewState();
}

class _SeriesDetailViewState extends State<SeriesDetailView> {
  late final Future<SeriesDetail> _detail = catalogueRead(
    () => (widget.deviceRepository ?? sharedDeviceRepository).getSeriesDetail(
      widget.seriesId,
    ),
  );

  void _play(Story story) =>
      context.push('/story?id=${Uri.encodeQueryComponent(story.id)}');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GuestPage.fill(child: Spinner());
        }
        if (snapshot.data case final detail?) {
          return _SeriesPage(detail: detail, onPlay: _play);
        }
        // A 404 covers a removed series and one with no episodes ready; the API never says which.
        final error = snapshot.error!;
        final notFound = error is AuthException && error.statusCode == 404;
        return GuestMessage(
          title: notFound ? 'Series not found' : 'Couldn’t open this series',
          body: notFound
              ? 'It may have been removed, or none of its episodes are ready.'
              : messageOf(error, 'Something went wrong.'),
          onBack: () => goBack(context),
        );
      },
    );
  }
}

class _SeriesPage extends StatelessWidget {
  const _SeriesPage({required this.detail, required this.onPlay});

  final SeriesDetail detail;
  final ValueChanged<Story> onPlay;

  @override
  Widget build(BuildContext context) {
    final paper = _paperFor(detail.series.id);
    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TvInsets.safeX,
          vertical: TvInsets.safeY,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiet: the cover is what should be loud on this page.
            TvButton(
              label: 'Back',
              icon: LucideIcons.arrowLeft,
              variant: TvButtonVariant.quiet,
              size: TvButtonSize.sm,
              autofocus: true,
              onSelect: () => goBack(context),
            ),
            const SizedBox(height: 1.25 * rem),
            _Cover(detail: detail, paper: paper),
            const SizedBox(height: 2.25 * rem),
            Text(
              'Episodes',
              style: TvText.xl.copyWith(
                fontFamily: TvText.baloo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1.5 * rem),
            CardGrid(
              children: [
                for (final episode in detail.episodes)
                  _EpisodeCard(
                    episode: episode,
                    paper: paper,
                    onSelect: () => onPlay(episode.story),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The cover mounted on the show's own sheet, with a scalloped edge under it.
class _Cover extends StatelessWidget {
  const _Cover({required this.detail, required this.paper});

  final SeriesDetail detail;
  final _Paper paper;

  static const _sheetRadius = BorderRadius.vertical(
    top: Radius.circular(2.5 * rem),
  );
  static final _mountShadow = [
    TvShadows.css(const Color(0x73281446), 24, 48, -20),
  ];

  @override
  Widget build(BuildContext context) {
    final series = detail.series;
    final count = detail.episodes.length;
    final prose = TvText.base.copyWith(color: paper.ink.withValues(alpha: 0.9));
    final measure = 56 * TvText.ch(prose);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            3 * rem,
            3 * rem,
            3 * rem,
            2.75 * rem,
          ),
          decoration: BoxDecoration(
            color: paper.sheet,
            borderRadius: _sheetRadius,
          ),
          child: Row(
            spacing: 3 * rem,
            children: [
              // Tilted on the mount, which is not focusable, so the D-pad's geometry stays square.
              Transform.rotate(
                angle: -2 * math.pi / 180,
                child: Container(
                  width: 21 * rem,
                  padding: const EdgeInsets.all(0.75 * rem),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.75 * rem),
                    boxShadow: _mountShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1.1 * rem),
                    child: AspectRatio(
                      aspectRatio: 6 / 5,
                      child: StoryImage(url: series.artworkUrl),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TvText.x3l.copyWith(
                        fontFamily: TvText.baloo,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing:
                            TvText.trackingTight * TvText.x3l.fontSize!,
                        color: paper.ink,
                      ),
                    ),
                    const SizedBox(height: 1.25 * rem),
                    Wrap(
                      spacing: 0.625 * rem,
                      runSpacing: 0.625 * rem,
                      children: [
                        _Tag(
                          icon: LucideIcons.baby,
                          label:
                              AgeGroup.parse(series.ageGroup)?.label ??
                              series.ageGroup,
                          ink: paper.ink,
                        ),
                        _Tag(
                          icon: LucideIcons.sparkles,
                          label: capitalize(series.category),
                          ink: paper.ink,
                        ),
                        // What is watchable now, not the planned run length.
                        _Tag(
                          icon: LucideIcons.bookOpen,
                          label:
                              '$count ${count == 1 ? 'episode' : 'episodes'}',
                          ink: paper.ink,
                        ),
                        _Tag(
                          icon: LucideIcons.languages,
                          label: series.language,
                          ink: paper.ink,
                        ),
                      ],
                    ),
                    if (series.description case final description?)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.25 * rem),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: measure),
                          child: Text(description, style: prose),
                        ),
                      ),
                    if (series.learningObjective case final objective?)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.25 * rem),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: measure),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 0.75 * rem,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 0.25 * rem),
                                child: Icon(
                                  LucideIcons.graduationCap,
                                  size: 1.5 * rem,
                                  color: prose.color,
                                ),
                              ),
                              Flexible(child: Text(objective, style: prose)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size.fromHeight(1.75 * rem),
          painter: _Scallops(paper.sheet),
        ),
      ],
    );
  }
}

/// A paper tag on the cover. White, because the sheet is already the colour.
class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.ink});

  final IconData icon;
  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: rem,
        vertical: 0.375 * rem,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.5 * rem,
        children: [
          Icon(icon, size: 1.25 * rem, color: ink.withValues(alpha: 0.7)),
          Text(
            label,
            style: TvText.sm.copyWith(fontWeight: FontWeight.w700, color: ink),
          ),
        ],
      ),
    );
  }
}

/// The sheet's scalloped lower edge: twelve half-ovals stretched across its width.
class _Scallops extends CustomPainter {
  const _Scallops(this.color);

  static const _count = 12;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / _count;
    final path = Path();
    for (var i = 1; i <= _count; i++) {
      path.arcToPoint(
        Offset(width * i, 0),
        radius: Radius.elliptical(width / 2, size.height),
        clockwise: false,
      );
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Scallops oldDelegate) => oldDelegate.color != color;
}

/// An episode framed like the cover above it, numbered on the corner in the show's colour.
class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.paper,
    required this.onSelect,
  });

  final SeriesEpisode episode;
  final _Paper paper;
  final VoidCallback onSelect;

  static const _mountRadius = BorderRadius.all(Radius.circular(1.5 * rem));
  static final _focusedShadow = [
    TvShadows.css(const Color(0x734C1D95), 18, 36, -18),
  ];
  static final _restingShadow = [
    TvShadows.css(const Color(0x2E0F0A1E), 2, 10, -4),
  ];

  @override
  Widget build(BuildContext context) {
    final story = episode.story;
    final title = story.title.isEmpty ? 'Untitled' : story.title;

    return TvFocusable(
      // The mount draws the ring: one round the whole tile would box in the caption too.
      ring: false,
      borderRadius: _mountRadius,
      semanticLabel: 'Episode ${episode.episodeNumber}, $title',
      onSelect: onSelect,
      // Scale, not a bigger shadow: TV GPUs composite transforms cheaply and repaint large shadows dearly.
      builder: (context, focused) => AnimatedScale(
        scale: focused ? 1.05 : 1,
        duration: TvMotion.cardLift.duration,
        curve: TvMotion.cardLift,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(0.625 * rem),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: _mountRadius,
                    boxShadow: focused ? _focusedShadow : _restingShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(rem),
                    child: AspectRatio(
                      aspectRatio: 6 / 5,
                      child: StoryImage(url: story.artworkUrl),
                    ),
                  ),
                ),
                // Inset, tracing the mount: an outset ring would be pushed under a neighbour by the scale.
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: TvMotion.focusDuration,
                    decoration: BoxDecoration(
                      borderRadius: _mountRadius,
                      border: Border.all(
                        color: focused ? TvColors.ring : Colors.transparent,
                        width: 2 * px,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -0.75 * rem,
                  top: -0.75 * rem,
                  child: Container(
                    width: 3 * rem,
                    height: 3 * rem,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: paper.sheet,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3 * px,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                      boxShadow: TvShadows.md(),
                    ),
                    child: Text(
                      '${episode.episodeNumber}',
                      style: TvText.base.copyWith(
                        fontFamily: TvText.baloo,
                        fontWeight: FontWeight.w800,
                        color: paper.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 0.75 * rem),
            AnimatedDefaultTextStyle(
              duration: TvMotion.focusDuration,
              style: TvText.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: focused ? TvColors.primary : TvColors.foreground,
              ),
              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            // A bucket ("short"), not a running time.
            if (story.duration case final duration?)
              Padding(
                padding: const EdgeInsets.only(top: 0.125 * rem),
                child: Text(
                  capitalize(duration),
                  style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
