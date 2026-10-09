import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_heading.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/actor.dart';
import '../../../../data/models/membership.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Who this console session is signed in as, and how to sign it out. Re-read from /auth/me on open,
/// so a role change shows without waiting for the token to expire.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, this.authRepository, this.onSignOut});

  final AuthRepository? authRepository;
  final VoidCallback? onSignOut;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final AuthRepository _auth =
      widget.authRepository ?? sharedAuthRepository;
  late Actor? _actor = _auth.currentUser;
  List<Membership> _memberships = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final me = await _auth.getMe();
      if (!mounted) return;
      setState(() {
        _actor = me.actor;
        _memberships = me.memberships;
      });
    } catch (_) {
      // Offline or expired: the account this session signed in with is still the right thing to show.
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    widget.onSignOut != null ? widget.onSignOut!() : context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final actor = _actor;
    // The membership the session is scoped to is already shown under Account.
    final others = [
      for (final m in _memberships)
        if (m.role != actor?.role ||
            m.partnerId != actor?.partnerId ||
            m.propertyId != actor?.propertyId)
          m,
    ];

    return ConsolePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            icon: LucideIcons.settings,
            title: 'Settings',
            subtitle: 'The account this console session is signed in with.',
          ),
          const SizedBox(height: 2.5 * rem),
          const SectionHeading('Account'),
          const SizedBox(height: 1.25 * rem),
          TwoColumnGrid(
            children: [
              DetailCard.text(
                icon: LucideIcons.userRound,
                label: 'Name',
                value: (actor?.fullName.isNotEmpty ?? false)
                    ? actor!.fullName
                    : 'Not set',
              ),
              DetailCard.text(
                icon: LucideIcons.mail,
                label: 'Email',
                value: actor?.email ?? 'Not set',
              ),
              DetailCard(
                icon: LucideIcons.shieldCheck,
                label: 'Role',
                value: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    actor == null ? 'Not set' : roleLabel(actor.role),
                    tone: BadgeTone.positive,
                  ),
                ),
              ),
              DetailCard.text(
                icon: LucideIcons.building2,
                label: 'Scope',
                value: actor == null
                    ? 'Not set'
                    : describeScope(actor.partnerId, actor.propertyId),
              ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 3 * rem),
            const SectionHeading(
              'Other access',
              description:
                  'This account also holds the scopes below. Signing in here uses the one above; there is no way to switch between them yet.',
            ),
            const SizedBox(height: 1.25 * rem),
            TwoColumnGrid(
              children: [
                for (final m in others)
                  DetailCard.text(
                    icon: LucideIcons.building2,
                    label: roleLabel(m.role),
                    value: describeScope(m.partnerId, m.propertyId),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 3 * rem),
          const SectionHeading(
            'Sign out',
            description:
                'Ends every session started from this login, on every device.',
          ),
          const SizedBox(height: 1.25 * rem),
          TvButton(
            label: 'Sign out',
            icon: LucideIcons.logOut,
            variant: TvButtonVariant.danger,
            size: TvButtonSize.md,
            autofocus: true,
            onSelect: _signOut,
          ),
          const SizedBox(height: 2.5 * rem),
        ],
      ),
    );
  }
}
