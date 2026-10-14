import '../../../data/repositories/usage_queue.dart';

/// One opening of a story: recorded once it has really started, then its watch time grows in place.
class StoryPlay {
  StoryPlay(this.storyId, {UsageQueue? usage})
    : _usage = usage ?? sharedUsageQueue;

  final String storyId;
  final UsageQueue _usage;
  UsageEvent? _event;
  double _seconds = 0;
  bool _completed = false;

  /// Adds time actually spent in the story; the first call is what records the play.
  void watch(double seconds) {
    if (seconds <= 0) return;
    _usage.markActive();
    final event = _event ??= _usage.record(
      UsageType.storyPlay,
      storyId: storyId,
      watchSeconds: 0,
    );
    if (event == null) return;
    _seconds += seconds;
    // Whole seconds only, so a play is re-queued once a second at most.
    final whole = _seconds.floor();
    if (whole != event['watch_seconds']) {
      _usage.upsert(_event = {...event, 'watch_seconds': whole});
    }
  }

  /// The story reached its end, recorded once per play.
  void complete() {
    if (_event == null || _completed) return;
    _completed = true;
    _usage.record(UsageType.storyComplete, storyId: storyId);
  }
}
