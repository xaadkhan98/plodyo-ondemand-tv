import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TvNavigationItem {
  const TvNavigationItem({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.path,
  }) : assert(icon != null || svgAsset != null, 'Must provide either icon or svgAsset');

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final String path;
}

/// Dynamic Expandable 10-foot TV Sidebar Navigation Rail.
///
/// Overlays on top of the main screen, expanding from 58px to 175px when focused/hovered
/// to reveal tab names without causing layout shifts to the main screen.
class TvSidebar extends StatefulWidget {
  const TvSidebar({
    super.key,
    required this.currentPath,
    this.onItemSelected,
  });

  final String currentPath;
  final ValueChanged<String>? onItemSelected;

  static const List<TvNavigationItem> navItems = [
    TvNavigationItem(
      svgAsset: 'assets/icons/home.svg',
      label: 'Home',
      path: '/home',
    ),
    TvNavigationItem(
      svgAsset: 'assets/icons/search.svg',
      label: 'Search',
      path: '/search',
    ),
    TvNavigationItem(
      svgAsset: 'assets/icons/categories.svg',
      label: 'Categories',
      path: '/categories',
    ),
    TvNavigationItem(
      icon: Icons.bar_chart_rounded,
      label: 'All stories',
      path: '/stories',
    ),
    TvNavigationItem(
      icon: Icons.apartment_rounded,
      label: 'Partners',
      path: '/partners',
    ),
    TvNavigationItem(
      icon: Icons.mail_outline_rounded,
      label: 'Invites',
      path: '/invites',
    ),
    TvNavigationItem(
      icon: Icons.account_balance_outlined,
      label: 'Properties',
      path: '/properties',
    ),
    TvNavigationItem(
      icon: Icons.meeting_room_outlined,
      label: 'Rooms',
      path: '/rooms',
    ),
    TvNavigationItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      path: '/settings',
    ),
  ];

  @override
  State<TvSidebar> createState() => _TvSidebarState();
}

class _TvSidebarState extends State<TvSidebar> {
  bool _isSidebarFocused = false;
  bool _isSidebarHovered = false;

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isSidebarFocused || _isSidebarHovered;
    final width = isExpanded ? 175.0 : 58.0;

    return FocusScope(
      onFocusChange: (hasAnyChildFocus) {
        setState(() {
          _isSidebarFocused = hasAnyChildFocus;
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isSidebarHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isSidebarHovered = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              right: BorderSide(
                color: Color(0xFFF1EBF5),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isExpanded ? 0.08 : 0.04),
                blurRadius: isExpanded ? 22 : 12,
                spreadRadius: isExpanded ? 2 : 1,
                offset: Offset(isExpanded ? 5 : 3, 0),
              ),
              BoxShadow(
                color: const Color(0xFF9333EA).withValues(alpha: isExpanded ? 0.08 : 0.03),
                blurRadius: isExpanded ? 20 : 10,
                offset: Offset(isExpanded ? 3 : 2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Fixed constant top spacing so tabs never jump vertically
              const SizedBox(height: 120),

              // Navigation items list with stable vertical spacing
              Expanded(
                child: ListView.separated(
                  itemCount: TvSidebar.navItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = TvSidebar.navItems[index];
                    final isSelected = widget.currentPath.startsWith(item.path);

                    return _TvSidebarItemWidget(
                      item: item,
                      isSelected: isSelected,
                      isExpanded: isExpanded,
                      onTap: () {
                        if (widget.onItemSelected != null) {
                          widget.onItemSelected!(item.path);
                        } else {
                          context.go(item.path);
                        }
                      },
                    );
                  },
                ),
              ),

              // User Profile Avatar Footer (Circle with 'N')
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvSidebarItemWidget extends StatefulWidget {
  const _TvSidebarItemWidget({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final TvNavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_TvSidebarItemWidget> createState() => _TvSidebarItemWidgetState();
}

class _TvSidebarItemWidgetState extends State<_TvSidebarItemWidget> {
  bool _isFocused = false;
  bool _isHovered = false;

  Widget _buildIcon(Color color, double size) {
    if (widget.item.svgAsset != null) {
      return SvgPicture.asset(
        widget.item.svgAsset!,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color,
          BlendMode.srcIn,
        ),
      );
    }
    return Icon(
      widget.item.icon,
      size: size,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;
    final isHighlighted = widget.isSelected || active;

    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Tooltip(
        message: widget.isExpanded ? '' : widget.item.label,
        waitDuration: const Duration(milliseconds: 300),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: active ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: widget.isExpanded ? double.infinity : 42,
                height: 42,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isExpanded ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFD946EF),
                            Color(0xFF9333EA),
                          ],
                        )
                      : null,
                  color: isHighlighted ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD946EF).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: widget.isExpanded
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 140,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Center(
                                  child: _buildIcon(
                                    isHighlighted
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                    20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isHighlighted
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isHighlighted
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: _buildIcon(
                          isHighlighted
                              ? Colors.white
                              : const Color(0xFF374151),
                          20,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
