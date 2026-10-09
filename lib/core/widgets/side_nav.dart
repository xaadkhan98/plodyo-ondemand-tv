import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'outset_shadow.dart';
import 'tv_focusable.dart';

/// One destination in the [SideNav].
class NavItem {
  const NavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.exact = false,
  });

  final String path;
  final String label;
  final IconData icon;

  /// Lit only on its own path, not on the sections nested under it.
  final bool exact;

  bool isActive(String current) =>
      current == path ||
      (!exact && path != '/' && current.startsWith('$path/'));
}

/// The left rail over the routed [child]: icons only until focus enters it, then it opens over the screen
/// with labels. Translucent until focused, because an opaque strip read as a seam down the screen.
/// It also bridges focus: each screen is its own route focus scope, which Flutter's D-pad traversal
/// never leaves, so Left past a screen's edge is carried into the rail here, and Right back out.
class SideNav extends StatefulWidget {
  const SideNav({
    super.key,
    required this.items,
    required this.currentPath,
    required this.child,
  });

  static const double collapsedWidth = 4.5 * rem;
  static const double expandedWidth = 15.5 * rem;

  final List<NavItem> items;
  final String currentPath;
  final Widget child;

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  static const _duration = Duration(milliseconds: 300);

  late List<FocusNode> _nodes = _nodesFor(widget.items);
  bool _open = false;

  /// Where focus was on the screen when it crossed into the rail, so Right returns to it.
  FocusNode? _returnTo;

  static List<FocusNode> _nodesFor(List<NavItem> items) => [
    for (final _ in items) FocusNode(),
  ];

  @override
  void didUpdateWidget(SideNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = _nodesFor(widget.items);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  static bool _isPress(KeyEvent event) =>
      event is KeyDownEvent || event is KeyRepeatEvent;

  /// Left with nothing further left on the screen enters the rail at the tile nearest in height.
  KeyEventResult _onScreenKey(FocusNode _, KeyEvent event) {
    final current = FocusManager.instance.primaryFocus;
    if (!_isPress(event) ||
        event.logicalKey != LogicalKeyboardKey.arrowLeft ||
        current == null) {
      return KeyEventResult.ignored;
    }
    if (current.focusInDirection(TraversalDirection.left)) {
      return KeyEventResult.handled;
    }
    final y = current.rect.center.dy;
    final nearest = _nodes.reduce(
      (a, b) =>
          (a.rect.center.dy - y).abs() <= (b.rect.center.dy - y).abs() ? a : b,
    );
    _returnTo = current;
    nearest.requestFocus();
    return KeyEventResult.handled;
  }

  /// The rail owns up and down, stopping at its ends; Right goes back to where the screen left off.
  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (!_isPress(event)) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final target = _returnTo;
      if (target == null || target.context == null) {
        return KeyEventResult.ignored;
      }
      target.requestFocus();
      return KeyEventResult.handled;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowDown => 1,
      _ => 0,
    };
    if (step == 0) return KeyEventResult.ignored;
    final index = _nodes.indexWhere((node) => node.hasFocus);
    if (index >= 0 && index + step >= 0 && index + step < _nodes.length) {
      _nodes[index + step].requestFocus();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.zero;
    final rail = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _open = focused),
      onKeyEvent: _onKey,
      child: OutsetShadow(
        shadows: _open ? TvShadows.x2l() : const [],
        borderRadius: radius,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2 * px, sigmaY: 2 * px),
            child: AnimatedContainer(
              duration: _duration,
              curve: TvMotion.focus,
              width: _open ? SideNav.expandedWidth : SideNav.collapsedWidth,
              padding: const EdgeInsets.symmetric(horizontal: 0.5 * rem),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _open ? 0.95 : 0.4),
                border: Border(
                  right: BorderSide(
                    color: TvColors.border.withValues(alpha: 0.4),
                    width: px,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 0.375 * rem,
                children: [
                  for (final (index, item) in widget.items.indexed)
                    _NavTile(
                      item: item,
                      focusNode: _nodes[index],
                      open: _open,
                      active: item.isActive(widget.currentPath),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: _onScreenKey,
            child: widget.child,
          ),
        ),
        Positioned(left: 0, top: 0, bottom: 0, child: rail),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.focusNode,
    required this.open,
    required this.active,
  });

  final NavItem item;
  final FocusNode focusNode;
  final bool open;
  final bool active;

  static const _radius = BorderRadius.all(Radius.circular(0.75 * rem));
  static const _labelSlide = Duration(milliseconds: 300);
  static final _lift = SpringCurve(
    stiffness: 380,
    damping: 28,
    duration: const Duration(milliseconds: 400),
  );

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: focusNode,
      // The tile fills on focus; at 4.5rem collapsed there is no room for an outset ring.
      ring: false,
      borderRadius: _radius,
      semanticLabel: item.label,
      onSelect: () => context.go(item.path),
      builder: (context, focused) {
        final color = focused
            ? Colors.white
            : (active ? TvColors.primary : TvColors.foreground);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 3.25 * rem,
          padding: const EdgeInsets.symmetric(horizontal: 0.875 * rem),
          decoration: BoxDecoration(
            color: !focused && active
                ? TvColors.primary.withValues(alpha: 0.1)
                : null,
            gradient: focused ? TvColors.brand : null,
            borderRadius: _radius,
            boxShadow: focused ? TvShadows.lg() : null,
          ),
          // The label slides out from under the icon, so the rail opens rather than blinks.
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: rem,
                children: [
                  AnimatedSlide(
                    offset: Offset(0, focused ? -1 / 15 : 0),
                    duration: _lift.duration,
                    curve: _lift,
                    child: Icon(item.icon, size: 1.5 * rem, color: color),
                  ),
                  AnimatedOpacity(
                    opacity: open ? 1 : 0,
                    duration: _labelSlide,
                    curve: TvMotion.focus,
                    child: AnimatedSlide(
                      offset: Offset(open ? 0 : -0.3, 0),
                      duration: _labelSlide,
                      curve: TvMotion.focus,
                      child: Text(
                        item.label,
                        style: TvText.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
