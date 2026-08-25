import 'package:flutter/material.dart';
import '../theme/tv_colors.dart';
import '../theme/tv_typography.dart';
import '../constants/app_constants.dart';
import 'tv_focusable.dart';

class TvNavigationItem {
  const TvNavigationItem({
    required this.icon,
    required this.label,
    required this.id,
  });

  final IconData icon;
  final String label;
  final String id;
}

/// Expandable 10-foot TV Sidebar Navigation Rail.
class TvSidebar extends StatefulWidget {
  const TvSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<TvNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  State<TvSidebar> createState() => _TvSidebarState();
}

class _TvSidebarState extends State<TvSidebar> {
  bool _isSidebarFocused = false;

  @override
  Widget build(BuildContext context) {
    final width = _isSidebarFocused
        ? AppConstants.sidebarExpandedWidth
        : AppConstants.sidebarCollapsedWidth;

    return FocusScope(
      onFocusChange: (hasAnyChildFocus) {
        setState(() {
          _isSidebarFocused = hasAnyChildFocus;
        });
      },
      child: AnimatedContainer(
        duration: AppConstants.sidebarExpandDuration,
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: TvColors.sidebarBackground,
          border: const Border(
            right: BorderSide(
              color: Colors.white10,
              width: 1,
            ),
          ),
          boxShadow: _isSidebarFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 28),
            // App Brand Logo / Icon
            _buildBrandHeader(),
            const SizedBox(height: 32),
            // Navigation Menu Items
            Expanded(
              child: ListView.separated(
                itemCount: widget.items.length,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = widget.selectedIndex == index;
                  return _TvSidebarItemWidget(
                    item: item,
                    isSelected: isSelected,
                    isSidebarExpanded: _isSidebarFocused,
                    onTap: () => widget.onItemSelected(index),
                  );
                },
              ),
            ),
            // Version Info / TV Profile Indicator
            _buildProfileFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _isSidebarFocused
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: TvColors.focusBorderGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tv_rounded,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PLODYO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: TvColors.focusBorderGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tv_rounded,
                size: 24,
                color: Colors.black,
              ),
            ),
    );
  }

  Widget _buildProfileFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _isSidebarFocused
          ? Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: TvColors.surfaceElevated,
                  child: Icon(Icons.person_rounded, size: 20, color: TvColors.textSecondary),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Living Room TV',
                    style: TvTypography.cardSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : const CircleAvatar(
              radius: 16,
              backgroundColor: TvColors.surfaceElevated,
              child: Icon(Icons.person_rounded, size: 20, color: TvColors.textSecondary),
            ),
    );
  }
}

class _TvSidebarItemWidget extends StatefulWidget {
  const _TvSidebarItemWidget({
    required this.item,
    required this.isSelected,
    required this.isSidebarExpanded,
    required this.onTap,
  });

  final TvNavigationItem item;
  final bool isSelected;
  final bool isSidebarExpanded;
  final VoidCallback onTap;

  @override
  State<_TvSidebarItemWidget> createState() => _TvSidebarItemWidgetState();
}

class _TvSidebarItemWidgetState extends State<_TvSidebarItemWidget> {
  bool _isItemFocused = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isSelected
        ? TvColors.primary
        : (_isItemFocused ? Colors.white : TvColors.textSecondary);

    return TvFocusable(
      onPressed: widget.onTap,
      onFocusChange: (focused) {
        setState(() {
          _isItemFocused = focused;
        });
      },
      showFocusBorder: false,
      borderRadius: BorderRadius.circular(10),
      scaleFactor: 1.05,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: _isItemFocused
              ? TvColors.focusCardBackground
              : (widget.isSelected ? TvColors.surfaceElevated : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: widget.isSelected
              ? Border.all(color: TvColors.primary.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSidebarExpanded ? 14 : 0,
        ),
        child: widget.isSidebarExpanded
            ? Row(
                children: [
                  Icon(
                    widget.item.icon,
                    size: 22,
                    color: activeColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TvTypography.sidebarItem.copyWith(
                        color: activeColor,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  widget.item.icon,
                  size: 22,
                  color: activeColor,
                ),
              ),
      ),
    );
  }
}
