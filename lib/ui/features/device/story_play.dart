import '../../../data/repositories/usage_queue.dart';

/// One opening of a story: counted once it has really started, then its watch time reported as it grows.
class StoryPlay {
  StoryPlay(this.storyId, {this.ageGroup, UsageQueue? usage})
    : _usage = usage ?? sharedUsageQueue;

  final String storyId;

  /// The guest's pick when the story opened. It leaves the TV only inside the property's totals.
  final String? ageGroup;
  final UsageQueue _usage;
  UsageEvent? _slice;
  double _seconds = 0;
  int _reported = 0;

  /// Adds time actually spent in the story; the first call is what counts the play.
  void watch(double seconds) {
    if (seconds <= 0) return;
    _usage.markActive();
    final slice = _slice ??= _usage.start(storyId, ageGroup: ageGroup);
    if (slice == null) return;
    _seconds += seconds;
    // Whole seconds only, so a play touches the queue once a second at most.
    final whole = _seconds.floor();
    if (whole > _reported) {
      _slice = _usage.watched(slice, whole - _reported);
      _reported = whole;
    }
  }
}
