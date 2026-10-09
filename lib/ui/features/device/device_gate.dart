import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tv_colors.dart';
import '../../../core/theme/tv_scale.dart';
import '../../../core/widgets/loading.dart';
import '../../../core/widgets/notice_screen.dart';
import '../../../core/widgets/side_nav.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../data/repositories/device_repository.dart';
import 'device_controller.dart';
import 'views/pair_view.dart';
import 'views/welcome_view.dart';

/// The room TV's screens under the guest rail. This TV is left off: support reaches it by the blue button.
const _items = [
  NavItem(path: '/', label: 'Home', icon: LucideIcons.house, exact: true),
  NavItem(path: '/stories', label: 'Stories', icon: LucideIcons.library),
  NavItem(path: '/series', label: 'Series', icon: LucideIcons.layers),
  NavItem(
    path: '/learning',
    label: 'Learning',
    icon: LucideIcons.graduationCap,
  ),
  NavItem(path: '/search', label: 'Search', icon: LucideIcons.search),
];

/// Renders the guest screens only for a TV paired to a live room. Short of that it shows the way forward:
/// set the TV up, try again, or start over. Anyone who wanted the console is handed across to sign in.
class DeviceGate extends StatefulWidget {
  const DeviceGate({
    super.key,
    required this.currentPath,
    required this.child,
    this.deviceRepository,
  });

  final String currentPath;
  final Widget child;
  final DeviceRepository? deviceRepository;

  @override
  State<DeviceGate> createState() => _DeviceGateState();
}

class _DeviceGateState extends State<DeviceGate> {
  late final DeviceController _device = DeviceController(
    device: widget.deviceRepository,
  )..addListener(_onChange);
  bool _pairing = false;

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _device.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_device.phase) {
      DeviceLoading() => const Scaffold(body: Spinner()),
      DeviceUnpaired() when _pairing => PairView(
        pair: _device.pair,
        onCancel: () => setState(() => _pairing = false),
      ),
      DeviceUnpaired() => WelcomeView(
        onSetUp: () => setState(() => _pairing = true),
        onSignIn: () => context.push('/sign-in'),
      ),
      // One message covers every cause the API never distinguishes: revoked, re-provisioned elsewhere, or the
      // venue suspended. Two of those fix themselves, so trying again comes first and re-pairing second.
      DeviceUnauthorized() => Scaffold(
        body: NoticeScreen(
          icon: const Icon(
            LucideIcons.shieldAlert,
            size: 3.5 * rem,
            color: TvColors.destructive,
          ),
          title: 'This TV cannot reach its room',
          body:
              'Its access may have been withdrawn, or the venue may be suspended. Nothing on this set needs changing if the venue is coming back.',
          actions: [
            NoticeAction(label: 'Try again', onSelect: _device.resolve),
            NoticeAction(
              label: 'Set up this TV again',
              onSelect: _device.unpair,
              variant: TvButtonVariant.danger,
            ),
          ],
        ),
      ),
      DeviceUnavailable(:final notice) => Scaffold(
        body: NoticeScreen(
          icon: const Icon(
            LucideIcons.wifiOff,
            size: 3.5 * rem,
            color: TvColors.mutedForeground,
          ),
          title: 'Cannot reach Plodyo',
          body: notice,
          footnote:
              'This TV is still paired. Try again once the connection is back.',
          actions: [
            NoticeAction(label: 'Try again', onSelect: _device.resolve),
          ],
        ),
      ),
      // The blue button is support's way to This TV: a remote has one, and a child does not go hunting for it.
      // Material gives the rail's labels their text theme; each screen brings its own Scaffold.
      DeviceReady() => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.colorF3Blue): () {
            if (widget.currentPath != '/room') context.push('/room');
          },
        },
        child: DeviceScope(
          controller: _device,
          child: Material(
            type: MaterialType.transparency,
            child: SideNav(
              items: _items,
              currentPath: widget.currentPath,
              child: widget.child,
            ),
          ),
        ),
      ),
    };
  }
}
