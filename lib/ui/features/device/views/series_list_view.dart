import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/filter_card.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_grid.dart';

/// The API's ceiling for one page, and the widest net for the topic chips.
const _topicScanSize = 100;

/// Categories are free text, so a topic's picture is matched on the words in it.
final _topicEmoji = <(RegExp, String)>[
  (RegExp('math|number|count|logic|shape', caseSensitive: false), '🔢'),
  (
    RegExp('litera|read|word|letter|alphabet|language', caseSensitive: false),
    '🔤',
  ),
  (RegExp('science|space|planet|star|discover', caseSensitive: false), '🚀'),
  (
    RegExp('nature|animal|wildlife|forest|ocean|sea', caseSensitive: false),
    '🐾',
  ),
  (RegExp('music|song|rhyme|dance', caseSensitive: false), '🎵'),
  (RegExp('art|colou?r|draw|craft|creat', caseSensitive: false), '🎨'),
  (RegExp('emotion|feel|kind|social|friend|share', caseSensitive: false), '💛'),
  (RegExp('body|health|food|eat|grow', caseSensitive: false), '🍎'),
  (RegExp('bedtime|sleep|night|dream|calm', caseSensitive: false), '🌙'),
  (RegExp('advent|explore|journey|travel|world', caseSensitive: false), '🗺️'),
  (RegExp('holiday|festiv|season|celebrat', caseSensitive: false), '🎉'),
];

/// Published series of one type, a page at a time. A card opens its episode list, since a series has no
/// media of its own. Series and Learning are both this screen, differing by type, title and icon.
class SeriesListView extends StatefulWidget {
  const SeriesListView({super.key, required this.type, this.deviceRepository});

  final SeriesType type;
  final DeviceRepository? deviceRepository;

  @override
  State<SeriesListView> createState() => _SeriesListViewState();
}

class _SeriesListViewState extends State<SeriesListView> {
  late final DeviceRepository _catalogue =
      widget.deviceRepository ?? sharedDeviceRepository;
  String? _category;
  Future<List<String>>? _topics;
  Object? _topicsFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final device = DeviceScope.of(context);
    final filters = (device.language, device.ageGroup);
    if (filters == _topicsFor) return;
    _topicsFor = filters;
    // No endpoint lists the categories in use, so the chips are read off a wide first page under the
    // grid's own filters. ponytail: one 100-row scan; a categories endpoint if a room ever outgrows it.
    _topics =
        catalogueRead(
          () => _catalogue.getSeries(
            seriesType: widget.type,
            language: device.language,
            ageGroup: device.ageGroup,
            pageSize: _topicScanSize,
          ),
        ).then(
          (page) =>
              {for (final series in page.data) series.category}.toList()
                ..sort(),
        );
  }

  /// "What's it about", or null where there is one topic or none: one topic is the whole screen under a chip.
  /// "All topics" is always offered, so a topic gone under a new language cannot strand the filter.
  FilterGroup? _topicFilter(List<String>? topics) {
    if (topics == null || topics.length < 2) return null;
    return FilterGroup(
      label: "What's it about",
      value: _category,
      options: [
        const FilterOption(value: null, label: 'All topics', emoji: '🌈'),
        for (final name in topics)
          FilterOption(
            value: name,
            // Categories come back lowercase; a chip is a proper name.
            label: name.isEmpty
                ? name
                : name[0].toUpperCase() + name.substring(1),
            emoji:
                _topicEmoji
                    .where((topic) => topic.$1.hasMatch(name))
                    .firstOrNull
                    ?.$2 ??
                '⭐',
          ),
      ],
      onChange: (category) => setState(() => _category = category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceScope.of(context);
    final (language, ageGroup, category) = (
      device.language,
      device.ageGroup,
      _category,
    );
    final (title, icon, subtitle) = switch (widget.type) {
      SeriesType.entertainment => (
        'Series',
        LucideIcons.layers,
        'Shows with lots of episodes — one more before bed? 🍿',
      ),
      SeriesType.learning => (
        'Learning series',
        LucideIcons.graduationCap,
        'Learn something brand new today, one giggle at a time 🌟',
      ),
    };
    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TvInsets.safeX,
          vertical: TvInsets.safeY,
        ),
        child: FutureBuilder(
          future: _topics,
          builder: (context, topics) => StoryGrid(
            query: (language, ageGroup, category),
            noun: 'series',
            fetchPage: (page) => catalogueRead(
              () => _catalogue.getSeries(
                seriesType: widget.type,
                language: language,
                ageGroup: ageGroup,
                category: category,
                page: page,
                pageSize: gridPageSize,
              ),
            ).then((page) => page.map((series) => series.asCard)),
            onSelect: (series) => openSeries(context, series),
            header: StoryGridHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              filters: [?ageFilter(device), ?_topicFilter(topics.data)],
            ),
          ),
        ),
      ),
    );
  }
}
