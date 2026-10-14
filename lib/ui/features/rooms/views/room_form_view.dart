import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/language_picker.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import '../widgets/property_picker.dart';

enum _Field { roomLabel }

/// The API's limit on a room name.
const roomLabelMaxLength = 100;

/// Creates a room under a property, or renames one; the API does not move rooms between properties.
/// Creating can fail for a reason the form cannot see — the room limit is counted server-side — so the
/// API's message is shown as it arrives. Pops the saved room.
class RoomFormView extends StatefulWidget {
  const RoomFormView({
    super.key,
    this.room,
    this.propertyId,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
  });

  /// Absent for a new room.
  final RoomModel? room;

  /// Pre-selects the property, e.g. the one the room list was filtered to.
  final String? propertyId;
  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;

  @override
  State<RoomFormView> createState() => _RoomFormViewState();
}

class _RoomFormViewState extends State<RoomFormView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: roomLabelMaxLength,
    initial: {
      if (widget.room case final room?) _Field.roomLabel: room.roomLabel,
    },
    onEdit: () => setState(() => _error = null),
  );
  final _keyboard = FocusNode();
  late String? _propertyId =
      widget.room?.propertyId ??
      widget.propertyId ??
      _auth.currentUser?.propertyId;
  late String? _language = widget.room?.defaultLanguage;
  bool _saving = false;
  String? _error;

  // A property admin owns exactly one property, so there is nothing to choose.
  bool get _needsPicker =>
      widget.room == null && _auth.currentUser?.propertyId == null;

  @override
  void dispose() {
    _entry.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _entry.value.trim();
    final invalid =
        validateRequired(label, 'room name', maxLength: roomLabelMaxLength) ??
        (_propertyId == null ? 'Choose which property this room is in.' : null);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _saving = true);
    final rooms = widget.roomsRepository ?? sharedRoomsRepository;
    try {
      // An empty language drops an override already set.
      final saved = widget.room == null
          ? await rooms.createRoom(
              accessToken: _auth.accessToken,
              propertyId: _propertyId!,
              roomLabel: label,
              defaultLanguage: _language,
            )
          : await rooms.updateRoom(
              accessToken: _auth.accessToken,
              roomId: widget.room!.id,
              roomLabel: label,
              defaultLanguage: _language ?? '',
            );
      if (mounted) context.pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not save the room.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.room != null;
    return TextEntryScope(
      controller: _entry,
      onExit: () => context.pop(),
      child: ConsolePage(
        maxWidth: 93.75 * rem,
        child: KeyboardFormLayout(
          alignTop: true,
          keyboardLabel: 'Entering Room name',
          keyboard: OnScreenKeyboard(
            controller: _entry,
            extraKeys: KeySets.name,
            entryFocusNode: _keyboard,
          ),
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeading(editing ? 'Edit room' : 'Add a room'),
              const SizedBox(height: 0.5 * rem),
              const ScreenSubtitle(
                'A room is one TV. It stays unprovisioned until a device is paired with it, and counts against the partner’s room limit either way.',
                maxCh: 60,
              ),
              if (_needsPicker) ...[
                const SizedBox(height: 1.75 * rem),
                PropertyPicker(
                  value: _propertyId,
                  disabled: _saving,
                  emptyMessage:
                      'There are no active properties to add a room to yet.',
                  propertiesRepository: widget.propertiesRepository,
                  authRepository: _auth,
                  onChanged: (id) => setState(() => _propertyId = id),
                ),
              ],
              const SizedBox(height: 1.5 * rem),
              ListenableBuilder(
                listenable: _entry,
                builder: (context, _) => TvTextField(
                  label: 'Room name',
                  value: _entry.value,
                  placeholder: 'Room 214',
                  icon: LucideIcons.doorOpen,
                  active: true,
                  autofocus: true,
                  keyboardFocusNode: _keyboard,
                  onSelect: () => _entry.focus(_Field.roomLabel),
                ),
              ),
              const SizedBox(height: 1.5 * rem),
              LanguagePicker(
                columns: 4,
                label: 'Language override (optional)',
                noneLabel: 'Follows the property',
                value: _language,
                disabled: _saving,
                onChanged: (code) => setState(() {
                  _error = null;
                  _language = code;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 1.25 * rem),
                StatusMessage(tone: StatusTone.error, message: _error!),
              ],
              const SizedBox(height: 1.75 * rem),
              Wrap(
                spacing: rem,
                runSpacing: rem,
                children: [
                  TvButton(
                    label: editing ? 'Save changes' : 'Create room',
                    icon: LucideIcons.check,
                    busy: _saving,
                    busyLabel: 'Saving…',
                    onSelect: _submit,
                  ),
                  TvButton(
                    label: 'Cancel',
                    icon: LucideIcons.arrowLeft,
                    variant: TvButtonVariant.outline,
                    disabled: _saving,
                    onSelect: () => context.pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
