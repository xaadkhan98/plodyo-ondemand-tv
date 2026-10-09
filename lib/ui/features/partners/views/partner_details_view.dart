import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/keyboard_form_layout.dart';
import '../../../../core/widgets/number_stepper.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_text_field.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../partner_labels.dart';

/// The decision open in place of the action row, if any.
enum _Draft { none, approve, reject, roomLimit, suspend, activate }

/// One partner: its record, and the review and status actions the API allows it in its current state.
/// Every confirmation replaces the action row inline; Back closes it before it leaves the screen.
class PartnerDetailsView extends StatefulWidget {
  const PartnerDetailsView({
    super.key,
    required this.partner,
    this.partnersRepository,
    this.authRepository,
  });

  final PartnerModel partner;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;

  @override
  State<PartnerDetailsView> createState() => _PartnerDetailsViewState();
}

class _PartnerDetailsViewState extends State<PartnerDetailsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final PartnersRepository _partners =
      widget.partnersRepository ?? sharedPartnersRepository;
  late PartnerModel _partner = widget.partner;
  _Draft _draft = _Draft.none;
  int _roomLimit = 0;
  bool _busy = false;
  String? _error;

  void _openDraft(_Draft draft) => setState(() {
    _error = null;
    _roomLimit = _partner.roomLimit;
    _draft = draft;
  });

  void _closeDraft() => setState(() => _draft = _Draft.none);

  /// Runs one action against the API and shows the record it returns.
  Future<void> _run(
    Future<PartnerModel> Function(String token, String id) action,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await action(_auth.accessToken, _partner.id);
      if (mounted) {
        setState(() {
          _partner = updated;
          _draft = _Draft.none;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not complete that action.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    setState(() => _error = null);
    final saved = await context.push<PartnerModel>(
      '/partners/edit',
      extra: _partner,
    );
    if (saved != null && mounted) setState(() => _partner = saved);
  }

  @override
  Widget build(BuildContext context) {
    final partner = _partner;
    final isSuper = _auth.currentUser?.isSuperAdmin ?? false;

    // Back closes an open draft first. The reject draft handles Back itself, deleting typed text first.
    return PopScope(
      canPop: _draft == _Draft.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _draft != _Draft.reject) _closeDraft();
      },
      child: ConsolePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvButton(
              label: 'All partners',
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
                ScreenHeading(partner.name),
                StatusBadge(partner.statusLabel, tone: partner.statusTone),
              ],
            ),
            const SizedBox(height: 2 * rem),
            TwoColumnGrid(
              children: [
                DetailCard.text(
                  label: 'Business type',
                  value: partner.typeLabel,
                ),
                DetailCard.text(
                  label: 'Contact email',
                  value: partner.contactEmail,
                ),
                DetailCard.text(
                  label: 'Contact name',
                  value: partner.contactName ?? 'Not given',
                ),
                DetailCard.text(
                  label: 'Phone',
                  value: partner.phone ?? 'Not given',
                ),
                DetailCard.text(
                  label: 'Room limit',
                  value: partner.roomLimit == 0
                      ? '0 — no rooms may sign in yet'
                      : '${partner.roomLimit} rooms',
                ),
                DetailCard.text(
                  label: 'Content tier',
                  value: partner.tierDescription,
                ),
                DetailCard.text(
                  label: 'Contract reference',
                  value: partner.contractReference ?? 'None',
                ),
                DetailCard.text(
                  label: 'Registered',
                  value: formatDateTime(partner.createdAt),
                ),
                DetailCard.text(
                  label: 'Reviewed',
                  value: partner.reviewedAt == null
                      ? 'Not yet'
                      : formatDateTime(partner.reviewedAt),
                ),
                if (partner.rejectionReason case final reason?)
                  WideCell(
                    child: DetailCard.text(
                      label: 'Rejection reason',
                      value: reason,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 1.5 * rem),
              StatusMessage(tone: StatusTone.error, message: _error!),
            ],
            if (partner.isSuspended) ...[
              const SizedBox(height: 1.5 * rem),
              const StatusMessage(
                tone: StatusTone.warning,
                message:
                    'Every device under this partner is failing authentication right now, in every property. Activating puts them all back.',
              ),
            ],
            const SizedBox(height: 2 * rem),
            // Keyed so each draft is a fresh subtree: reused button states would hand the old focus to a new button.
            KeyedSubtree(
              key: ValueKey(_draft),
              child: switch (_draft) {
                _Draft.none => _actions(partner, isSuper: isSuper),
                _Draft.suspend || _Draft.activate => _statusDraft(
                  suspend: _draft == _Draft.suspend,
                ),
                _Draft.reject => _RejectDraft(
                  busy: _busy,
                  onEdit: () => setState(() => _error = null),
                  onCancel: _closeDraft,
                  onConfirm: (reason) => _run(
                    (token, id) => _partners.rejectPartner(
                      accessToken: token,
                      partnerId: id,
                      rejectionReason: reason,
                    ),
                  ),
                ),
                _Draft.approve || _Draft.roomLimit => _roomLimitDraft(
                  approve: _draft == _Draft.approve,
                ),
              },
            ),
            const SizedBox(height: 2.5 * rem),
          ],
        ),
      ),
    );
  }

  Widget _actions(PartnerModel partner, {required bool isSuper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            // A partner admin may correct its own venue's contact details, and nothing else here.
            TvButton(
              label: 'Edit details',
              icon: LucideIcons.pencil,
              variant: TvButtonVariant.outline,
              autofocus: true,
              onSelect: _edit,
            ),
            if (isSuper && partner.canReview) ...[
              TvButton(
                label: 'Approve',
                icon: LucideIcons.check,
                onSelect: () => _openDraft(_Draft.approve),
              ),
              TvButton(
                label: 'Reject',
                icon: LucideIcons.x,
                variant: TvButtonVariant.danger,
                onSelect: () => _openDraft(_Draft.reject),
              ),
            ],
            if (isSuper && !partner.canReview)
              TvButton(
                label: 'Change room limit',
                variant: TvButtonVariant.outline,
                onSelect: () => _openDraft(_Draft.roomLimit),
              ),
            // Offered only where the API accepts it: suspend is ACTIVE-only, activate lifts a suspension only.
            if (isSuper && partner.canSuspend)
              TvButton(
                label: 'Suspend',
                icon: LucideIcons.powerOff,
                variant: TvButtonVariant.danger,
                onSelect: () => _openDraft(_Draft.suspend),
              ),
            if (isSuper && partner.canActivate)
              TvButton(
                label: 'Activate',
                icon: LucideIcons.power,
                onSelect: () => _openDraft(_Draft.activate),
              ),
          ],
        ),
        if (!isSuper) ...[
          const SizedBox(height: 1.5 * rem),
          const StatusMessage(
            tone: StatusTone.info,
            message:
                'Approving, rejecting, suspending and changing the room limit are done by a super admin.',
          ),
        ],
      ],
    );
  }

  Widget _statusDraft({required bool suspend}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          suspend ? 'Suspend this partner?' : 'Activate this partner?',
          description: suspend
              ? 'Every TV under every property this partner owns stops serving content on its next call. Rooms, devices and history are kept — activating puts them all back.'
              : 'Rooms under this partner start serving content again. No device needs re-pairing.',
        ),
        const SizedBox(height: 1.25 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: suspend ? 'Suspend partner' : 'Activate partner',
              icon: suspend ? LucideIcons.powerOff : LucideIcons.power,
              variant: suspend
                  ? TvButtonVariant.danger
                  : TvButtonVariant.primary,
              autofocus: true,
              busy: _busy,
              busyLabel: 'Saving…',
              onSelect: () => _run(
                (token, id) => suspend
                    ? _partners.suspendPartner(
                        accessToken: token,
                        partnerId: id,
                      )
                    : _partners.activatePartner(
                        accessToken: token,
                        partnerId: id,
                      ),
              ),
            ),
            TvButton(
              label: 'Cancel',
              variant: TvButtonVariant.outline,
              disabled: _busy,
              onSelect: _closeDraft,
            ),
          ],
        ),
      ],
    );
  }

  Widget _roomLimitDraft({required bool approve}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          approve ? 'Approve this application' : 'Room limit',
          description:
              'How many rooms may be signed in at once across this partner.${approve ? ' Leave it at 0 to approve without rooms.' : ''}',
        ),
        const SizedBox(height: 1.25 * rem),
        NumberStepper(
          value: _roomLimit,
          unit: 'rooms',
          disabled: _busy,
          autofocus: true,
          onChanged: (value) => setState(() => _roomLimit = value),
        ),
        const SizedBox(height: 1.5 * rem),
        Wrap(
          spacing: rem,
          runSpacing: rem,
          children: [
            TvButton(
              label: approve ? 'Confirm approval' : 'Save room limit',
              icon: LucideIcons.check,
              busy: _busy,
              busyLabel: 'Saving…',
              onSelect: () => _run(
                (token, id) => approve
                    ? _partners.approvePartner(
                        accessToken: token,
                        partnerId: id,
                        roomLimit: _roomLimit,
                      )
                    : _partners.updateRoomLimit(
                        accessToken: token,
                        partnerId: id,
                        roomLimit: _roomLimit,
                      ),
              ),
            ),
            TvButton(
              label: 'Cancel',
              variant: TvButtonVariant.outline,
              disabled: _busy,
              onSelect: _closeDraft,
            ),
          ],
        ),
      ],
    );
  }
}

