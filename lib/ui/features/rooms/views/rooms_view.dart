import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import '../room_labels.dart';
import '../widgets/room_presence.dart';

/// The rooms in the account's scope: one row per TV, and where a partner comes when a TV will not sign in.
/// The list re-reads itself on the TVs' heartbeat, so presence stays current while it is on screen.
class RoomsView extends StatefulWidget {
  const RoomsView({
    super.key,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
  });

  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;

  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  static const _filters = [
    Choice(value: 'all', label: 'All'),
    Choice(value: 'UNPROVISIONED', label: 'Not set up'),
    Choice(value: 'ACTIVE', label: 'Active'),
    Choice(value: 'REVOKED', label: 'Revoked'),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final RoomsRepository _rooms =
      widget.roomsRepository ?? sharedRoomsRepository;

  // A property admin sees one property's rooms, so a property filter would be a control with one option.
  late final bool _spansProperties = _auth.currentUser?.propertyId == null;
  List<PropertyModel> _properties = const [];
  String _propertyId = 'all';
  DateTime _now = DateTime.now();
  Timer? _heartbeat;

  late final _list = PagedList<RoomModel, String>(
    filter: 'all',
    fetch: (status, page) => _rooms.getRooms(
      accessToken: _auth.accessToken,
      status: status == 'all' ? null : status,
      propertyId: _propertyId == 'all' ? null : _propertyId,
      page: page,
      pageSize: defaultPageSize,
    ),
  )..load();

  @override
  void initState() {
    super.initState();
    if (_spansProperties) _loadProperties();
    // "5 minutes ago" and the online window keep moving between fetches.
    _heartbeat = Timer.periodic(presenceRefresh, (_) {
      setState(() => _now = DateTime.now());
      _list.load(quiet: true);
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _list.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final page =
          await (widget.propertiesRepository ?? sharedPropertiesRepository)
              .getProperties(
                accessToken: _auth.accessToken,
                pageSize: pickerPageSize,
              );
      if (mounted) setState(() => _properties = page.data);
    } catch (_) {
      // Names are a convenience here: without them the rows still show and the property filter hides.
    }
  }

  void _changeProperty(String id) {
    setState(() => _propertyId = id);
    _list.setFilter(_list.filter);
  }

  /// Opens a screen that may change rooms, then reloads quietly on the way back.
  Future<void> _visit(String path, {Object? extra}) async {
    await context.push(
      path,
      extra: extra ?? (_propertyId == 'all' ? null : _propertyId),
    );
    if (mounted) _list.load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final names = {
      for (final property in _properties) property.id: property.name,
    };
    return ConsolePage(
      maxWidth: 93.75 * rem,
      child: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => AdminListLayout<RoomModel, String>(
          list: _list,
          icon: LucideIcons.doorOpen,
          title: 'Rooms',
          description:
              'One row per TV. A room counts against the partner’s room limit from the moment it is created, whether or not a device has been paired.',
          filters: _filters,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.75 * rem,
            children: [
              TvButton(
                label: 'Add room',
                icon: LucideIcons.plus,
                size: TvButtonSize.md,
                autofocus: true,
                onSelect: () => _visit('/rooms/add'),
              ),
              TvButton(
                label: 'Add many',
                icon: LucideIcons.rows3,
                variant: TvButtonVariant.outline,
                size: TvButtonSize.md,
                onSelect: () => _visit('/rooms/add-many'),
              ),
            ],
          ),
          secondaryFilter: _spansProperties && _properties.isNotEmpty
              ? ChoiceGroup<String>(
                  value: _propertyId,
                  layout: ChoiceLayout.chips,
                  onChanged: _changeProperty,
                  options: [
                    const Choice(value: 'all', label: 'All properties'),
                    for (final property in _properties)
                      Choice(value: property.id, label: property.name),
                  ],
                )
              : null,
          emptyMessage: _list.filter == 'all'
              ? 'No rooms yet. Add one to get a TV signed in.'
              : 'No rooms are ${roomStatusLabels[_list.filter]!.toLowerCase()}.',
          rowBuilder: (room) => ListRow(
            icon: LucideIcons.doorOpen,
            title: room.roomLabel,
            badges: [StatusBadge(room.statusLabel, tone: room.statusTone)],
            meta: [
              if (_spansProperties && names[room.propertyId] != null)
                MetaItem(names[room.propertyId]!, icon: LucideIcons.landmark),
              if (room.defaultLanguage case final code? when code.isNotEmpty)
                MetaItem(
                  languageLabel(code),
                  leading: LanguageFlag(
                    code: code,
                    width: 1.5 * rem,
                    height: rem,
                    fallback: const Icon(LucideIcons.languages, size: rem),
                  ),
                ),
              RoomActivity(room: room, now: _now),
            ],
            onSelect: () => _visit('/rooms/details', extra: room),
          ),
        ),
      ),
    );
  }
}
