import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/person_model.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/people_repository.dart';
import '../person_labels.dart';

/// The decision open in place of the action row, if any.
enum _Draft { none, rename, disable, enable }

/// The API's limit on a display name.
const _fullNameMaxLength = 200;

/// One account: who it is, the scopes it holds within the caller's own, and renaming or disabling it.
/// Disable is withheld on the caller's own account: locking yourself out of the only console that could
/// undo it is the mistake this screen can prevent.
class PersonDetailsView extends StatefulWidget {
  const PersonDetailsView({
    super.key,
    required this.person,
    this.peopleRepository,
    this.authRepository,
  });

  final PersonModel person;
  final PeopleRepository? peopleRepository;
  final AuthRepository? authRepository;

  @override
  State<PersonDetailsView> createState() => _PersonDetailsViewState();
}

class _PersonDetailsViewState extends State<PersonDetailsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PeopleRepository _people =
      widget.peopleRepository ?? sharedPeopleRepository;
  late PersonModel _person = widget.person;
  _Draft _draft = _Draft.none;
  bool _busy = false;
  String? _error;

  void _open(_Draft draft) => setState(() {
    _error = null;
    _draft = draft;
  });

  /// Runs one action against the API and shows the account it returns.
  Future<void> _run(
    Future<PersonModel> Function(String token, String id) action,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action(_auth.accessToken, _person.id);
      if (!mounted) return;
      setState(() {
        _person = updated;
        _draft = _Draft.none;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not complete that action.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final actor = _auth.currentUser;
    final isSelf = person.id == actor?.userId;
    final canEdit = actor?.canAdminister ?? false;

    // Back closes an open draft first. The rename draft handles Back itself, deleting typed text first.
    return PopScope(
      canPop: _draft == _Draft.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _draft != _Draft.rename) _open(_Draft.none);
      },
      child: ConsolePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvButton(
              label: 'All people',
              icon: LucideIcons.arrowLeft,
              variant: TvButtonVariant.quiet,
              size: TvButtonSize.sm,
              // With no action to land on, first focus comes here.
              autofocus: !canEdit,
              onSelect: () => context.pop(),
            ),
            const SizedBox(height: rem),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: rem,
              runSpacing: 0.5 * rem,
              children: [
                ScreenHeading(
                  person.fullName.isNotEmpty ? person.fullName : person.email,
                ),
                StatusBadge(person.statusLabel, tone: person.statusTone),
                if (isSelf) const StatusBadge('You'),
              ],
            ),
            const SizedBox(height: 2 * rem),
            TwoColumnGrid(
              children: [
                DetailCard.text(label: 'Email', value: person.email),
                DetailCard.text(
                  label: 'Name',
                  value: person.fullName.isNotEmpty
                      ? person.fullName
                      : 'Not set',
                ),
                DetailCard.text(
                  label: 'Last signed in',
                  value: person.lastLoginAt == null
                      ? 'Never'
                      : formatDateTime(person.lastLoginAt),
                ),
                DetailCard.text(
                  label: 'Created',
                  value: formatDateTime(person.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 2.5 * rem),
            const SectionHeading(
              'Access',
              description:
                  'Only the scopes inside your own are listed. This account may hold others elsewhere that you cannot see.',
            ),
            const SizedBox(height: 1.25 * rem),
            if (person.memberships.isEmpty)
              const StatusMessage(
                tone: StatusTone.info,
                message: 'No access within your scope.',
              )
            else
              TwoColumnGrid(
                children: [
                  for (final m in person.memberships)
                    DetailCard.text(
                      label: roleLabel(m.role),
                      value: describeScope(m.partnerId, m.propertyId),
                    ),
                ],
              ),
            if (person.isDisabled) ...[
              const SizedBox(height: 1.5 * rem),
              const StatusMessage(
                tone: StatusTone.warning,
                message:
                    'This account cannot sign in. Every session it held was ended when it was disabled.',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 1.5 * rem),
              StatusMessage(tone: StatusTone.error, message: _error!),
            ],
            const SizedBox(height: 2 * rem),
            if (!canEdit)
              const StatusMessage(
                tone: StatusTone.info,
                message:
                    'Renaming and disabling an account are done by a partner or super admin.',
              )
            else
              // Keyed so each draft is a fresh subtree: reused button states would hand the old focus to a new button.
              KeyedSubtree(
                key: ValueKey(_draft),
                child: switch (_draft) {
                  _Draft.none => _actions(person, isSelf: isSelf),
                  _Draft.rename => _RenameDraft(
                    initial: person.fullName,
                    busy: _busy,
                    onEdit: () => setState(() => _error = null),
                    onCancel: () => _open(_Draft.none),
                    onConfirm: (name) => _run(
                      (token, id) => _people.updateName(
                        accessToken: token,
                        personId: id,
                        fullName: name,
                      ),
                    ),
                  ),
                  _Draft.disable || _Draft.enable => _statusDraft(
                    disable: _draft == _Draft.disable,
                  ),
                },
              ),
            const SizedBox(height: 2.5 * rem),
          ],
        ),
      ),
    );
  }

  Widget _actions(PersonModel person, {required bool isSelf}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: 'Change name',
              icon: LucideIcons.pencil,
              variant: TvButtonVariant.outline,
              autofocus: true,
              onSelect: () => _open(_Draft.rename),
            ),
            if (!person.isDisabled && !isSelf)
              TvButton(
                label: 'Disable account',
                icon: LucideIcons.userX,
                variant: TvButtonVariant.danger,
                onSelect: () => _open(_Draft.disable),
              ),
            if (person.isDisabled)
              TvButton(
                label: 'Enable account',
                icon: LucideIcons.userCheck,
                onSelect: () => _open(_Draft.enable),
              ),
          ],
        ),
        if (isSelf && !person.isDisabled) ...[
          const SizedBox(height: 1.5 * rem),
          const StatusMessage(
            tone: StatusTone.info,
            message:
                'You cannot disable your own account. Ask another admin if you need this one closed.',
          ),
        ],
      ],
    );
  }

  Widget _statusDraft({required bool disable}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          disable ? 'Disable this account?' : 'Let this account back in?',
          description: disable
              ? 'They are signed out of every device immediately and cannot sign in again until this is undone.'
              : 'They can sign in again with the password they already had. No new invite is needed.',
        ),
        const SizedBox(height: 1.25 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: disable ? 'Disable account' : 'Enable account',
              icon: disable ? LucideIcons.userX : LucideIcons.userCheck,
              variant: disable
                  ? TvButtonVariant.danger
                  : TvButtonVariant.primary,
              autofocus: true,
              busy: _busy,
              busyLabel: 'Saving…',
              onSelect: () => _run(
                (token, id) => disable
                    ? _people.disablePerson(accessToken: token, personId: id)
                    : _people.updateStatus(
                        accessToken: token,
                        personId: id,
                        status: 'ACTIVE',
                      ),
              ),
            ),
            TvButton(
              label: 'Cancel',
              variant: TvButtonVariant.outline,
              disabled: _busy,
              onSelect: () => _open(_Draft.none),
            ),
          ],
        ),
      ],
    );
  }
}

