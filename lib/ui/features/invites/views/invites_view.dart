import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/admin_list_layout.dart';
import '../../../../core/widgets/choice_group.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/invite_model.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/invites_repository.dart';

const _statusLabels = {
  'PENDING': 'Pending',
  'ACCEPTED': 'Accepted',
  'EXPIRED': 'Expired',
  'REVOKED': 'Revoked',
};

/// Invites and the actions each still allows: resend and revoke appear only where the API would accept them,
/// because a button that always fails is worse than no button.
class InvitesView extends StatefulWidget {
  const InvitesView({super.key, this.invitesRepository, this.authRepository});

  final InvitesRepository? invitesRepository;
  final AuthRepository? authRepository;

  @override
  State<InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<InvitesView> {
  static const _filters = [
    Choice(value: 'all', label: 'All'),
    Choice(value: 'PENDING', label: 'Pending'),
    Choice(value: 'ACCEPTED', label: 'Accepted'),
    Choice(value: 'EXPIRED', label: 'Expired'),
    Choice(value: 'REVOKED', label: 'Revoked'),
  ];

  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late final InvitesRepository _invites =
      widget.invitesRepository ?? sharedInvitesRepository;
  late final _list = PagedList<InviteModel, String>(
    filter: 'all',
    fetch: (status, page) => _invites.getInvites(
      accessToken: _auth.accessToken,
      status: status == 'all' ? null : status,
      page: page,
      pageSize: defaultPageSize,
    ),
  )..load();

  /// The invite a resend or revoke is in flight for.
  String? _busyId;
  String? _actionError;

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _act(
    String inviteId,
    Future<Object?> Function(String token) action,
  ) async {
    setState(() {
      _busyId = inviteId;
      _actionError = null;
    });
    try {
      await action(_auth.accessToken);
      await _list.load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _actionError = messageOf(e, 'Could not complete that action.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _issue() async {
    final sent = await context.push<bool>('/invites/add');
    if (sent ?? false) _list.load();
  }

  /// The date that matters depends on where the invite got to.
  static String _timing(InviteModel invite) {
    if (invite.isAccepted && invite.acceptedAt != null) {
      return 'Accepted ${formatDate(invite.acceptedAt)}';
    }
    if (invite.isPending && invite.expiresAt != null) {
      return 'Expires ${formatDate(invite.expiresAt)}';
    }
    if (invite.sentAt != null) return 'Sent ${formatDate(invite.sentAt)}';
    return 'Created ${formatDate(invite.createdAt)}';
  }

  static BadgeTone _tone(InviteModel invite) => switch (invite.status) {
    'PENDING' => BadgeTone.pending,
    'ACCEPTED' => BadgeTone.positive,
    'EXPIRED' => BadgeTone.neutral,
    _ => BadgeTone.negative,
  };

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      maxWidth: 93.75 * rem,
      child: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => AdminListLayout<InviteModel, String>(
          list: _list,
          icon: LucideIcons.mail,
          title: 'Invites',
          description:
              'People invited to administer a partner or one of its properties. Invites expire after seven days.',
          filters: _filters,
          action: TvButton(
            label: 'Invite someone',
            icon: LucideIcons.plus,
            size: TvButtonSize.md,
            autofocus: true,
            onSelect: _issue,
          ),
          notice: _actionError == null
              ? null
              : StatusMessage(tone: StatusTone.error, message: _actionError!),
          emptyMessage: _list.filter == 'all'
              ? 'No invites have been sent yet.'
              : 'No invites are ${_statusLabels[_list.filter]!.toLowerCase()}.',
          rowBuilder: (invite) {
            final busy = _busyId == invite.id;
            return ListRow(
              icon: LucideIcons.mail,
              title: invite.email,
              badges: [
                StatusBadge(
                  _statusLabels[invite.status] ?? invite.status,
                  tone: _tone(invite),
                ),
              ],
              meta: [
                MetaItem('${roleLabel(invite.role)} · ${_timing(invite)}'),
              ],
              dimmed: busy,
              // The row is not a target itself: its buttons are.
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 0.75 * rem,
                children: [
                  if (busy) const LoadingDots(color: TvColors.mutedForeground),
                  if (invite.canResend)
                    TvButton(
                      label: 'Resend',
                      icon: LucideIcons.rotateCw,
                      variant: TvButtonVariant.outline,
                      size: TvButtonSize.sm,
                      disabled: busy,
                      onSelect: () => _act(
                        invite.id,
                        (token) => _invites.resendInvite(
                          accessToken: token,
                          inviteId: invite.id,
                        ),
                      ),
                    ),
                  if (invite.canRevoke)
                    TvButton(
                      label: 'Revoke',
                      icon: LucideIcons.trash2,
                      variant: TvButtonVariant.danger,
                      size: TvButtonSize.sm,
                      disabled: busy,
                      onSelect: () => _act(
                        invite.id,
                        (token) => _invites.revokeInvite(
                          accessToken: token,
                          inviteId: invite.id,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
