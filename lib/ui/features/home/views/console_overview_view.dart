import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_scale.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/list_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/two_column_grid.dart';
import '../../../../data/models/actor.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Where the console starts, so signing in never drops an admin on a section they cannot open.
class ConsoleOverviewView extends StatelessWidget {
  const ConsoleOverviewView({super.key, this.authRepository});

  final AuthRepository? authRepository;

  static const _sections = [
    _Section(
      path: '/partners',
      label: 'Partners',
      body:
          'Review applications, onboard a venue by hand, and set how many rooms each may sign in.',
      icon: LucideIcons.building2,
      adminOnly: true,
    ),
    _Section(
      path: '/invites',
      label: 'Invites',
      body:
          'Send someone an account, chase one that was never accepted, or revoke it.',
      icon: LucideIcons.mail,
      adminOnly: true,
    ),
    _Section(
      path: '/',
      label: 'Library',
      body:
          'The stories and series your rooms can play, on the tier this partner is on.',
      icon: LucideIcons.library,
    ),
    _Section(
      path: '/properties',
      label: 'Properties',
      body:
          'The buildings rooms are created under. Suspending one stops every room in it.',
      icon: LucideIcons.landmark,
    ),
    _Section(
      path: '/rooms',
      label: 'Rooms',
      body:
          'One row per TV. Pair a set, take one out of service, or add a floor at a time.',
      icon: LucideIcons.doorOpen,
    ),
    _Section(
      path: '/people',
      label: 'People',
      body:
          'Everyone who can sign in within your scope, and whether they still can.',
      icon: LucideIcons.users,
    ),
    _Section(
      path: '/settings',
      label: 'Account',
      body: 'The account this session is signed in as, and how to sign out.',
      icon: LucideIcons.settings,
    ),
  ];

  /// How far this session's scope reaches, which the API enforces.
  static String _reach(Actor? actor) => switch (actor?.role) {
    'SUPER_ADMIN' => 'Every partner, property and room on Plodyo TV.',
    'PARTNER_ADMIN' =>
      'Everything under your partner, across all of its properties.',
    _ => 'Your own property, and the rooms and people inside it.',
  };

  @override
  Widget build(BuildContext context) {
    final actor = (authRepository ?? sharedAuthRepository).currentUser;
    final sections = [
      for (final section in _sections)
        if (!section.adminOnly || (actor?.canAdminister ?? false)) section,
    ];

    return ConsolePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageTitle(
            icon: LucideIcons.layoutDashboard,
            title: 'Console',
            badge: actor == null
                ? null
                : StatusBadge(roleLabel(actor.role), tone: BadgeTone.positive),
            subtitle:
                '${_reach(actor)} Library shows what your rooms can play; the TVs themselves sign in '
                'with their own room credential.',
          ),
          const SizedBox(height: 2.25 * rem),
          TwoColumnGrid(
            children: [
              for (final (index, section) in sections.indexed)
                ListRow(
                  icon: section.icon,
                  title: section.label,
                  body: section.body,
                  autofocus: index == 0,
                  onSelect: () => context.go(section.path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.path,
    required this.label,
    required this.body,
    required this.icon,
    this.adminOnly = false,
  });

  final String path;
  final String label;
  final String body;
  final IconData icon;

  /// Partners and invites 403 for a property admin, so the card is hidden rather than a dead end.
  final bool adminOnly;
}
