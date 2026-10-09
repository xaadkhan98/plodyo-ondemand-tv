import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/language_picker.dart';
import '../../../../core/widgets/number_stepper.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import '../widgets/property_picker.dart';
import 'room_form_view.dart' show roomLabelMaxLength;

enum _Field { prefix }

/// The API's largest batch.
const _maxBatch = 500;

/// Labels that appear twice in a batch, in the order they first repeat; trimmed and case-insensitive, as sent.
/// The API refuses the whole batch for one, and only the person who built the list knows which range to fix.
List<String> duplicateLabels(List<String> labels) {
  final seen = <String>{};
  final repeated = <String>{};
  for (final label in labels) {
    final key = label.trim().toLowerCase();
    if (key.isEmpty) continue;
    if (!seen.add(key)) repeated.add(label.trim());
  }
  return repeated.toList();
}

/// Adds a floor of rooms in one all-or-nothing batch. The API takes a list, not a range: real numbering skips
/// floors and has lettered suites, so ranges are built here into an ordinary list. Pops true once created.
class AddManyRoomsView extends StatefulWidget {
  const AddManyRoomsView({
    super.key,
    this.propertyId,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
  });

  /// Pre-selects the property, e.g. the one the room list was filtered to.
  final String? propertyId;
  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;

  @override
  State<AddManyRoomsView> createState() => _AddManyRoomsViewState();
}

class _AddManyRoomsViewState extends State<AddManyRoomsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: roomLabelMaxLength,
    onEdit: () => setState(() => _error = null),
  );
  late String? _propertyId = widget.propertyId ?? _auth.currentUser?.propertyId;
  String? _language;
  final List<String> _labels = [];
  int _from = 101;
  int _to = 110;
  bool _saving = false;
  String? _error;

  // A property admin owns exactly one property, so there is nothing to choose.
  bool get _needsPicker => _auth.currentUser?.propertyId == null;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _addRange() {
    if (_to < _from) {
      setState(
        () => _error = 'The last number has to be at or above the first.',
      );
      return;
    }
    // The prefix keeps its own trailing space — "Room " is what makes "Room 101" — so only the ends are trimmed.
    final added = [
      for (var n = _from; n <= _to; n++) '${_entry.value}$n'.trim(),
    ];
    final total = _labels.length + added.length;
    setState(() {
      if (total > _maxBatch) {
        _error =
            'A batch holds at most $_maxBatch rooms. That range would make $total.';
      } else {
        _error = null;
        _labels.addAll(added);
      }
    });
  }

  Future<void> _submit() async {
    final repeated = duplicateLabels(_labels);
    final invalid =
        (_labels.isEmpty ? 'Add at least one room.' : null) ??
        (_propertyId == null
            ? 'Choose which property these rooms are in.'
            : null) ??
        (repeated.isNotEmpty
            ? 'These are in the list twice: ${repeated.join(', ')}'
            : null);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _saving = true);
    try {
      await (widget.roomsRepository ?? sharedRoomsRepository).createRoomsBulk(
        accessToken: _auth.accessToken,
        propertyId: _propertyId!,
        defaultLanguage: _language,
        rooms: [
          for (final label in _labels) {'room_label': label.trim()},
        ],
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not add the rooms.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _labels.length;
    return TextEntryScope(
      controller: _entry,
      onExit: () => context.pop(),
      child: ConsolePage(
        maxWidth: 93.75 * rem,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4 * rem,
          children: [
            Expanded(child: _form(count)),
            _staging(count),
          ],
        ),
      ),
    );
  }

  Widget _form(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeading('Add many rooms'),
        const SizedBox(height: 0.5 * rem),
        const ScreenSubtitle(
          'Either every room is created or none are, so a failed attempt leaves nothing to tidy up. No pairing codes are issued here — a code lasts fifteen minutes, so each TV is paired from its own room screen when someone is standing at it.',
          maxCh: 60,
        ),
        if (_needsPicker) ...[
          const SizedBox(height: 1.75 * rem),
          PropertyPicker(
            value: _propertyId,
            disabled: _saving,
            emptyMessage: 'There are no active properties to add rooms to yet.',
            propertiesRepository: widget.propertiesRepository,
            authRepository: _auth,
            onChanged: (id) => setState(() => _propertyId = id),
          ),
        ],
        const SizedBox(height: 1.75 * rem),
        const SectionHeading(
          'Build a range',
          description:
              'Add one range per floor or wing. Numbering that skips or restarts is why this is several ranges rather than one.',
        ),
        const SizedBox(height: rem),
        ListenableBuilder(
          listenable: _entry,
          builder: (context, _) => TvTextField(
            label: 'Prefix (optional)',
            value: _entry.value,
            placeholder: 'Room ',
            icon: LucideIcons.doorOpen,
            active: true,
            autofocus: true,
            onSelect: () => _entry.focus(_Field.prefix),
          ),
        ),
        const SizedBox(height: rem),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 2 * rem,
          runSpacing: rem,
          children: [
            NumberStepper(
              label: 'First number',
              value: _from,
              disabled: _saving,
              onChanged: (value) => setState(() => _from = value),
            ),
            NumberStepper(
              label: 'Last number',
              value: _to,
              disabled: _saving,
              onChanged: (value) => setState(() => _to = value),
            ),
          ],
        ),
        const SizedBox(height: 1.25 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: 'Add this range',
              icon: LucideIcons.plus,
              variant: TvButtonVariant.outline,
              disabled: _saving,
              onSelect: _addRange,
            ),
            if (count > 0)
              TvButton(
                label: 'Clear the list',
                icon: LucideIcons.trash2,
                variant: TvButtonVariant.quiet,
                disabled: _saving,
                onSelect: () => setState(() {
                  _error = null;
                  _labels.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 1.75 * rem),
        LanguagePicker(
          columns: 4,
          label: 'Language for every room in this batch (optional)',
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
              label: count == 0
                  ? 'Add rooms'
                  : 'Add $count ${count == 1 ? 'room' : 'rooms'}',
              icon: LucideIcons.check,
              busy: _saving,
              busyLabel: 'Adding…',
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
    );
  }

  /// The batch as it stands, above the keyboard that types the prefix.
  Widget _staging(int count) {
    final note = TvText.sm.copyWith(color: TvColors.mutedForeground);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count == 0 ? 'Nothing in the list yet' : '$count of $_maxBatch rooms',
          style: note.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 0.75 * rem),
        Container(
          width: 24 * rem,
          constraints: const BoxConstraints(maxHeight: 22 * rem),
          padding: const EdgeInsets.all(rem),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(rem),
            border: Border.all(color: TvColors.border, width: 2 * px),
          ),
          child: count == 0
              ? Text(
                  'Build a range and it appears here before anything is sent.',
                  style: note,
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: count,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 0.375 * rem),
                  itemBuilder: (_, index) => Text(
                    _labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.sm.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
        ),
        const SizedBox(height: rem),
        OnScreenKeyboard(controller: _entry, extraKeys: KeySets.name),
      ],
    );
  }
}
