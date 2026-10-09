import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/picker_list.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/invites_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

enum _Field { email }

/// Issues an invite. Who is signed in shapes the form: a partner admin invites only into its own partner, so
/// the partner picker is skipped, and only a super admin may invite another partner admin. Pickers offer
/// ACTIVE records only, the API's own condition, so nothing refusable is shown. Pops true once sent.
class InviteSomeoneView extends StatefulWidget {
  const InviteSomeoneView({
    super.key,
    this.invitesRepository,
    this.partnersRepository,
    this.propertiesRepository,
    this.authRepository,
  });

  final InvitesRepository? invitesRepository;
  final PartnersRepository? partnersRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;

  @override
  State<InviteSomeoneView> createState() => _InviteSomeoneViewState();
}

class _InviteSomeoneViewState extends State<InviteSomeoneView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    onEdit: () => setState(() => _error = null),
  );

  // Only a super admin may invite another partner admin.
  late final List<String> _roles = (_auth.currentUser?.isSuperAdmin ?? false)
      ? const ['PARTNER_ADMIN', 'PROPERTY_ADMIN']
      : const ['PROPERTY_ADMIN'];
  late String _role = _roles.first;
  late String? _partnerId = _auth.currentUser?.partnerId;
  String? _propertyId;
  bool _sending = false;
  String? _error;

  // A super admin has no partner of its own, so it picks one.
  late final bool _needsPartnerPicker = _auth.currentUser?.partnerId == null;
  List<PartnerModel>? _partners;
  String? _partnersError;
  List<PropertyModel>? _properties;
  String? _propertiesError;

  bool get _needsProperty => _role == 'PROPERTY_ADMIN';

  @override
  void initState() {
    super.initState();
    if (_needsPartnerPicker) _loadPartners();
    _loadProperties();
  }

  @override
  void dispose() {
    _entry.dispose();
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
      if (mounted) {
        setState(
          () => _partnersError = messageOf(e, 'Could not load partners.'),
        );
      }
    }
  }

  /// The chosen partner's active properties; only a property-admin invite needs them.
  Future<void> _loadProperties() async {
    final partnerId = _partnerId;
    if (!_needsProperty || partnerId == null) return;
    try {
      final page =
          await (widget.propertiesRepository ?? sharedPropertiesRepository)
              .getProperties(
                accessToken: _auth.accessToken,
                partnerId: partnerId,
                status: 'ACTIVE',
                pageSize: pickerPageSize,
              );
      // The partner may have changed while this was in flight.
      if (mounted && partnerId == _partnerId) {
        setState(() => _properties = page.data);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _propertiesError = messageOf(e, 'Could not load properties.'),
        );
      }
    }
  }

  /// A role or partner change invalidates the property list and any choice from it.
  void _clearProperties() {
    _propertyId = null;
    _properties = null;
    _propertiesError = null;
  }

  void _changeRole(String role) {
    setState(() {
      _role = role;
      _clearProperties();
    });
    _loadProperties();
  }

  void _changePartner(String id) {
    setState(() {
      _partnerId = id;
      _clearProperties();
    });
    _loadProperties();
  }

  Future<void> _submit() async {
    final invalid =
        validateEmail(_entry.value, label: 'email address to invite') ??
        (_partnerId == null
            ? 'Choose which partner this invite is for.'
            : null) ??
        (_needsProperty && _propertyId == null
            ? 'Choose which property this person will administer.'
            : null);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() => _sending = true);
    try {
      await (widget.invitesRepository ?? sharedInvitesRepository).createInvite(
        accessToken: _auth.accessToken,
        email: _entry.value.trim(),
        role: _role,
        partnerId: _partnerId!,
        propertyId: _needsProperty ? _propertyId : null,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not send the invite.'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextEntryScope(
      controller: _entry,
      onExit: () => context.pop(),
      child: ConsolePage(
        maxWidth: 93.75 * rem,
        child: KeyboardFormLayout(
          alignTop: true,
          keyboardLabel: 'Entering email address',
          keyboard: OnScreenKeyboard(
            controller: _entry,
            extraKeys: KeySets.email,
          ),
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeading('Invite someone'),
              const SizedBox(height: 0.5 * rem),
              const ScreenSubtitle(
                'They will get an email with a link to choose a password. The link expires after seven days.',
                maxCh: 60,
              ),
              const SizedBox(height: 1.75 * rem),
              ListenableBuilder(
                listenable: _entry,
                builder: (context, _) => TvTextField(
                  label: 'Email address',
                  value: _entry.value,
                  placeholder: 'colleague@venue.com',
                  icon: LucideIcons.mail,
                  active: true,
                  autofocus: true,
                  onSelect: () => _entry.focus(_Field.email),
                ),
              ),
              if (_roles.length > 1) ...[
                const SizedBox(height: 1.5 * rem),
                ChoiceGroup<String>(
                  label: 'Role',
                  value: _role,
                  disabled: _sending,
                  onChanged: _changeRole,
                  options: [
                    for (final role in _roles)
                      Choice(
                        value: role,
                        label: roleLabel(role),
                        description: role == 'PARTNER_ADMIN'
                            ? 'Administers the partner and every property under it.'
                            : 'Administers one property only.',
                      ),
                  ],
                ),
              ],
              if (_needsPartnerPicker) ...[
                const SizedBox(height: 1.5 * rem),
                PickerList(
                  label: 'Partner',
                  icon: LucideIcons.building2,
                  value: _partnerId,
                  onChanged: _changePartner,
                  loading: _partners == null && _partnersError == null,
                  error: _partnersError,
                  disabled: _sending,
                  emptyMessage:
                      'There are no active partners to invite into yet.',
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
              if (_needsProperty) ...[
                const SizedBox(height: 1.5 * rem),
                PickerList(
                  label: 'Property',
                  icon: LucideIcons.landmark,
                  value: _propertyId,
                  onChanged: (id) => setState(() => _propertyId = id),
                  loading:
                      _partnerId != null &&
                      _properties == null &&
                      _propertiesError == null,
                  error: _propertiesError,
                  disabled: _sending,
                  emptyMessage: _partnerId == null
                      ? 'Choose a partner first.'
                      : 'This partner has no active properties yet. Add one before inviting a property admin.',
                  options: [
                    for (final property
                        in _properties ?? const <PropertyModel>[])
                      PickerOption(
                        id: property.id,
                        label: property.name,
                        hint: [
                          property.city,
                          property.country,
                        ].whereType<String>().join(', '),
                      ),
                  ],
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
                    label: 'Send invite',
                    icon: LucideIcons.send,
                    busy: _sending,
                    busyLabel: 'Sending…',
                    onSelect: _submit,
                  ),
                  TvButton(
                    label: 'Cancel',
                    icon: LucideIcons.arrowLeft,
                    variant: TvButtonVariant.outline,
                    disabled: _sending,
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
