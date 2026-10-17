import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'device_repository.dart';

/// A slice of one play in the API's wire format, plus a local `id` the API never sees.
typedef UsageEvent = Map<String, Object?>;

final UsageQueue sharedUsageQueue = UsageQueue(sharedDeviceRepository);

/// What guests watch on this TV, held until a report carries it to the property's totals. Stored, so a power
/// cut loses seconds, not plays. Each slice holds only seconds not yet sent, so the API just adds them up.
class UsageQueue {
  UsageQueue(this._device, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _storageKey = 'plodyo.ondemand.viewing-queue';
  static const _dayKey = 'plodyo.ondemand.viewing-day';

  /// Where the session-era build queued events the API no longer takes.
  static const _legacyKey = 'plodyo.ondemand.usage-queue';

  /// The API's cap per report.
  static const maxPerBeat = 50;

  /// A TV offline for days keeps its newest slices rather than an ever-growing backlog.
  static const maxQueued = 500;

  /// Watch time ticks every second, so storage writes are batched to this.
  static const persistDelay = Duration(seconds: 5);

  final DeviceRepository _device;
  final DateTime Function() _now;
  final Random _random = Random.secure();
  List<UsageEvent> _events = [];
  String? _countedDay;
  Timer? _persistTimer;
  DateTime? _lastActive;

  /// Reads what a previous run left unsent. Called once, before the first frame.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
      _countedDay = prefs.getString(_dayKey);
      _events = [
        for (final event
            in jsonDecode(prefs.getString(_storageKey) ?? '[]') as List<dynamic>)
          (event as Map).cast<String, Object?>(),
      ];
    } on Object {
      // Unreadable storage starts an empty queue rather than failing every report.
      _events = [];
    }
  }

  /// A play starting: counts one play, with the guest's age pick. The day's first also counts this TV, which
  /// is how the console tells a busy day from one TV's. Null unpaired, so the console never counts as a guest.
  UsageEvent? start(String storyId, {String? ageGroup}) {
    if (!_device.isPaired) return null;
    final now = _now();
    final day = _localDay(now);
    final event = <String, Object?>{
      'id': _uuid(),
      'story_id': storyId,
      'occurred_at': now.toUtc().toIso8601String(),
      'age_group': ?ageGroup,
      'start': true,
      'watch_seconds': 0,
      if (day != _countedDay) 'first_play_today': true,
    };
    _countedDay = day;
    _add(event);
    return event;
  }

  /// Adds seconds to a play: onto its slice while that is unsent, else onto a fresh one. Returns the slice to
  /// add to next time.
  UsageEvent watched(UsageEvent play, int seconds) {
    final at = _events.indexWhere((queued) => queued['id'] == play['id']);
    if (at >= 0) {
      final grown = {
        ..._events[at],
        'watch_seconds': (_events[at]['watch_seconds']! as int) + seconds,
      };
      _events[at] = grown;
      _persistSoon();
      return grown;
    }
    final next = <String, Object?>{
      'id': _uuid(),
      'story_id': play['story_id'],
      'occurred_at': _now().toUtc().toIso8601String(),
      'age_group': ?play['age_group'],
      'watch_seconds': seconds,
    };
    _add(next);
    return next;
  }

  void _add(UsageEvent event) {
    _events.add(event);
    if (_events.length > maxQueued) {
      _events.removeRange(0, _events.length - maxQueued);
    }
    _persistSoon();
  }

  /// The oldest slices, copied, so one that grows while in flight is told apart on acknowledge.
  List<UsageEvent> takeBatch() => [
    for (final event in _events.take(maxPerBeat)) {...event},
  ];

  /// Drops what a report delivered. A slice that grew in flight keeps only its unsent seconds, and is no
  /// longer a start: that play has been counted.
  void acknowledge(List<UsageEvent> sent) {
    if (sent.isEmpty) return;
    for (final event in sent) {
      final at = _events.indexWhere((queued) => queued['id'] == event['id']);
      if (at < 0) continue;
      final left =
          (_events[at]['watch_seconds']! as int) -
          (event['watch_seconds']! as int);
      if (left > 0) {
        _events[at] = {..._events[at], 'watch_seconds': left}
          ..remove('start')
          ..remove('first_play_today');
      } else {
        _events.removeAt(at);
      }
    }
    _persistSoon();
  }

  void _persistSoon() => _persistTimer ??= Timer(persistDelay, persistNow);

  /// Writes the queue now; also called when the app leaves the screen.
  Future<void> persistNow() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_events));
      if (_countedDay case final day?) await prefs.setString(_dayKey, day);
    } on Exception {
      // Kept in memory; it just will not survive a restart.
    }
  }

  /// A remote press, or a story playing.
  void markActive() => _lastActive = _now();

  bool activeWithin(Duration window) =>
      _lastActive != null && _now().difference(_lastActive!) < window;

  // The set's own calendar day, which is the venue's when its clock is.
  static String _localDay(DateTime at) =>
      at.toLocal().toIso8601String().substring(0, 10);

  /// A version 4 UUID, which only matches acknowledgements on this TV.
  String _uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
