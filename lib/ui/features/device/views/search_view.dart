import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/blinking_caret.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/rocking.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/device_models.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/card_grid.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_card.dart';

/// Rows a search reads: three of the API's 100-row pages. Past it the screen says it searched part.
const searchScanLimit = 300;
const _scanPageSize = 100;
const _minTerm = 2;
const _maxTerm = 40;

enum _Field { term }

/// The catalogue as far as a search reads it, and how much there is in all.
typedef _Scan = ({List<Story> stories, int total});

/// Up to [searchScanLimit] rows, matched here because the catalogue has no search parameter. Stops at
/// the first short page, so a room of 40 stories costs one request.
Future<_Scan> _scanCatalogue(
  DeviceRepository catalogue, {
  String? language,
  AgeGroup? ageGroup,
}) async {
  final stories = <Story>[];
  var total = 0;
  for (var page = 1; stories.length < searchScanLimit; page++) {
    final result = await catalogue.getStories(
      language: language,
      ageGroup: ageGroup,
      page: page,
      pageSize: _scanPageSize,
    );
    total = result.total;
    stories.addAll(result.data);
    if (result.data.isEmpty || stories.length >= total) break;
  }
  return (stories: stories.take(searchScanLimit).toList(), total: total);
}

/// Finds a story by title in the room's catalogue: the keyboard and the query on the left, matches on
/// the right. A physical keyboard types straight in; Back deletes, and leaves once the query is empty.
class SearchView extends StatefulWidget {
  const SearchView({super.key, this.deviceRepository});

  final DeviceRepository? deviceRepository;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final DeviceRepository _catalogue =
      widget.deviceRepository ?? sharedDeviceRepository;
  late final TextEntryController<_Field> _entry = TextEntryController(
    _Field.values,
    maxLength: _maxTerm,
  )..addListener(_onType);
  final _firstKey = FocusNode();
  Timer? _settle;
  String _settled = '';
  Future<_Scan>? _scan;
  Object? _scanFor;

  @override
  void initState() {
    super.initState();
    // The keyboard is the screen's one way in, so it takes the ring.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstKey.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final device = DeviceScope.of(context);
    final filters = (device.language, device.ageGroup);
    if (filters == _scanFor) return;
    _scanFor = filters;
    // Read once per language and age; the catalogue does not change while a guest is typing.
    _scan = catalogueRead(
      () => _scanCatalogue(
        _catalogue,
        language: device.language,
        ageGroup: device.ageGroup,
      ),
    );
  }

  @override
  void dispose() {
    _settle?.cancel();
    _entry.dispose();
    _firstKey.dispose();
    super.dispose();
  }

