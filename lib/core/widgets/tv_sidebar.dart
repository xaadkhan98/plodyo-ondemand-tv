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

/// Dynamic Expandable 10-foot TV Sidebar Navigation Rail matching Plodyo Console design.
class TvSidebar extends StatefulWidget {
  const TvSidebar({
    super.key,
    required this.currentPath,
    this.onItemSelected,
    this.initialExpanded = false,
  });

  final String currentPath;
  final ValueChanged<String>? onItemSelected;
  final bool initialExpanded;

  static const List<TvNavigationItem> navItems = [
    // ---------------------------------------------------------
    // Previous consumer/VOD sections (commented out as requested)
    // ---------------------------------------------------------
    // TvNavigationItem(
    //   svgAsset: 'assets/icons/home.svg',
    //   label: 'Home',
    //   path: '/home',
    // ),
    // TvNavigationItem(
    //   svgAsset: 'assets/icons/search.svg',
    //   label: 'Search',
    //   path: '/search',
    // ),
    // TvNavigationItem(
    //   svgAsset: 'assets/icons/categories.svg',
    //   label: 'Categories',
    //   path: '/categories',
    // ),
    // TvNavigationItem(
    //   icon: Icons.bar_chart_rounded,
    //   label: 'All stories',
    //   path: '/stories',
    // ),

    // ---------------------------------------------------------
    // Console Management Navigation Sections (shown in design)
    // ---------------------------------------------------------
    TvNavigationItem(
      icon: Icons.grid_view_rounded,
      label: 'Overview',
      path: '/overview',
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
      icon: Icons.people_outline_rounded,
      label: 'People',
      path: '/people',
    ),
    TvNavigationItem(
      icon: Icons.settings_outlined,
      label: 'Account',
      path: '/settings',
    ),
  ];

  @override
  State<TvSidebar> createState() => _TvSidebarState();
}

class _TvSidebarState extends State<TvSidebar> {
  late bool _isSidebarFocused;
  bool _isSidebarHovered = false;

  @override
  void initState() {
    super.initState();
    _isSidebarFocused = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = _isSidebarFocused || _isSidebarHovered;
    final width = isExpanded ? 220.0 : 74.0;

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
          duration: const Duration(milliseconds: 220),
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
                color: Colors.black.withValues(alpha: isExpanded ? 0.08 : 0.03),
                blurRadius: isExpanded ? 20 : 10,
                spreadRadius: isExpanded ? 2 : 1,
                offset: Offset(isExpanded ? 5 : 2, 0),
              ),
              BoxShadow(
                color: const Color(0xFF9333EA)
                    .withValues(alpha: isExpanded ? 0.08 : 0.02),
                blurRadius: isExpanded ? 18 : 8,
                offset: Offset(isExpanded ? 3 : 1, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top spacing aligned with the first card in Overview
              const SizedBox(height: 180),

              // Navigation items list
              Expanded(
                child: ListView.separated(
                  itemCount: TvSidebar.navItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = TvSidebar.navItems[index];
                    final isSelected = widget.currentPath == item.path ||
                        (item.path != '/' &&
                            widget.currentPath.startsWith(item.path));

                    return _TvSidebarItemWidget(
                      item: item,
                      isSelected: isSelected,
                      isExpanded: isExpanded,
                      autofocus: index == 0 && widget.initialExpanded,
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
    this.autofocus = false,
  });

  final TvNavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool autofocus;

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
    final isSelected = widget.isSelected;

    // Color tokens matching the design image:
    // Selected item in collapsed/expanded mode uses lavender box + purple icon & text
    final backgroundColor = isSelected
        ? const Color(0xFFF3E8FF)
        : (active ? const Color(0xFFFAF5FF) : Colors.transparent);

    final borderColor = isSelected
        ? const Color(0xFFDDD6FE)
        : (active ? const Color(0xFFE9D5FF) : Colors.transparent);

    final foregroundColor = isSelected || active
        ? const Color(0xFF9333EA)
        : const Color(0xFF1E293B);

    return Focus(
      autofocus: widget.autofocus,
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
              scale: active ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: widget.isExpanded ? double.infinity : 52,
                height: 52,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isExpanded ? 14 : 0,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: borderColor,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9333EA)
                                .withValues(alpha: 0.16),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: widget.isExpanded
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: 180,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: _buildIcon(
                                    foregroundColor,
                                    27,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.item.label,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : (active
                                            ? FontWeight.w700
                                            : FontWeight.w600),
                                    color: foregroundColor,
                                    letterSpacing: -0.2,
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
                          foregroundColor,
                          27,
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
