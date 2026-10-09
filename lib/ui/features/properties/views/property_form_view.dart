import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/language_picker.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/picker_list.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

enum _Field {
  name(
    'Property name',
    'Grand Plaza Downtown',
    LucideIcons.landmark,
    KeySets.name,
    200,
  ),
  country('Country (optional)', 'US', LucideIcons.globe, KeySets.name, 100),
  city('City (optional)', 'Austin', LucideIcons.mapPin, KeySets.name, 100),
  timezone(
    'Timezone (optional)',
    'America/Chicago',
    LucideIcons.globe,
    KeySets.timezone,
    100,
  );

  const _Field(
    this.label,
    this.placeholder,
    this.icon,
    this.extraKeys,
    this.maxLength,
  );

  final String label;
  final String placeholder;
  final IconData icon;
  final List<String> extraKeys;

  /// The API's column limit.
  final int maxLength;
}

/// Creates a property, or edits one. Country, city and timezone are free text — a hard-coded timezone list
/// would be wrong the day a venue falls outside it — but language is a closed set the API checks. The owning
/// partner is fixed once a property exists, and only a super admin has more than one to pick from.
class PropertyFormView extends StatefulWidget {
  const PropertyFormView({
    super.key,
    this.property,
    this.propertiesRepository,
    this.partnersRepository,
    this.authRepository,
  });

  /// Absent for a new property.
  final PropertyModel? property;
  final PropertiesRepository? propertiesRepository;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;

  @override
  State<PropertyFormView> createState() => _PropertyFormViewState();
}

class _PropertyFormViewState extends State<PropertyFormView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: _Field.name.maxLength,
    initial: switch (widget.property) {
      final p? => {
        _Field.name: p.name,
        _Field.country: p.country ?? '',
        _Field.city: p.city ?? '',
        _Field.timezone: p.timezone ?? '',
      },
      null => const {},
    },
    onEdit: () => setState(() => _error = null),
  );
  final _keyboard = FocusNode();
  late String? _partnerId =
      widget.property?.partnerId ?? _auth.currentUser?.partnerId;
  late String? _language = widget.property?.defaultLanguage;
  late final bool _needsPartnerPicker =
      widget.property == null && _auth.currentUser?.partnerId == null;
  List<PartnerModel>? _partners;
  String? _partnersError;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_needsPartnerPicker) _loadPartners();
  }

  @override
  void dispose() {
    _entry.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    try {
      final page = await (widget.partnersRepository ?? sharedPartnersRepository)
          .getPartners(
            accessToken: _auth.accessToken,
            status: 'ACTIVE',
            pageSize: pickerPageSize,
          );
      if (mounted) setState(() => _partners = page.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _partnersError = messageOf(e, 'Could not load partners.'));
    }
  }

  Future<void> _submit() async {
    String text(_Field field) => _entry[field].trim();
    // Ordered so the message names the first field that needs fixing.
    final invalid =
        validateRequired(
          text(_Field.name),
          'property name',
          maxLength: _Field.name.maxLength,
        ) ??
        (_partnerId == null
            ? 'Choose which partner this property belongs to.'
            : null) ??
        validateMaxLength(
          text(_Field.country),
          'country',
          _Field.country.maxLength,
        ) ??
        validateMaxLength(text(_Field.city), 'city', _Field.city.maxLength) ??
        validateMaxLength(
          text(_Field.timezone),
          'timezone',
          _Field.timezone.maxLength,
        );
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _saving = true);
    final properties =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    try {
      // Blank values are sent on an edit: an empty string is what clears a field or a language already set.
      final saved = widget.property == null
          ? await properties.createProperty(
              accessToken: _auth.accessToken,
              partnerId: _partnerId!,
              name: text(_Field.name),
              country: text(_Field.country),
              city: text(_Field.city),
              timezone: text(_Field.timezone),
              defaultLanguage: _language,
            )
          : await properties.updateProperty(
              accessToken: _auth.accessToken,
              propertyId: widget.property!.id,
              name: text(_Field.name),
              country: text(_Field.country),
              city: text(_Field.city),
              timezone: text(_Field.timezone),
              defaultLanguage: _language ?? '',
            );
      if (mounted) context.pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not save the property.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.property != null;
    return TextEntryScope(
      controller: _entry,
      onExit: () => context.pop(),
      child: ConsolePage(
        maxWidth: 93.75 * rem,
        child: ListenableBuilder(
          listenable: _entry,
          builder: (context, _) => KeyboardFormLayout(
            alignTop: true,
            keyboardLabel:
                'Entering ${_entry.active.label.replaceAll(' (optional)', '')}',
            keyboard: OnScreenKeyboard(
              controller: _entry,
              extraKeys: _entry.active.extraKeys,
              entryFocusNode: _keyboard,
            ),
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeading(editing ? 'Edit property' : 'Add a property'),
                const SizedBox(height: 0.5 * rem),
                const ScreenSubtitle(
                  'A property is one building or site. Rooms are created under it, and the room limit is shared across every property this partner owns.',
                  maxCh: 60,
                ),
                if (_needsPartnerPicker) ...[
                  const SizedBox(height: 1.75 * rem),
                  PickerList(
                    label: 'Partner',
                    icon: LucideIcons.building2,
                    value: _partnerId,
                    onChanged: (id) => setState(() => _partnerId = id),
                    loading: _partners == null && _partnersError == null,
                    error: _partnersError,
                    disabled: _saving,
                    emptyMessage:
                        'There are no active partners to add a property to yet.',
                    options: [
                      for (final partner in _partners ?? const <PartnerModel>[])
                        PickerOption(
                          id: partner.id,
                          label: partner.name,
                          hint: partner.contactEmail,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 1.5 * rem),
                for (final field in _Field.values) ...[
                  if (field != _Field.name) const SizedBox(height: 0.75 * rem),
                  TvTextField(
                    label: field.label,
                    value: _entry[field],
                    placeholder: field.placeholder,
                    icon: field.icon,
                    autofocus: field == _Field.name,
                    active: _entry.active == field,
                    keyboardFocusNode: _keyboard,
                    onSelect: () => _entry.focus(field),
                  ),
                ],
                const SizedBox(height: 1.5 * rem),
                LanguagePicker(
                  columns: 4,
                  label: 'Default language (optional)',
                  noneLabel: 'Not set',
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
                      label: editing ? 'Save changes' : 'Create property',
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
      ),
    );
  }
}
