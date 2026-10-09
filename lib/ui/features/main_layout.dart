import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/tv_colors.dart';
import '../../core/theme/tv_scale.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/notice_screen.dart';
import '../../core/widgets/side_nav.dart';
import '../../data/models/auth_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'device/device_controller.dart';

/// The console shell: the routed screen under the side rail, with the rail's entries filtered by role.
/// A session restored from storage is checked against /auth/me before any screen reads its actor. The shell
/// also holds the console's library picks, so a language chosen over the catalogue survives a visit to the
/// admin screens; those ignore it.
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

  AuthRepository get _auth => widget.authRepository ?? sharedAuthRepository;

  // Restored, so the actor is still unknown.
  late bool _resuming = _auth.currentUser == null && _auth.isAuthenticated;

  // Set when Plodyo could not be reached: the session is intact, so trying again needs no password.
  String? _unreachable;

  @override
  void initState() {
    super.initState();
    if (_resuming) _resume();
  }

  Future<void> _resume() async {
    try {
      await _auth.resume();
    } on AuthException catch (error) {
      // A refused session is over, and the router has already taken the console to sign-in.
      if (error.statusCode != 401 && mounted) {
        setState(() => _unreachable = error.message);
      }
      return;
    }
    if (mounted) setState(() => _resuming = false);
  }

  void _retry() {
    setState(() => _unreachable = null);
    _resume();
  }

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
    if (_unreachable case final notice?) {
      return Scaffold(
        body: NoticeScreen(
          icon: const Icon(
            LucideIcons.wifiOff,
            size: 3.5 * rem,
            color: TvColors.mutedForeground,
          ),
          title: 'Cannot reach Plodyo',
          body: notice,
          footnote:
              'This session is still signed in. Try again once the connection is back.',
          actions: [NoticeAction(label: 'Try again', onSelect: _retry)],
        ),
      );
    }
    if (_resuming) return const Scaffold(body: Spinner());

    final canAdminister = _auth.currentUser?.canAdminister ?? false;
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
