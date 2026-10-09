import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/room_model.dart';

/// The pairing code and the clock that says whether it is still worth typing. A code lives fifteen minutes
/// and works once; without the countdown, an installer types eight characters only to read "invalid or expired".
/// Key it by code, so a reissued code starts its own countdown.
class PairingCodePanel extends StatefulWidget {
  const PairingCodePanel({
    super.key,
    required this.pairing,
    required this.reissuing,
    required this.onReissue,
    required this.onDone,
  });

  final ProvisionRoomResponse pairing;
  final bool reissuing;
  final VoidCallback onReissue;
  final VoidCallback onDone;

  @override
  State<PairingCodePanel> createState() => _PairingCodePanelState();
}

class _PairingCodePanelState extends State<PairingCodePanel> {
  late int _remaining = _secondsLeft();
  late final Timer _tick;

  /// Recomputed from the timestamp rather than decremented, so a throttled clock shows the truth.
  int _secondsLeft() {
    final expiresAt = DateTime.tryParse(widget.pairing.expiresAt);
    if (expiresAt == null) return 0;
    final left = expiresAt.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _remaining = _secondsLeft()),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == 0;
    final tabular = const [FontFeature.tabularFigures()];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          'Pair the TV in this room',
          description:
              'Open Plodyo on the set in this room and type this code. It works once, and any device this room had before has already stopped working.',
        ),
        const SizedBox(height: 1.25 * rem),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 1.5 * rem,
          runSpacing: rem,
          children: [
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2.5 * rem,
                  vertical: 1.5 * rem,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5 * rem),
                  border: Border.all(color: TvColors.primary, width: 2 * px),
                ),
                child: Text(
                  widget.pairing.pairingCode,
                  style: TvText.x3l.copyWith(
                    fontFamily: TvText.fredoka,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2 * TvText.x3l.fontSize!,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired ? 'Expired' : 'Expires in',
                  style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                ),
                Text(
                  expired
                      ? '—'
                      : '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
                  style: TvText.xl.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (expired) ...[
          const SizedBox(height: 1.25 * rem),
          const StatusMessage(
            tone: StatusTone.warning,
            message:
                'This code has expired. Get a new one — the room is unchanged, and the old code cannot be revived.',
          ),
        ],
        const SizedBox(height: 1.5 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: 'New code',
              icon: LucideIcons.refreshCw,
              variant: expired
                  ? TvButtonVariant.primary
                  : TvButtonVariant.outline,
              autofocus: true,
              busy: widget.reissuing,
              busyLabel: 'Getting a code…',
              onSelect: widget.onReissue,
            ),
            TvButton(
              label: 'Done',
              icon: LucideIcons.tv,
              variant: expired
                  ? TvButtonVariant.outline
                  : TvButtonVariant.primary,
              disabled: widget.reissuing,
              onSelect: widget.onDone,
            ),
          ],
        ),
      ],
    );
  }
}
