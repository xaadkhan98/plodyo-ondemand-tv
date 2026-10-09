import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/side_nav.dart';
import '../../data/repositories/auth_repository.dart';

/// The console shell: the routed screen under the side rail, with the rail's entries filtered by role.
class MainTvLayout extends StatelessWidget {
  const MainTvLayout({
    super.key,
    required this.currentPath,
    required this.child,
    this.authRepository,
  });

  final String currentPath;
  final Widget child;
  final AuthRepository? authRepository;

  // Admin entries are hidden rather than disabled: a visible dead end reads as the app being broken.
  static List<NavItem> _itemsFor({required bool canAdminister}) => [
    const NavItem(
      path: '/overview',
      label: 'Overview',
      icon: LucideIcons.layoutDashboard,
      exact: true,
    ),
    if (canAdminister) ...const [
      NavItem(
        path: '/partners',
        label: 'Partners',
        icon: LucideIcons.building2,
      ),
      NavItem(path: '/invites', label: 'Invites', icon: LucideIcons.mail),
    ],
    const NavItem(
      path: '/properties',
      label: 'Properties',
      icon: LucideIcons.landmark,
    ),
    const NavItem(path: '/rooms', label: 'Rooms', icon: LucideIcons.doorOpen),
    const NavItem(path: '/people', label: 'People', icon: LucideIcons.users),
    const NavItem(
      path: '/settings',
      label: 'Account',
      icon: LucideIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final canAdminister =
        (authRepository ?? sharedAuthRepository).currentUser?.canAdminister ??
        false;
    // Material gives the rail's labels their text theme; the screen brings its own Scaffold.
    return Material(
      type: MaterialType.transparency,
      // The screen takes first focus, never the rail, so a booting console lands on content.
      child: SideNav(
        items: _itemsFor(canAdminister: canAdminister),
        currentPath: currentPath,
        child: child,
      ),
    );
  }
}
