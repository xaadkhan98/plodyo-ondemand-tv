import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/device_models.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/viewing_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

/// What guests watched, for a whole property. There is deliberately no room, TV or per-device view of it.
class ViewingView extends StatefulWidget {
  const ViewingView({
    super.key,
    this.propertiesRepository,
    this.authRepository,
    this.today = DateTime.now,
  });

  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final DateTime Function() today;

  @override
  State<ViewingView> createState() => _ViewingViewState();
}

class _ViewingViewState extends State<ViewingView> {
  static const _ranges = [
    Choice(value: 7, label: 'Last 7 days'),
    Choice(value: 30, label: 'Last 30 days'),
    Choice(value: 90, label: 'Last 90 days'),
  ];

  // The TV console has room for five; the web console lists all ten.
  static const _topStories = 5;

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PropertiesRepository _repo =
      widget.propertiesRepository ?? sharedPropertiesRepository;

  List<PropertyModel>? _properties;
  String? _propertyId;
  int _days = 30;
  ViewingTotals? _totals;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final page = await _repo.getProperties(
        accessToken: _auth.accessToken,
        pageSize: pickerPageSize,
      );
      if (!mounted) return;
      setState(() {
        _properties = page.data;
        _propertyId = page.data.isEmpty ? null : page.data.first.id;
      });
      _load();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _load() async {
    final propertyId = _propertyId;
    if (propertyId == null) return;
    final request = ++_request;
    final to = widget.today();
    setState(() {
      _totals = null;
      _error = null;
    });
    try {
      final totals = await _repo.getViewing(
        accessToken: _auth.accessToken,
        propertyId: propertyId,
        from: _day(to.subtract(Duration(days: _days - 1))),
        to: _day(to),
      );
      if (mounted && request == _request) setState(() => _totals = totals);
    } on Object catch (error) {
      if (mounted && request == _request) setState(() => _error = error);
    }
  }

  static String _day(DateTime at) => at.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final properties = _properties;
    return ConsolePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            icon: LucideIcons.chartColumn,
            title: 'Viewing',
            subtitle:
                'What guests watched, for the whole property. Nothing here is per room or per TV.',
          ),
          const SizedBox(height: 1.5 * rem),
          if (properties != null && properties.length > 1) ...[
            ChoiceGroup<String>(
              value: _propertyId!,
              layout: ChoiceLayout.chips,
              autofocus: true,
              onChanged: (id) {
                setState(() => _propertyId = id);
                _load();
              },
              options: [
                for (final property in properties)
                  Choice(value: property.id, label: property.name),
              ],
            ),
            const SizedBox(height: 0.75 * rem),
          ],
          ChoiceGroup<int>(
            value: _days,
            layout: ChoiceLayout.chips,
            autofocus: properties == null || properties.length <= 1,
            onChanged: (days) {
              setState(() => _days = days);
              _load();
            },
            options: _ranges,
          ),
          const SizedBox(height: 1.75 * rem),
          ..._results(properties),
        ],
      ),
    );
  }

  List<Widget> _results(List<PropertyModel>? properties) {
    if (_error case final error?) {
      return [
        StatusMessage(
          tone: StatusTone.error,
          message: messageOf(error, 'Could not load viewing.'),
        ),
      ];
    }
    if (properties != null && properties.isEmpty) {
      return const [
        StatusMessage(
          tone: StatusTone.info,
          message: 'No properties yet. Viewing appears once a property has TVs.',
        ),
      ];
    }
    final totals = _totals;
    if (totals == null) return const [Spinner()];
    return [
      TwoColumnGrid(
        children: [
          DetailCard.text(
            icon: LucideIcons.play,
            label: 'Plays',
            value: '${totals.plays}',
          ),
          DetailCard.text(
            icon: LucideIcons.clock,
            label: 'Watch time',
            value: formatWatchTime(totals.watchSeconds),
          ),
        ],
      ),
      if (totals.hiddenDays > 0) ...[
        const SizedBox(height: rem),
        StatusMessage(
          tone: StatusTone.info,
          message:
              '${totals.hiddenDays} ${totals.hiddenDays == 1 ? 'day is' : 'days are'} left out: fewer than '
              '${totals.minDevices} TVs reported, so no single household can be picked out.',
        ),
      ],
      const SizedBox(height: 1.5 * rem),
      TwoColumnGrid(
        children: [
          _Lines(
            title: 'Top stories',
            empty: 'No plays in this range.',
            lines: totals.topStories.take(_topStories).toList(),
          ),
          _Lines(
            title: 'By age group',
            empty: 'No plays in this range.',
            lines: [
              for (final line in totals.ageGroups)
                ViewingLine(
                  label: AgeGroup.parse(line.label)?.label ?? 'No age picked',
                  plays: line.plays,
                  watchSeconds: line.watchSeconds,
                ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.title, required this.empty, required this.lines});

  final String title;
  final String empty;
  final List<ViewingLine> lines;

  @override
  Widget build(BuildContext context) {
    final muted = TvText.base.copyWith(color: TvColors.mutedForeground);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.5 * rem,
      children: [
        SectionHeading(title),
        if (lines.isEmpty) Text(empty, style: muted),
        for (final line in lines)
          Row(
            spacing: rem,
            children: [
              Expanded(
                child: Text(
                  line.label,
                  style: TvText.base,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${line.plays} ${line.plays == 1 ? 'play' : 'plays'} · ${formatWatchTime(line.watchSeconds)}',
                style: muted,
              ),
            ],
          ),
      ],
    );
  }
}
