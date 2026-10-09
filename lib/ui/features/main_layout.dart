import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/side_nav.dart';
import '../../data/repositories/auth_repository.dart';
import 'device/device_controller.dart';

/// The console shell: the routed screen under the side rail, with the rail's entries filtered by role.
/// It also holds the console's library picks, so a language chosen over the catalogue survives a visit to
/// the admin screens; those ignore it.
class MainTvLayout extends StatefulWidget {
  const MainTvLayout({
    super.key,
    required this.currentPath,
    required this.child,
    this.authRepository,
  });

  final String currentPath;
  final Widget child;
  final AuthRepository? authRepository;

  @override
  State<MainTvLayout> createState() => _MainTvLayoutState();
}

class _MainTvLayoutState extends State<MainTvLayout> {
  final _library = ConsoleLibrary();

  @override
  void dispose() {
    _library.dispose();
    super.dispose();
  }

  // The catalogue entries are the room TV's own screens, read through the admin lane. Admin entries are
  // hidden rather than disabled: a visible dead end reads as the app being broken.
  static List<NavItem> _itemsFor({required bool canAdminister}) => [
    const NavItem(
      path: '/',
      label: 'Home',
      icon: LucideIcons.house,
      exact: true,
    ),
    const NavItem(
      path: '/stories',
      label: 'Stories',
      icon: LucideIcons.library,
    ),
    const NavItem(path: '/series', label: 'Series', icon: LucideIcons.layers),
    const NavItem(
      path: '/learning',
      label: 'Learning',
      icon: LucideIcons.graduationCap,
    ),
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
        (widget.authRepository ?? sharedAuthRepository)
            .currentUser
            ?.canAdminister ??
        false;
    // Material gives the rail's labels their text theme; the screen brings its own Scaffold.
    return DeviceScope(
      session: _library,
      child: Material(
        type: MaterialType.transparency,
        // The screen takes first focus, never the rail, so a booting console lands on content.
        child: SideNav(
          items: _itemsFor(canAdminister: canAdminister),
          currentPath: widget.currentPath,
          child: widget.child,
        ),
      ),
    );
  }
}
