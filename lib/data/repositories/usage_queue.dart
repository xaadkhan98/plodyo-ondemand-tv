import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'device_repository.dart';

/// One event in the API's wire format, so the queue is sent exactly as it is stored.
typedef UsageEvent = Map<String, Object?>;

enum UsageType {
  storyPlay('STORY_PLAY'),
  storyComplete('STORY_COMPLETE'),
  languageSelect('LANGUAGE_SELECT'),
  ageSelect('AGE_SELECT');

  const UsageType(this.code);

  final String code;
}

final UsageQueue sharedUsageQueue = UsageQueue(sharedDeviceRepository);

/// What guests do on this TV, held until a heartbeat carries it. Stored, so a power cut loses seconds, not plays.
class UsageQueue {
  UsageQueue(this._device, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _storageKey = 'plodyo.ondemand.usage-queue';

  /// The API's cap per heartbeat.
  static const maxPerBeat = 50;

  /// A TV offline for days keeps its newest events rather than an ever-growing backlog.
  static const maxQueued = 500;

  /// Watch time ticks every second, so storage writes are batched to this.
  static const persistDelay = Duration(seconds: 5);

  final DeviceRepository _device;
  final DateTime Function() _now;
  final Random _random = Random.secure();
  List<UsageEvent> _events = [];
  Timer? _persistTimer;
  DateTime? _lastActive;

  /// Reads what a previous run left unsent. Called once, before the first frame.
  Future<void> restore() async {
    try {
      final stored = (await SharedPreferences.getInstance()).getString(
        _storageKey,
      );
      _events = [
        for (final event in jsonDecode(stored ?? '[]') as List<dynamic>)
          (event as Map).cast<String, Object?>(),
      ];
    } on Object {
      // Unreadable storage starts an empty queue rather than failing every beat.
      _events = [];
    }
  }

  /// Queues a new event. Only a paired TV records, so a console previewing stories never counts as a guest.
  UsageEvent? record(
    UsageType type, {
    String? storyId,
    String? language,
    String? ageGroup,
    int? watchSeconds,
  }) {
    if (!_device.isPaired) return null;
    final event = <String, Object?>{
      'id': _uuid(),
      'type': type.code,
      'occurred_at': _now().toUtc().toIso8601String(),
      'story_id': ?storyId,
      'language': ?language,
      'age_group': ?ageGroup,
      'watch_seconds': ?watchSeconds,
    };
    upsert(event);
    return event;
  }

  /// Queues the event or replaces its queued copy. Re-sending a play is how its watch time grows.
  void upsert(UsageEvent event) {
    final at = _events.indexWhere((queued) => queued['id'] == event['id']);
    if (at >= 0) {
      _events[at] = {...event};
    } else {
      _events.add({...event});
    }
    if (_events.length > maxQueued) {
      _events.removeRange(0, _events.length - maxQueued);
    }
    _persistTimer ??= Timer(persistDelay, persistNow);
  }

  /// The oldest events, copied, so one that grows while in flight is told apart on acknowledge.
  List<UsageEvent> takeBatch() => [
    for (final event in _events.take(maxPerBeat)) {...event},
  ];

  /// Drops what a beat delivered, unless it grew since: that play goes again with its new total.
  void acknowledge(List<UsageEvent> sent) {
    if (sent.isEmpty) return;
    _events.removeWhere(
      (queued) => sent.any(
        (event) =>
            event['id'] == queued['id'] &&
            event['watch_seconds'] == queued['watch_seconds'],
      ),
    );
    _persistTimer ??= Timer(persistDelay, persistNow);
  }

  /// Writes the queue now; also called when the app leaves the screen.
  Future<void> persistNow() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      await (await SharedPreferences.getInstance()).setString(
        _storageKey,
        jsonEncode(_events),
      );
    } on Exception {
      // Kept in memory; it just will not survive a restart.
    }
  }

  /// A remote press, or a story playing.
  void markActive() => _lastActive = _now();

  bool activeWithin(Duration window) =>
      _lastActive != null && _now().difference(_lastActive!) < window;

  /// A version 4 UUID, which the API dedupes re-sent events by.
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
