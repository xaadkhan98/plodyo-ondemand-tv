import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../data/models/room_model.dart';

/// A TV beats every minute, so three missed beats is offline.
const _onlineWindow = Duration(minutes: 3);

/// How often a screen showing presence re-reads it: the TV's own heartbeat.
const presenceRefresh = Duration(minutes: 1);

enum Presence { online, offline, never }

/// Only a paired room has a TV that can be online; null for the rest.
Presence? presenceOf(RoomModel room, DateTime now) {
  if (!room.isActive) return null;
  final seen = room.lastSeenAt == null
      ? null
      : DateTime.tryParse(room.lastSeenAt!);
  if (seen == null) return Presence.never;
  return now.difference(seen) < _onlineWindow
      ? Presence.online
      : Presence.offline;
}

/// A room row's activity: presence for a paired TV, otherwise how far the room got.
class RoomActivity extends StatelessWidget {
  const RoomActivity({super.key, required this.room, required this.now});

  final RoomModel room;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final presence = presenceOf(room, now);
    if (presence == Presence.online) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.5 * rem,
        children: [
          const PresenceDot(online: true),
          Text(
            'Online',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: TvColors.mintInk,
            ),
          ),
        ],
      );
    }
    if (room.lastSeenAt case final seen?) {
      return Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 0.5 * rem,
          children: [
            if (presence != null) const PresenceDot(),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: 'Last seen ${timeAgo(seen, now)} ',
                  children: [
                    TextSpan(
                      text: '(${formatDateTime(seen)})',
                      style: TextStyle(
                        color: TvColors.mutedForeground.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    if (presence == Presence.never) return const Text('Never seen');
    if (room.provisionedAt != null) {
      return Text('Set up ${formatDate(room.provisionedAt)}');
    }
    return Text('Added ${formatDate(room.createdAt)}');
  }
}

/// The room detail's "Last seen" value, with the exact time under it.
class LastSeen extends StatelessWidget {
  const LastSeen({super.key, required this.room, required this.now});

  final RoomModel room;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final presence = presenceOf(room, now);
    final note = TvText.sm.copyWith(
      fontWeight: FontWeight.w400,
      color: TvColors.mutedForeground,
    );
    final seen = room.lastSeenAt;
    if (seen == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Never'),
          if (presence == Presence.never)
            Text(
              'Not since it was paired. Check the TV is on and connected.',
              style: note,
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (presence == Presence.online)
          Row(
            spacing: 0.625 * rem,
            children: [
              const PresenceDot(online: true, live: true),
              Text('Online now', style: TextStyle(color: TvColors.mintInk)),
            ],
          )
        else
          Text(timeAgo(seen, now)),
        Text(
          formatDateTime(seen),
          style: note.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Filled mint for online, a hollow ring for a TV gone quiet. [live] pulses: one per screen, never a list of them.
class PresenceDot extends StatefulWidget {
  const PresenceDot({super.key, this.online = false, this.live = false});

  final bool online;
  final bool live;

  @override
  State<PresenceDot> createState() => _PresenceDotState();
}

class _PresenceDotState extends State<PresenceDot>
    with SingleTickerProviderStateMixin {
  static const double _size = 0.75 * rem;

  // Tailwind's `animate-ping`: grow to twice the size while fading out, once a second.
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _ping.repeat();
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.online ? TvColors.mint : null,
        border: widget.online
            ? null
            : Border.all(
                color: TvColors.mutedForeground.withValues(alpha: 0.5),
                width: 2 * px,
              ),
      ),
    );
    if (!widget.live || MediaQuery.disableAnimationsOf(context)) return dot;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ping,
          builder: (context, _) => Transform.scale(
            scale: 1 + _ping.value,
            child: Opacity(
              opacity: 1 - _ping.value,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TvColors.mint.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
        dot,
      ],
    );
  }
}
