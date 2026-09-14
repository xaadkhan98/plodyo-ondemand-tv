import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/tv_section_badge.dart';

class CategoryItemData {
  const CategoryItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.gradientColors,
    required this.glowColor,
    required this.watermarkIcon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final List<Color> gradientColors;
  final Color glowColor;
  final IconData watermarkIcon;
}

/// Categories View with 4x2 interactive vibrant theme cards matching Plodyo UI design.
class CategoriesView extends StatefulWidget {
  const CategoriesView({
    super.key,
    this.initialSelectedId = 'magic',
    this.onCategorySelected,
  });

  final String initialSelectedId;
  final ValueChanged<CategoryItemData>? onCategorySelected;

  static const List<CategoryItemData> categories = [
    CategoryItemData(
      id: 'nature',
      title: 'Nature',
      subtitle: 'Animals, plants, outdoors',
      emoji: '🌱',
      icon: Icons.eco_rounded,
      gradientColors: [Color(0xFF34D399), Color(0xFF059669)],
      glowColor: Color(0xFF10B981),
      watermarkIcon: Icons.eco_rounded,
    ),
    CategoryItemData(
      id: 'friends',
      title: 'Friends',
      subtitle: 'Friendship & social',
      emoji: '🤝',
      icon: Icons.people_alt_rounded,
      gradientColors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      glowColor: Color(0xFFF59E0B),
      watermarkIcon: Icons.handshake_rounded,
    ),
    CategoryItemData(
      id: 'family',
      title: 'Family',
      subtitle: 'Family bonds & love',
      emoji: '🏡',
      icon: Icons.cottage_rounded,
      gradientColors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
      glowColor: Color(0xFFF43F5E),
      watermarkIcon: Icons.cottage_rounded,
    ),
    CategoryItemData(
      id: 'adventure',
      title: 'Adventure',
      subtitle: 'Exciting journeys',
      emoji: '🧭',
      icon: Icons.explore_rounded,
      gradientColors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      glowColor: Color(0xFF0EA5E9),
      watermarkIcon: Icons.explore_rounded,
    ),
    CategoryItemData(
      id: 'magic',
      title: 'Magic',
      subtitle: 'Fantasy & wonder',
      emoji: '✨',
      icon: Icons.auto_awesome_rounded,
      gradientColors: [Color(0xFFA855F7), Color(0xFF8B5CF6)],
      glowColor: Color(0xFF8B5CF6),
      watermarkIcon: Icons.auto_awesome_rounded,
    ),
    CategoryItemData(
      id: 'learning',
      title: 'Learning',
      subtitle: 'Educational fun',
      emoji: '📚',
      icon: Icons.school_rounded,
      gradientColors: [Color(0xFF818CF8), Color(0xFF6366F1)],
      glowColor: Color(0xFF6366F1),
      watermarkIcon: Icons.menu_book_rounded,
    ),
    CategoryItemData(
      id: 'animals',
      title: 'Animals',
      subtitle: 'Cute creatures',
      emoji: '🐾',
      icon: Icons.pets_rounded,
      gradientColors: [Color(0xFFA3E635), Color(0xFF65A30D)],
      glowColor: Color(0xFF84CC16),
      watermarkIcon: Icons.pets_rounded,
    ),
    CategoryItemData(
      id: 'space',
      title: 'Space',
      subtitle: 'Stars & planets',
      emoji: '🚀',
      icon: Icons.rocket_launch_rounded,
      gradientColors: [Color(0xFFE879F9), Color(0xFFC026D3)],
      glowColor: Color(0xFFC026D3),
      watermarkIcon: Icons.rocket_launch_rounded,
    ),
  ];

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = screenWidth * 0.10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Top App Bar Branding: Logo + "Plodyo"
            const Padding(
              padding: EdgeInsets.fromLTRB(36, 16, 36, 8),
              child: PlodyoHeader(padding: EdgeInsets.zero),
            ),

            // Sticky Screen Name Section (Title + Subtitle)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalSpacing,
                vertical: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const TvSectionBadge(
                    icon: Icons.category_rounded,
                    size: 54,
                    iconSize: 28,
                    gradientColors: [
                      Color(0xFFF472B6),
                      Color(0xFFD946EF),
                      Color(0xFF9333EA),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title: "Categories"
                        Text(
                          'Categories',
                          style: GoogleFonts.baloo2(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18181B),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Subtitle: "Pick a theme to explore."
                        Text(
                          'Pick a theme to explore.',
                          style: GoogleFonts.nunito(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable 4-Column Responsive Grid of Category Cards
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const crossAxisCount = 4;
                        final totalSpacing = 16.0 * (crossAxisCount - 1);
                        final cardWidth =
                            (constraints.maxWidth - totalSpacing) /
                                crossAxisCount;
                        final cardHeight = cardWidth * 0.72;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: CategoriesView.categories.map((category) {
                            final isSelected = _selectedId == category.id;

                            return SizedBox(
                              width: cardWidth,
                              height: cardHeight,
                              child: _CategoryCard(
                                category: category,
                                isSelected: isSelected,
                                onSelected: () {
                                  setState(() {
                                    _selectedId = category.id;
                                  });
                                  widget.onCategorySelected?.call(category);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  final CategoryItemData category;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
        if (focused) {
          widget.onSelected();
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onSelected();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          widget.onSelected();
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: GestureDetector(
          onTap: widget.onSelected,
          child: AnimatedScale(
            scale: active ? 1.025 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.category.gradientColors,
                ),
                border: active
                    ? Border.all(color: Colors.white, width: 2.0)
                    : null,
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: widget.category.glowColor.withValues(alpha: 0.55),
                      blurRadius: 26,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Watermark subtle icon in top right
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Icon(
                      widget.category.watermarkIcon,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),

                  // Content inside card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),

                        // Prominent Category Icon right near the Title
                        Text(
                          widget.category.emoji,
                          style: const TextStyle(
                            fontSize: 32,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Title and Subtitle
                        Text(
                          widget.category.title,
                          style: GoogleFonts.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.category.subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
