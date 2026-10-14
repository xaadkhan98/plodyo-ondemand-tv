import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/dashed_border.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/rocking.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/paginated_response.dart';
import '../../../../data/models/story_models.dart';
import 'card_grid.dart';
import 'filter_card.dart';
import 'story_card.dart';

/// Rows a grid asks for at a time.
const gridPageSize = 24;

/// What a catalogue grid screen opens with: its sticker title and line, then the filters.
class StoryGridHeader extends StatelessWidget {
  const StoryGridHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filters,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<FilterGroup> filters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2 * rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 1.5 * rem,
        children: [
          PageTitle(icon: icon, title: title, subtitle: subtitle),
          FilterCard(groups: filters),
        ],
      ),
    );
  }
}

/// A paged grid of story cards with an explicit "Load more": focus moves by D-pad, so there is no scroll
/// to hang infinite loading off, and a button is a target the remote can land on. Series ride in it too.
class StoryGrid extends StatefulWidget {
  const StoryGrid({
    super.key,
    required this.query,
    required this.fetchPage,
    required this.onSelect,
    required this.header,
    this.noun = 'stories',
  });

  /// The filters the list is read under; a change starts a fresh list rather than appending to the old one.
  final Object? query;

  /// Fetches one 1-based page of [gridPageSize] rows.
  final Future<PaginatedResponse<Story>> Function(int page) fetchPage;
  final ValueChanged<Story> onSelect;

  /// Above the grid in every state, so the filters in it keep their state while the grid reloads.
  final Widget header;

  /// Plural, for the messages.
  final String noun;

  @override
  State<StoryGrid> createState() => _StoryGridState();
}

class _StoryGridState extends State<StoryGrid> {
  final _stories = <Story>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  // Bumped by a new query, so a page for the old filters never lands in the new list.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(StoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query == oldWidget.query) return;
    _generation++;
    _stories.clear();
    _page = 0;
    _loading = true;
    _loadingMore = false;
    _error = null;
    _fetch();
  }

  Future<void> _fetch() async {
    final generation = _generation;
    try {
      final page = await widget.fetchPage(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _stories.addAll(page.data);
        _page = page.page;
        // `total` counts the whole catalogue under these filters, so the last page is where it is met.
        _hasMore = page.page * page.pageSize < page.total;
        _loading = _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = _loadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
        if (_loading)
          CardGrid(
            gap: 2 * rem,
            rowGap: 2.5 * rem,
            children: [
              for (var i = 0; i < 12; i++)
                const StoryCardSkeleton(fullWidth: true),
            ],
          )
        else if (_error case final error?)
          _GridError(noun: widget.noun, error: error)
        else if (_stories.isEmpty)
          const _Empty()
        else ...[
          // No per-card entrance: it would replay on every "Load more", and the home rails are the one stagger.
          CardGrid(
            gap: 2 * rem,
            rowGap: 2.5 * rem,
            children: [
              for (final story in _stories)
                StoryCard(
                  key: ValueKey(story.id),
                  story: story,
                  fullWidth: true,
                  onSelect: () => widget.onSelect(story),
                ),
            ],
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 3 * rem, bottom: rem),
              child: Center(
                child: _LoadMore(busy: _loadingMore, onSelect: _loadMore),
              ),
            ),
        ],
      ],
    );
  }
}

/// Outlined in primary at rest, not a faint border: a control you could only find by moving focus onto it.
/// Busy swallows the press rather than disabling, so the ring stays put while the next page lands.
class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.busy, required this.onSelect});

  final bool busy;
  final VoidCallback onSelect;

  static const _pill = BorderRadius.all(Radius.circular(999));
  static const _border = 2 * px;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      borderRadius: _pill,
      semanticLabel: 'Load more',
      onSelect: onSelect,
      builder: (context, focused) {
        final ink = focused ? Colors.white : TvColors.foreground;
        return AnimatedScale(
          scale: focused ? 1.05 : 1,
          duration: TvMotion.focusDuration,
          curve: TvMotion.focus,
          child: AnimatedContainer(
            duration: TvMotion.focusDuration,
            padding: const EdgeInsets.symmetric(
              horizontal: 2.5 * rem + _border,
              vertical: rem + _border,
            ),
            decoration: BoxDecoration(
              color: focused ? null : Colors.white,
              gradient: focused ? TvColors.brandBold : null,
              borderRadius: _pill,
              border: Border.all(
                color: focused ? Colors.transparent : TvColors.primary,
                width: _border,
              ),
              boxShadow: focused
                  ? TvShadows.xl(TvColors.primary.withValues(alpha: 0.3))
                  : [TvShadows.css(const Color(0x0D000000), 1, 2, 0)],
            ),
            child: DefaultTextStyle(
              style: TvText.base.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 0.75 * rem,
                children: busy
                    ? [LoadingDots(color: ink), const Text('Loading…')]
                    : [
                        Icon(LucideIcons.plus500, size: 1.5 * rem, color: ink),
                        const Text('Load more'),
                      ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridError extends StatelessWidget {
  const _GridError({required this.noun, required this.error});

  final String noun;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 2 * rem,
        vertical: 1.75 * rem,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(rem),
        border: Border.all(color: TvColors.border, width: px),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 0.25 * rem,
        children: [
          Text(
            'Couldn’t load $noun',
            style: TvText.lg.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            messageOf(error, 'Something went wrong.'),
            style: TvText.base.copyWith(color: TvColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// Nothing under these filters: a rocking pile of books and the two things worth changing.
class _Empty extends StatelessWidget {
  const _Empty();

  static const _radius = BorderRadius.all(Radius.circular(1.5 * rem));

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const DashedBorder(radius: _radius, width: px),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5 * rem),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: _radius,
        ),
        child: Column(
          children: [
            const Rocking(
              tilt: 7,
              rise: 8 * px,
              child: ExcludeSemantics(
                child: Text(
                  '📚',
                  style: TextStyle(fontSize: 3.75 * rem, height: 1),
                ),
              ),
            ),
            const SizedBox(height: rem),
            Text(
              'Nothing here yet',
              style: TvText.lg.copyWith(
                fontFamily: TvText.fredoka,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 0.25 * rem),
            Text(
              'Try a different age group or language.',
              style: TvText.base.copyWith(color: TvColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