  // The query shows every key at once; matching waits for a pause in typing.
  void _onType() {
    _settle?.cancel();
    _settle = Timer(
      const Duration(milliseconds: 250),
      () => setState(() => _settled = _entry.value),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final term = _entry.value;
    return GuestPage.fill(
      child: TextEntryScope(
        controller: _entry,
        onExit: () => goBack(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TvInsets.safeX,
            0,
            TvInsets.safeX,
            TvInsets.safeY,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 3 * rem,
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageTitle(
                      icon: LucideIcons.search,
                      title: 'Search',
                      subtitle: "By title, across this room's stories.",
                    ),
                    const SizedBox(height: 1.5 * rem),
                    _Query(term),
                    const SizedBox(height: 1.5 * rem),
                    OnScreenKeyboard(
                      controller: _entry,
                      entryFocusNode: _firstKey,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _scan,
                  builder: (context, scan) => _Results(
                    typed: term.trim().length >= _minTerm,
                    settled: _settled,
                    scan: scan,
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

/// The query as typed, with its caret. Not a native field: that would raise the TV's own keyboard.
class _Query extends StatelessWidget {
  const _Query(this.term);

  final String term;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 4 * rem,
      padding: const EdgeInsets.symmetric(horizontal: 1.25 * rem + 2 * px),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rem),
        border: Border.all(color: TvColors.border, width: 2 * px),
      ),
      child: Row(
        spacing: 0.75 * rem,
        children: [
          const Icon(
            LucideIcons.search,
            size: 1.5 * rem,
            color: TvColors.mutedForeground,
          ),
          Flexible(
            child: Text(
              term.isEmpty ? 'Search stories…' : term,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TvText.base.copyWith(
                color: term.isEmpty
                    ? TvColors.mutedForeground
                    : TvColors.foreground,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 0.125 * rem),
            child: BlinkingCaret(height: 1.75 * rem),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.typed,
    required this.settled,
    required this.scan,
  });

  /// Enough has been typed to search on.
  final bool typed;

  /// The query as of the last pause in typing, which is what is matched.
  final String settled;
  final AsyncSnapshot<_Scan> scan;

  @override
  Widget build(BuildContext context) {
    final needle = settled.trim().toLowerCase();
    // Until a typed query settles, the prompt stays rather than flashing "no results" for half a word.
    if (!typed || needle.length < _minTerm) {
      return const _Prompt(
        title: 'What would you like to watch?',
        body: 'Use the keyboard to search by title.',
      );
    }
    if (scan.connectionState != ConnectionState.done) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(0.75 * rem),
        child: CardGrid(
          columns: 3,
          gap: 1.5 * rem,
          children: [for (var i = 0; i < 10; i++) const _SkeletonResult()],
        ),
      );
    }
    if (scan.error case final error?) {
      return _Prompt(
        title: 'Couldn’t search',
        body: messageOf(error, 'Something went wrong.'),
      );
    }
    final (:stories, :total) = scan.requireData;
    final partial = total > searchScanLimit;
    final results = [
      for (final story in stories)
        if (story.title.toLowerCase().contains(needle)) story,
    ];
    if (results.isEmpty) {
      return _Prompt(
        title: 'No results for “$settled”',
        body: partial
            ? 'Only the first $searchScanLimit stories in this room are searched. Try narrowing by age or language.'
            : 'Try a different word.',
      );
    }
    // Padded so a focused card's lift is not clipped at the pane's edge.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0.75 * rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${results.length} result${results.length == 1 ? '' : 's'}'
            '${partial ? ' · searching the first $searchScanLimit of $total' : ''}',
            style: TvText.sm.copyWith(color: TvColors.mutedForeground),
          ),
          const SizedBox(height: 1.25 * rem),
          CardGrid(
            columns: 3,
            gap: 1.5 * rem,
            rowGap: 2 * rem,
            children: [
              for (final (i, story) in results.indexed)
                _Arrival(
                  key: ValueKey(story.id),
                  delay: Duration(milliseconds: math.min(i * 30, 300)),
                  child: StoryCard(
                    story: story,
                    fullWidth: true,
                    onSelect: () => openStory(context, story),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A result fading in as it rises 16px, a beat after the one before it.
class _Arrival extends StatefulWidget {
  const _Arrival({super.key, required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival>
    with SingleTickerProviderStateMixin {
  static const _rise = Duration(milliseconds: 300);

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: widget.delay + _rise,
  )..forward();
  late final Animation<double> _t = CurvedAnimation(
    parent: _in,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _rise).inMilliseconds,
      1,
      curve: TvMotion.focus,
    ),
  );

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 16 * px * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _SkeletonResult extends StatelessWidget {
  const _SkeletonResult();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 6 / 5,
          child: Skeleton(borderRadius: BorderRadius.all(Radius.circular(rem))),
        ),
        SizedBox(height: 0.75 * rem),
        FractionallySizedBox(
          widthFactor: 0.75,
          child: Skeleton(height: 1.25 * rem),
        ),
      ],
    );
  }
}

/// The pane's resting states: what to do, why nothing matched, or why nothing loaded.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final style = TvText.base.copyWith(color: TvColors.mutedForeground);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Rocking(
            tilt: 4,
            rise: 10 * px,
            child: Icon(
              LucideIcons.search,
              size: 3.5 * rem,
              color: TvColors.mutedForeground.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: rem),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TvText.lg.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 0.25 * rem),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 46 * TvText.ch(style)),
            child: Text(body, textAlign: TextAlign.center, style: style),
          ),
        ],
      ),
    );
  }
}
