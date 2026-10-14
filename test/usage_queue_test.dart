import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'plodyo.ondemand.usage-queue';

class _Device implements DeviceRepository {
  _Device({this.isPaired = true});

  @override
  final bool isPaired;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records nothing unpaired, so the console never counts as a guest', () {
    expect(
      UsageQueue(_Device(isPaired: false)).record(UsageType.languageSelect),
      isNull,
    );
  });

  test('stamps each event with a v4 uuid and the clock', () {
    final at = DateTime.utc(2026, 10, 9, 12);
    final event = UsageQueue(
      _Device(),
      now: () => at,
    ).record(UsageType.ageSelect, ageGroup: '2-4')!;

    expect(
      event['id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(event['occurred_at'], '2026-10-09T12:00:00.000Z');
    expect(event['age_group'], '2-4');
    expect(event.containsKey('story_id'), isFalse);
  });

  test('replaces a queued event in place rather than queueing it twice', () {
    final queue = UsageQueue(_Device());
    final play = queue.record(
      UsageType.storyPlay,
      storyId: 's1',
      watchSeconds: 5,
    )!;

    queue.upsert({...play, 'watch_seconds': 30});

    expect(queue.takeBatch(), [
      {...play, 'watch_seconds': 30},
    ]);
  });

  test('hands out the oldest 50, and keeps only the newest 500', () {
    final queue = UsageQueue(_Device());
    final ids = [
      for (var i = 0; i < UsageQueue.maxQueued + 20; i++)
        queue.record(UsageType.languageSelect, language: 'ENG')!['id'],
    ];

    final batch = queue.takeBatch();

    expect(batch, hasLength(UsageQueue.maxPerBeat));
    expect(batch.first['id'], ids[20]);
  });

  test(
    'drops what a beat delivered, but re-sends a play that grew in flight',
    () {
      final queue = UsageQueue(_Device());
      final pick = queue.record(UsageType.languageSelect, language: 'ENG')!;
      final play = queue.record(
        UsageType.storyPlay,
        storyId: 's1',
        watchSeconds: 5,
      )!;
      final sent = queue.takeBatch();

      queue.upsert({...play, 'watch_seconds': 12});
      queue.acknowledge(sent);

      final left = queue.takeBatch();
      expect(left.map((e) => e['id']), [play['id']]);
      expect(left.single['watch_seconds'], 12);
      expect(left.any((e) => e['id'] == pick['id']), isFalse);
    },
  );

  testWidgets('writes to storage after a short delay and survives a restart', (
    tester,
  ) async {
    final queue = UsageQueue(_Device());
    final event = queue.record(UsageType.languageSelect, language: 'ENG')!;
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_storageKey), isNull);

    await tester.pump(UsageQueue.persistDelay);

    final restarted = UsageQueue(_Device());
    await restarted.restore();
    expect(restarted.takeBatch().single['id'], event['id']);
  });

  test('starts empty rather than failing when storage holds garbage', () async {
    SharedPreferences.setMockInitialValues({_storageKey: '{not json'});
    final queue = UsageQueue(_Device());

    await queue.restore();

    expect(queue.takeBatch(), isEmpty);
  });

  test('is active only within the window after the last activity', () {
    var now = DateTime.utc(2026, 10, 9, 12);
    final queue = UsageQueue(_Device(), now: () => now);
    const window = Duration(minutes: 1);
    expect(queue.activeWithin(window), isFalse);

    queue.markActive();
    now = now.add(const Duration(seconds: 59));
    expect(queue.activeWithin(window), isTrue);

    now = now.add(const Duration(seconds: 1));
    expect(queue.activeWithin(window), isFalse);
  });

  test('persists in the wire format the heartbeat sends', () async {
    final queue = UsageQueue(_Device());
    final event = queue.record(UsageType.storyComplete, storyId: 's1')!;

    await queue.persistNow();

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(_storageKey)!), [event]);
  });
}
