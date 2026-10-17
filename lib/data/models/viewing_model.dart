/// One line of a property's viewing: a story, or an age group.
class ViewingLine {
  const ViewingLine({
    required this.label,
    required this.plays,
    required this.watchSeconds,
  });

  final String label;
  final int plays;
  final int watchSeconds;
}

/// A property's viewing over a date range. Property totals only: nothing here is per room or per TV.
class ViewingTotals {
  const ViewingTotals({
    required this.plays,
    required this.watchSeconds,
    required this.topStories,
    required this.ageGroups,
    required this.hiddenDays,
    required this.minDevices,
  });

  factory ViewingTotals.fromJson(Map<String, dynamic> json) {
    List<ViewingLine> lines(String key, String labelKey) => [
      for (final row
          in (json[key] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        ViewingLine(
          label: row[labelKey] as String,
          plays: row['plays'] as int,
          watchSeconds: row['watch_seconds'] as int,
        ),
    ];
    return ViewingTotals(
      plays: json['plays'] as int? ?? 0,
      watchSeconds: json['watch_seconds'] as int? ?? 0,
      topStories: lines('top_stories', 'title'),
      ageGroups: lines('age_groups', 'age_group'),
      hiddenDays: json['hidden_days'] as int? ?? 0,
      minDevices: json['min_devices'] as int? ?? 5,
    );
  }

  final int plays;
  final int watchSeconds;
  final List<ViewingLine> topStories;

  /// Labelled by code: '0-2', '2-4', '5-7', or 'all' when the guest had picked none.
  final List<ViewingLine> ageGroups;

  /// Days left out of every figure because fewer than [minDevices] TVs reported.
  final int hiddenDays;
  final int minDevices;
}

/// "3 h 20 min", "45 min", "under a minute".
String formatWatchTime(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes == 0) return seconds == 0 ? '0 min' : 'under a minute';
  final hours = minutes ~/ 60;
  if (hours == 0) return '$minutes min';
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}
