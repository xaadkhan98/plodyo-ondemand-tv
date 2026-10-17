import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/repositories/device_repository.dart';
import 'package:plodyo_ondemand_tv/data/repositories/usage_queue.dart';
import 'package:plodyo_ondemand_tv/ui/features/device/story_play.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'plodyo.ondemand.viewing-queue';
const _dayKey = 'plodyo.ondemand.viewing-day';

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
    expect(UsageQueue(_Device(isPaired: false)).start('s1'), isNull);
  });

  test('a start counts one play with the age pick, and nothing that names the room', () {
    final at = DateTime.utc(2026, 10, 25, 12);
    final play = UsageQueue(_Device(), now: () => at).start('s1', ageGroup: '2-4')!;

    expect(
      play['id'],
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
    expect({...play}..remove('id'), {
      'story_id': 's1',
      'occurred_at': '2026-10-25T12:00:00.000Z',
      'age_group': '2-4',
      'start': true,
      'watch_seconds': 0,
      'first_play_today': true,
    });
  });

  test("counts this TV once a day: on the day's first play only", () {
    var now = DateTime(2026, 10, 25, 9);
    final queue = UsageQueue(_Device(), now: () => now);

    final first = queue.start('s1')!;
    final second = queue.start('s2')!;
    now = DateTime(2026, 10, 26, 9);
    final nextDay = queue.start('s1')!;

    expect(first['first_play_today'], isTrue);
    expect(second.containsKey('first_play_today'), isFalse);
    expect(nextDay['first_play_today'], isTrue);
  });

  test('grows an unsent slice in place, and opens a fresh one once that has gone', () {
    final queue = UsageQueue(_Device());
    var slice = queue.start('s1', ageGroup: '0-2')!;

    slice = queue.watched(slice, 5);
    slice = queue.watched(slice, 3);
    expect(queue.takeBatch().single['watch_seconds'], 8);

    queue.acknowledge(queue.takeBatch());
    final fresh = queue.watched(slice, 4);

    final [sent] = queue.takeBatch();
    expect(sent['id'], fresh['id']);
    expect({...sent}..remove('id')..remove('occurred_at'), {
      'story_id': 's1',
      'age_group': '0-2',
      'watch_seconds': 4,
    });
  });

  test(
    'keeps only the unsent seconds of a slice that grew in flight, no longer as a start',
    () {
      final queue = UsageQueue(_Device());
      final slice = queue.watched(queue.start('s1')!, 5);
      final sent = queue.takeBatch();

      queue.watched(slice, 7);
      queue.acknowledge(sent);

      final [left] = queue.takeBatch();
      expect(left['watch_seconds'], 7);
      expect(left.containsKey('start'), isFalse);
      expect(left.containsKey('first_play_today'), isFalse);
    },
  );

  test('a story play counts once it really starts, in whole seconds, with the age pick', () {
    final queue = UsageQueue(_Device());
    final play = StoryPlay('s1', ageGroup: '2-4', usage: queue);

    play.watch(0);
    expect(queue.takeBatch(), isEmpty);

    play
      ..watch(0.6)
      ..watch(0.6)
      ..watch(0.6);
    final [slice] = queue.takeBatch();
    expect(slice['start'], isTrue);
    expect(slice['age_group'], '2-4');
    expect(slice['watch_seconds'], 1);
  });

  test('hands out the oldest 50, and keeps only the newest 500', () {
    final queue = UsageQueue(_Device());
    final ids = [
      for (var i = 0; i < UsageQueue.maxQueued + 20; i++)
        queue.start('s$i')!['id'],
    ];

    final batch = queue.takeBatch();

    expect(batch, hasLength(UsageQueue.maxPerBeat));
    expect(batch.first['id'], ids[20]);
  });

  testWidgets('writes to storage after a short delay and survives a restart', (
    tester,
  ) async {
    final queue = UsageQueue(_Device());
    final play = queue.start('s1')!;
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_storageKey), isNull);

    await tester.pump(UsageQueue.persistDelay);

    final restarted = UsageQueue(_Device());
    await restarted.restore();
    expect(restarted.takeBatch().single['id'], play['id']);
    // The day it was counted on survives too, so a restart does not count the TV twice.
    expect(restarted.start('s2')!.containsKey('first_play_today'), isFalse);
    await restarted.persistNow();
  });

  test('forgets what the session-era build queued, which the API no longer takes', () async {
    SharedPreferences.setMockInitialValues({
      'plodyo.ondemand.usage-queue': jsonEncode([
        {'id': 'e1', 'type': 'AGE_SELECT', 'age_group': '2-4'},
      ]),
    });
    final queue = UsageQueue(_Device());

    await queue.restore();

    expect(queue.takeBatch(), isEmpty);
    expect((await SharedPreferences.getInstance()).getKeys(), isNot(contains('plodyo.ondemand.usage-queue')));
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

  test('persists in the wire format the report sends', () async {
    final queue = UsageQueue(_Device());
    final play = queue.start('s1')!;

    await queue.persistNow();

    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(_storageKey)!), [play]);
    expect(prefs.getString(_dayKey), isNotNull);
  });
}
