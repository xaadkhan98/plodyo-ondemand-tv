import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/number_stepper.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../partner_labels.dart';

enum _Field {
  name('Venue name', 'Grand Hotel Group', LucideIcons.building2, KeySets.name),
  contactEmail(
    'Contact email',
    'ops@grandhotelgroup.com',
    LucideIcons.mail,
    KeySets.email,
  ),
  contactName(
    'Contact name (optional)',
    'Jordan Lee',
    LucideIcons.userRound,
    KeySets.name,
  ),
  phone('Phone (optional)', '+1-555-0100', LucideIcons.phone, KeySets.phone),
  contractReference(
    'Contract reference (optional)',
    'CTR-2026-0142',
    LucideIcons.fileText,
    KeySets.name,
  );

  const _Field(this.label, this.placeholder, this.icon, this.extraKeys);

  final String label;
  final String placeholder;
  final IconData icon;
  final List<String> extraKeys;
}

/// The API's column limits for a partner.
abstract final class _Limits {
  static const int name = 200;
  static const int contactName = 200;
  static const int phone = 50;
  static const int contractReference = 100;
}

/// Onboards a partner by hand, or edits one's contact details. Creating is for what the public form cannot
/// serve — a chain arriving with a contract — and is active at once, with no invite sent. Pops the saved record.
class PartnerFormView extends StatefulWidget {
  const PartnerFormView({
    super.key,
    this.partner,
    this.partnersRepository,
    this.authRepository,
  });

  /// Absent for onboarding a new partner.
  final PartnerModel? partner;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;

  @override
  State<PartnerFormView> createState() => _PartnerFormViewState();
}

class _PartnerFormViewState extends State<PartnerFormView> {
  static const _types = [
    Choice(
      value: 'CHAIN',
      label: 'Chain',
      description: 'Several venues under one contract. Cannot self-register.',
    ),
    Choice(
      value: 'INDEPENDENT',
      label: 'Independent',
      description: 'A single hotel or guest house.',
    ),
    Choice(
      value: 'HOST',
      label: 'Host',
      description: 'A short-let host with a handful of rooms.',
    ),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;

  // Contract terms are super admin only: the API refuses a partner admin for so much as sending the keys.
  late final bool _canSetContract = _auth.currentUser?.isSuperAdmin ?? false;
  late final List<_Field> _fields = [
    for (final field in _Field.values)
      if (field != _Field.contractReference || _canSetContract) field,
  ];
  late final _entry = TextEntryController<_Field>(
    _fields,
    maxLength: _Limits.name,
    initial: switch (widget.partner) {
      final p? => {
        _Field.name: p.name,
        _Field.contactEmail: p.contactEmail,
        _Field.contactName: p.contactName ?? '',
        _Field.phone: p.phone ?? '',
        _Field.contractReference: p.contractReference ?? '',
      },
      null => const {},
    },
    onEdit: () => setState(() => _error = null),
  );
  final _keyboard = FocusNode();
  late String _partnerType = widget.partner?.partnerType ?? 'CHAIN';
  late int _roomLimit = widget.partner?.roomLimit ?? 0;
  late String _contentTier = widget.partner?.contentTier ?? 'TIER_1';
  bool _saving = false;
  String? _error;

  bool get _creating => widget.partner == null;

  @override
  void dispose() {
    _entry.dispose();
    _keyboard.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String text(_Field field) =>
        _fields.contains(field) ? _entry[field].trim() : '';
    // Ordered so the message names the first field that needs fixing.
    final invalid =
        validateRequired(
          text(_Field.name),
          'venue name',
          maxLength: _Limits.name,
        ) ??
        validateEmail(text(_Field.contactEmail), label: 'contact email') ??
        validateMaxLength(
          text(_Field.contactName),
          'contact name',
          _Limits.contactName,
        ) ??
        validateMaxLength(text(_Field.phone), 'phone number', _Limits.phone) ??
        validateMaxLength(
          text(_Field.contractReference),
          'contract reference',
          _Limits.contractReference,
        );
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _saving = true);
    final partners = widget.partnersRepository ?? sharedPartnersRepository;
    try {
      final saved = _creating
          ? await partners.createPartner(
              accessToken: _auth.accessToken,
              name: text(_Field.name),
              partnerType: _partnerType,
              contactEmail: text(_Field.contactEmail),
              contactName: text(_Field.contactName),
              phone: text(_Field.phone),
              contractReference: text(_Field.contractReference),
              roomLimit: _roomLimit,
              contentTier: _canSetContract ? _contentTier : null,
            )
          // Blank contact fields are sent: an empty value is the only way to clear a mistake.
          : await partners.updatePartner(
              accessToken: _auth.accessToken,
              partnerId: widget.partner!.id,
              name: text(_Field.name),
              contactEmail: text(_Field.contactEmail),
              contactName: text(_Field.contactName),
              phone: text(_Field.phone),
              contractReference: _canSetContract
                  ? text(_Field.contractReference)
                  : null,
              contentTier: _canSetContract ? _contentTier : null,
            );
      if (mounted) context.pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not save the partner.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = TvText.sm.copyWith(color: TvColors.mutedForeground);
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
                ScreenHeading(_creating ? 'Add a partner' : 'Edit partner'),
                const SizedBox(height: 0.5 * rem),
                ScreenSubtitle(
                  _creating
                      ? 'Onboards a venue that is not going through the public registration form. It is active straight away, and no invite is sent — invite the first partner admin separately.'
                      : 'Contact details only. Status and room limit have their own actions.',
                  maxCh: 60,
                ),
                if (_creating) ...[
                  const SizedBox(height: 1.75 * rem),
                  ChoiceGroup<String>(
                    label: 'Business type',
                    value: _partnerType,
                    options: _types,
                    disabled: _saving,
                    onChanged: (type) => setState(() => _partnerType = type),
                  ),
                ],
                const SizedBox(height: 1.5 * rem),
                for (final field in _fields) ...[
                  if (field != _fields.first)
                    const SizedBox(height: 0.75 * rem),
                  TvTextField(
                    label: field.label,
                    value: _entry[field],
                    placeholder: field.placeholder,
                    icon: field.icon,
                    autofocus: field == _fields.first,
                    active: _entry.active == field,
                    keyboardFocusNode: _keyboard,
                    onSelect: () => _entry.focus(field),
                  ),
                ],
                if (_creating) ...[
                  const SizedBox(height: 1.75 * rem),
                  NumberStepper(
                    label: 'Room limit',
                    value: _roomLimit,
                    unit: 'rooms',
                    disabled: _saving,
                    onChanged: (value) => setState(() => _roomLimit = value),
                  ),
                  const SizedBox(height: 0.5 * rem),
                  Text(
                    'At 0 no room can be created, so a TV cannot be signed in. It can be raised later from the partner’s own screen.',
                    style: note,
                  ),
                ],
                if (_canSetContract) ...[
                  const SizedBox(height: 1.75 * rem),
                  ChoiceGroup<String>(
                    label: 'Content tier',
                    value: _contentTier,
                    options: contentTierChoices,
                    disabled: _saving,
                    onChanged: (tier) => setState(() => _contentTier = tier),
                  ),
                  const SizedBox(height: 0.5 * rem),
                  Text(
                    'How much of the library this partner’s rooms may browse. Lowering it hides content the venue can currently play.',
                    style: note,
                  ),
                ],
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
                      label: _creating ? 'Create partner' : 'Save changes',
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
