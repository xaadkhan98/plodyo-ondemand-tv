import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../data/models/story_models.dart';
import '../../../../data/repositories/device_repository.dart';
import '../device_controller.dart';
import '../widgets/filter_card.dart';
import '../widgets/guest_page.dart';
import '../widgets/story_grid.dart';

/// Standalone stories, a page at a time. Episodes stay with their series: loose in this grid, eight
/// episodes of one show read as eight unrelated stories.
class StoriesView extends StatelessWidget {
  const StoriesView({super.key, this.deviceRepository});

  final DeviceRepository? deviceRepository;

  @override
  Widget build(BuildContext context) {
    final device = DeviceScope.of(context);
    final catalogue = deviceRepository ?? sharedDeviceRepository;
    final (language, ageGroup) = (device.language, device.ageGroup);
    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TvInsets.safeX,
          vertical: TvInsets.safeY,
        ),
        child: StoryGrid(
          query: (language, ageGroup),
          fetchPage: (page) => catalogueRead(
            () => catalogue.getStories(
              storyType: StoryType.standalone,
              language: language,
              ageGroup: ageGroup,
              page: page,
              pageSize: gridPageSize,
            ),
          ),
          onSelect: (story) => openStory(context, story),
          header: StoryGridHeader(
            icon: LucideIcons.library,
            title: ageGroup?.label ?? 'Stories',
            subtitle: "Pick a story and let's go somewhere magical ✨",
            filters: [?ageFilter(device)],
          ),
        ),
      ),
    );
  }
}