enum _ReasonField { reason }

/// The reject form, mounted only while open, so its keystrokes and a cancelled reason never outlive it.
class _RejectDraft extends StatefulWidget {
  const _RejectDraft({
    required this.busy,
    required this.onEdit,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final ValueChanged<String> onConfirm;

  @override
  State<_RejectDraft> createState() => _RejectDraftState();
}

class _RejectDraftState extends State<_RejectDraft> {
  late final _entry = TextEntryController<_ReasonField>(
    _ReasonField.values,
    maxLength: 500,
    onEdit: widget.onEdit,
  );

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Back deletes while there is a reason to delete, and closes the draft once the field is empty.
    return TextEntryScope(
      controller: _entry,
      onExit: widget.onCancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            'Reject this application',
            description:
                'The reason is optional and is stored on the partner record.',
          ),
          const SizedBox(height: 1.25 * rem),
          KeyboardFormLayout(
            alignTop: true,
            gap: 2 * rem,
            keyboard: OnScreenKeyboard(
              controller: _entry,
              extraKeys: KeySets.sentence,
            ),
            form: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: _entry,
                  builder: (context, _) => TvTextField(
                    label: 'Reason (optional)',
                    value: _entry.value,
                    placeholder: 'e.g. Missing business registration details',
                    active: true,
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                Wrap(
                  spacing: rem,
                  runSpacing: rem,
                  children: [
                    TvButton(
                      label: 'Confirm rejection',
                      variant: TvButtonVariant.danger,
                      autofocus: true,
                      busy: widget.busy,
                      busyLabel: 'Rejecting…',
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