enum _NameField { fullName }

/// The rename form, mounted only while open, so its keystrokes and a cancelled name never outlive it.
class _RenameDraft extends StatefulWidget {
  const _RenameDraft({
    required this.initial,
    required this.busy,
    required this.onEdit,
    required this.onCancel,
    required this.onConfirm,
  });

  final String initial;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final ValueChanged<String> onConfirm;

  @override
  State<_RenameDraft> createState() => _RenameDraftState();
}

class _RenameDraftState extends State<_RenameDraft> {
  late final _entry = TextEntryController<_NameField>(
    _NameField.values,
    initial: {_NameField.fullName: widget.initial},
    maxLength: _fullNameMaxLength,
    onEdit: widget.onEdit,
  );

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextEntryScope(
      controller: _entry,
      onExit: widget.onCancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            'Change name',
            description:
                'This is the only route in the API that can set a display name — there is no self-service profile screen.',
          ),
          const SizedBox(height: 1.25 * rem),
          KeyboardFormLayout(
            alignTop: true,
            gap: 2 * rem,
            keyboard: OnScreenKeyboard(
              controller: _entry,
              extraKeys: KeySets.name,
            ),
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: _entry,
                  builder: (context, _) => TvTextField(
                    label: 'Full name',
                    value: _entry.value,
                    placeholder: 'Jordan Lee',
                    active: true,
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                Wrap(
                  spacing: rem,
                  runSpacing: rem,
                  children: [
                    TvButton(
                      label: 'Save name',
                      icon: LucideIcons.check,
                      autofocus: true,
                      busy: widget.busy,
                      busyLabel: 'Saving…',
                      onSelect: () => widget.onConfirm(_entry.value),
                    ),
                    TvButton(
                      label: 'Cancel',
                      variant: TvButtonVariant.outline,
                      disabled: widget.busy,
                      onSelect: widget.onCancel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
