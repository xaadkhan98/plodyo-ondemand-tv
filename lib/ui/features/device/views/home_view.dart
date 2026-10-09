import 'package:flutter/material.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/guest_page.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/story_rail.dart';

/// The room's home screen: a featured hero, then one rail per category, ten deep, in the rail's order.
/// No filters here: language is the pill in the top bar, and age narrows a whole category on its own screen.
class HomeView extends StatefulWidget {
  const HomeView({super.key, this.deviceRepository});

  final DeviceRepository? deviceRepository;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Ten per rail; the rest of each category lives behind its own route.
  static const _railSize = 10;

  late final DeviceRepository _device =
      widget.deviceRepository ?? sharedDeviceRepository;
  late Future<List<Story>> _stories;
  late Future<List<Story>> _series;
  late Future<List<Story>> _learning;
  String? _language;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = DeviceScope.of(context).language;
    if (_loaded && language == _language) return;
    _loaded = true;
    _language = language;
    // The hero shares the stories rail's page rather than fetching the same rows twice.
    _stories = catalogueRead(
      () => _device.getStories(
        storyType: StoryType.standalone,
        language: language,
        pageSize: _railSize,
      ),
    ).then((page) => page.data);
    _series = _seriesRail(SeriesType.entertainment);
    _learning = _seriesRail(SeriesType.learning);
  }

  Future<List<Story>> _seriesRail(SeriesType type) => catalogueRead(
    () => _device.getSeries(
      seriesType: type,
      language: _language,
      pageSize: _railSize,
    ),
  ).then((page) => [for (final series in page.data) series.asCard]);

  @override
  Widget build(BuildContext context) {
    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.only(
          left: TvInsets.safeX,
          bottom: TvInsets.safeY,
        ),
        child: FutureBuilder(
          future: _stories,
          builder: (context, snapshot) {
            final stories = _rows(snapshot);
            // With no hero to take first focus, the first series card does.
            final noHero = stories != null && stories.isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: TvInsets.safeX),
                  child: HeroCarousel(
                    stories: stories,
                    onSelect: (story) => openStory(context, story),
                  ),
                ),
                StoryRail(
                  title: 'Stories',
                  subtitle: 'One story at a time, start to finish.',
                  stories: stories,
                  error: _error(snapshot),
                  onSelect: (story) => openStory(context, story),
                ),
                _SeriesRail(
                  future: _series,
                  title: 'Series',
                  subtitle: 'Follow the same friends through every episode.',
                  autofocus: noHero,
                  onSelect: (series) => openSeries(context, series),
                ),
                _SeriesRail(
                  future: _learning,
                  title: 'Learning series',
                  subtitle:
                      'Numbers, words and feelings, one episode at a time.',
                  autofocus: noHero,
                  onSelect: (series) => openSeries(context, series),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A rail's rows: null while a load is in flight (a new language included), empty once one has failed.
List<Story>? _rows(AsyncSnapshot<List<Story>> snapshot) =>
    snapshot.connectionState == ConnectionState.done
    ? (snapshot.data ?? const [])
    : null;

Object? _error(AsyncSnapshot<List<Story>> snapshot) =>
    snapshot.connectionState == ConnectionState.done ? snapshot.error : null;

class _SeriesRail extends StatelessWidget {
  const _SeriesRail({
    required this.future,
    required this.title,
    required this.subtitle,
    required this.autofocus,
    required this.onSelect,
  });

  final Future<List<Story>> future;
  final String title;
  final String subtitle;
  final bool autofocus;
  final ValueChanged<Story> onSelect;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        final series = _rows(snapshot);
        final error = _error(snapshot);
        // A category with nothing in it leaves no empty labelled row on the home screen.
        if (series != null && series.isEmpty && error == null) {
          return const SizedBox.shrink();
        }
        return StoryRail(
          title: title,
          subtitle: subtitle,
          stories: series,
          error: error,
          autofocus: autofocus,
          onSelect: onSelect,
        );
      },
    );
  }
}
