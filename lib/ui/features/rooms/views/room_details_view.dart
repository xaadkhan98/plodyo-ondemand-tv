import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import '../room_labels.dart';
import '../widgets/pairing_code_panel.dart';
import '../widgets/room_presence.dart';

/// What is open in place of the action row.
enum _Panel { actions, pairing, revoke, delete }

/// One room: its TV's presence, and pairing, revoking and deleting. Provisioning is offered in every state —
/// it revokes any existing credential first, so it is both first-time setup and how a replaced TV is re-paired.
class RoomDetailsView extends StatefulWidget {
  const RoomDetailsView({
    super.key,
    required this.room,
    this.roomsRepository,
    this.authRepository,
  });

  final RoomModel room;
  final RoomsRepository? roomsRepository;
  final AuthRepository? authRepository;

  @override
  State<RoomDetailsView> createState() => _RoomDetailsViewState();
}

class _RoomDetailsViewState extends State<RoomDetailsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final RoomsRepository _rooms =
      widget.roomsRepository ?? sharedRoomsRepository;
  late RoomModel _room = widget.room;
  _Panel _panel = _Panel.actions;
  ProvisionRoomResponse? _pairing;
  bool _busy = false;
  String? _error;
  DateTime _now = DateTime.now();
  late final Timer _heartbeat;

  @override
  void initState() {
    super.initState();
    // The TV beats every minute, so presence is re-read on the same beat while this is open.
    _heartbeat = Timer.periodic(presenceRefresh, (_) => _refresh());
  }

  @override
  void dispose() {
    _heartbeat.cancel();
    super.dispose();
  }

  /// Re-reads the room: presence, and the status an action has just changed.
  Future<void> _refresh() async {
    try {
      final room = await _rooms.getRoom(
        accessToken: _auth.accessToken,
        roomId: _room.id,
      );
      if (!mounted) return;
      setState(() {
        _room = room;
        _now = DateTime.now();
      });
    } catch (_) {
      // A missed refresh keeps the last reading; the next beat tries again.
    }
  }

  /// Runs one action against the API, then re-reads the room it changed.
  Future<void> _run(String failure, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _panel = _Panel.actions;
        _error = messageOf(e, failure);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Provisioning revokes whatever credential the room had, so its status is stale the moment this returns.
  Future<void> _provision() => _run('Could not get a pairing code.', () async {
    final pairing = await _rooms.provisionRoom(
      accessToken: _auth.accessToken,
      roomId: _room.id,
    );
    if (!mounted) return;
    setState(() {
      _pairing = pairing;
      _panel = _Panel.pairing;
    });
  });

  Future<void> _revoke() => _run('Could not revoke the device.', () async {
    await _rooms.revokeRoom(accessToken: _auth.accessToken, roomId: _room.id);
    if (mounted) setState(() => _panel = _Panel.actions);
  });

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _rooms.deleteRoom(accessToken: _auth.accessToken, roomId: _room.id);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _panel = _Panel.actions;
        _error = messageOf(e, 'Could not delete the room.');
      });
    }
  }

  Future<void> _edit() async {
    setState(() => _error = null);
    final saved = await context.push<RoomModel>('/rooms/edit', extra: _room);
    if (saved != null && mounted) setState(() => _room = saved);
  }

  void _open(_Panel panel) => setState(() {
    _error = null;
    _panel = panel;
  });

  @override
  Widget build(BuildContext context) {
    final room = _room;
    // Back steps out of an open panel first; a code on screen is the first thing to close, since it is single use.
    return PopScope(
      canPop: _panel == _Panel.actions,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _open(_Panel.actions);
      },
      child: ConsolePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvButton(
              label: 'All rooms',
              icon: LucideIcons.arrowLeft,
              variant: TvButtonVariant.quiet,
              size: TvButtonSize.sm,
              onSelect: () => context.pop(),
            ),
            const SizedBox(height: rem),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: rem,
              children: [
                ScreenHeading(room.roomLabel),
                StatusBadge(room.statusLabel, tone: room.statusTone),
              ],
            ),
            const SizedBox(height: 2 * rem),
            TwoColumnGrid(
              children: [
                DetailCard(
                  label: 'Language',
                  value: Row(
                    spacing: 0.625 * rem,
                    children: [
                      LanguageFlag(code: room.defaultLanguage),
                      Flexible(
                        child: Text(
                          languageLabel(
                            room.defaultLanguage,
                            'Follows the property',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DetailCard.text(
                  label: 'Set up',
                  value: room.provisionedAt == null
                      ? 'No device paired yet'
                      : formatDateTime(room.provisionedAt),
                ),
                DetailCard(
                  label: 'Last seen',
                  value: LastSeen(room: room, now: _now),
                ),
                DetailCard.text(
                  label: 'Created',
                  value: formatDateTime(room.createdAt),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 1.5 * rem),
              StatusMessage(tone: StatusTone.error, message: _error!),
            ],
            const SizedBox(height: 2 * rem),
            // Keyed so each panel is a fresh subtree: reused button states would hand the old focus to a new button.
            KeyedSubtree(
              key: ValueKey(_panel),
              child: switch (_panel) {
                _Panel.actions => _actions(room),
                _Panel.pairing => PairingCodePanel(
                  key: ValueKey(_pairing!.pairingCode),
                  pairing: _pairing!,
                  reissuing: _busy,
                  onReissue: _provision,
                  onDone: () => _open(_Panel.actions),
                ),
                _Panel.revoke => _confirm(
                  title: 'Revoke this room’s device?',
                  description:
                      'The TV in ${room.roomLabel} stops serving content on its next call. The room and everything it recorded are kept — only the credential stops working, and a new one can be issued at any time.',
                  confirm: TvButton(
                    label: 'Revoke device',
                    icon: LucideIcons.unplug,
                    variant: TvButtonVariant.danger,
                    autofocus: true,
                    busy: _busy,
                    busyLabel: 'Revoking…',
                    onSelect: _revoke,
                  ),
                ),
                _Panel.delete => _confirm(
                  title: 'Delete this room?',
                  description:
                      '${room.roomLabel} will be removed and its slot returned to the partner’s room limit. This cannot be undone.',
                  cancelLabel: 'Keep it',
                  confirm: TvButton(
                    label: 'Delete room',
                    icon: LucideIcons.trash2,
                    variant: TvButtonVariant.danger,
                    autofocus: true,
                    busy: _busy,
                    busyLabel: 'Deleting…',
                    onSelect: _delete,
                  ),
                ),
              },
            ),
            const SizedBox(height: 2.5 * rem),
          ],
        ),
      ),
    );
  }

  Widget _actions(RoomModel room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: 'Edit room',
              icon: LucideIcons.pencil,
              variant: TvButtonVariant.outline,
              autofocus: true,
              onSelect: _edit,
            ),
            TvButton(
              label: room.isUnprovisioned ? 'Set up TV' : 'Re-pair TV',
              icon: LucideIcons.plugZap,
              busy: _busy,
              busyLabel: 'Getting a code…',
              onSelect: _provision,
            ),
            if (room.canRevoke)
              TvButton(
                label: 'Revoke device',
                icon: LucideIcons.unplug,
                variant: TvButtonVariant.danger,
                onSelect: () => _open(_Panel.revoke),
              ),
            if (room.canDelete)
              TvButton(
                label: 'Delete room',
                icon: LucideIcons.trash2,
                variant: TvButtonVariant.danger,
                onSelect: () => _open(_Panel.delete),
              ),
          ],
        ),
        // A button that always fails is worse than none, so the reason is spelled out where it would have been.
        if (!room.canDelete) ...[
          const SizedBox(height: 1.5 * rem),
          const StatusMessage(
            tone: StatusTone.info,
            message:
                'This room has been set up before, so it keeps the session history a device recorded against it and cannot be deleted. Revoking its device is how it is taken out of service.',
          ),
        ],
      ],
    );
  }

  Widget _confirm({
    required String title,
    required String description,
    required TvButton confirm,
    String cancelLabel = 'Cancel',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title, description: description),
        const SizedBox(height: 1.25 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            confirm,
            TvButton(
              label: cancelLabel,
              variant: TvButtonVariant.outline,
              disabled: _busy,
              onSelect: () => _open(_Panel.actions),
            ),
          ],
        ),
      ],
    );
  }
}
