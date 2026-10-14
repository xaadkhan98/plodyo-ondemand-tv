import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/room_model.dart';
import 'package:plodyo_ondemand_tv/ui/features/rooms/views/add_many_rooms_view.dart';
import 'package:plodyo_ondemand_tv/ui/features/rooms/widgets/room_presence.dart';

void main() {
  test(
    'duplicateLabels finds repeats trimmed and case-insensitively, in first-repeat order',
    () {
      expect(
        duplicateLabels([
          'Room 101',
          'Room 102',
          ' room 101 ',
          'Room 102',
          '',
          '',
        ]),
        ['room 101', 'Room 102'],
      );
      expect(duplicateLabels(['101', '102']), isEmpty);
    },
  );

  test(
    'presenceOf: online inside three minutes, offline after, never without a beat, null unless active',
    () {
      final now = DateTime.utc(2026, 10, 9, 12);
      RoomModel room(String status, {Duration? seenAgo}) => RoomModel(
        id: 'r1',
        propertyId: 'p1',
        roomLabel: 'Room 101',
        status: status,
        lastSeenAt: seenAgo == null
            ? null
            : now.subtract(seenAgo).toIso8601String(),
        createdAt: '2026-09-01T00:00:00Z',
      );
      expect(
        presenceOf(room('ACTIVE', seenAgo: const Duration(minutes: 2)), now),
        Presence.online,
      );
      expect(
        presenceOf(room('ACTIVE', seenAgo: const Duration(minutes: 3)), now),
        Presence.offline,
      );
      expect(presenceOf(room('ACTIVE'), now), Presence.never);
      expect(presenceOf(room('UNPROVISIONED'), now), isNull);
      expect(presenceOf(room('REVOKED', seenAgo: Duration.zero), now), isNull);
    },
  );
}
