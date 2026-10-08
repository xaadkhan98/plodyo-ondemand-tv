import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/person_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/people_repository.dart';

enum PeopleFilter {
  all,
  active,
  invited,
  disabled,
}

/// People View matching the Plodyo TV specification.
/// Displays everyone who can sign in within organization scope,
/// with filter chips (All, Active, Invited, Disabled),
/// glowing focused TV card states, and full account management capabilities.
class PeopleView extends StatefulWidget {
  const PeopleView({
    super.key,
    this.peopleRepository,
    this.authRepository,
    this.onPersonSelected,
  });

  final PeopleRepository? peopleRepository;
  final AuthRepository? authRepository;
  final ValueChanged<PersonModel>? onPersonSelected;

  @override
  State<PeopleView> createState() => _PeopleViewState();
}

class _PeopleViewState extends State<PeopleView> {
  late final PeopleRepository _peopleRepository;
  late final AuthRepository _authRepository;

  PeopleFilter _selectedFilter = PeopleFilter.all;
  List<PersonModel> _people = [];
  bool _isLoading = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _peopleRepository = widget.peopleRepository ?? sharedPeopleRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    _loadPeople();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case PeopleFilter.active:
        return 'ACTIVE';
      case PeopleFilter.invited:
        return 'INVITED';
      case PeopleFilter.disabled:
        return 'DISABLED';
      case PeopleFilter.all:
        return null;
    }
  }

  List<PersonModel> get _filteredPeople {
    final list = _people;
    if (_selectedFilter == PeopleFilter.all) return list;
    return list.where((p) {
      switch (_selectedFilter) {
        case PeopleFilter.active:
          return p.isActive;
        case PeopleFilter.invited:
          return p.isInvited;
        case PeopleFilter.disabled:
          return p.isDisabled;
        case PeopleFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _loadPeople() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final response = await _peopleRepository.getPeople(
        accessToken: token,
        status: _apiStatusQuery,
      );

      if (mounted) {
        setState(() {
          _people = response.data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _people = [];
          _isLoading = false;
          _errorMessage = e is AuthException ? e.message : 'Could not load people.';
        });
      }
    }
  }

  void _onFilterChanged(PeopleFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadPeople();
    }
  }

  void _showPersonDetailsDialog(PersonModel person) async {
    if (widget.onPersonSelected != null) {
      widget.onPersonSelected!(person);
      return;
    }

    await context.push('/people/details', extra: person);
    if (mounted) {
      _loadPeople();
    }
  }

  @override
  Widget build(BuildContext context) {
    final peopleToDisplay = _filteredPeople;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Plodyo Logo Header (Sticky)
            const Padding(
              padding: EdgeInsets.only(left: 48, right: 48, top: 20, bottom: 8),
              child: PlodyoHeader(padding: EdgeInsets.zero),
            ),

            // Title Row & Filter Controls Section (Sticky)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row: Angled Floating Badge Icon + "People" Title & Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Angled Floating People Badge Icon matching the screenshot
                      const TvSectionBadge(
                        icon: Icons.people_alt_rounded,
                        gradientColors: [
                          Color(0xFFF472B6), // Soft vibrant pink / magenta
                          Color(0xFFE879F9), // Vibrant soft magenta
                          Color(0xFF9333EA), // Royal purple
                          Color(0xFF7E22CE), // Deep purple
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Title & Subtitle Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'People',
                              style: GoogleFonts.baloo2(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF9333EA),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Everyone who can sign in within your scope. Disabling an account ends its sessions on every device at once.',
                              style: GoogleFonts.nunito(
                                fontSize: 15.5,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Filter Chips / Tabs Row (All, Active, Invited, Disabled)
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == PeopleFilter.all,
                        onTap: () => _onFilterChanged(PeopleFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Active',
                        isSelected: _selectedFilter == PeopleFilter.active,
                        onTap: () => _onFilterChanged(PeopleFilter.active),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Invited',
                        isSelected: _selectedFilter == PeopleFilter.invited,
                        onTap: () => _onFilterChanged(PeopleFilter.invited),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Disabled',
                        isSelected: _selectedFilter == PeopleFilter.disabled,
                        onTap: () => _onFilterChanged(PeopleFilter.disabled),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Content Area: Loading, Error, Empty State, or Scrollable People List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: PlodyoPageLoading(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626), size: 36),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Color(0xFF71717A), fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _loadPeople,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : peopleToDisplay.isEmpty
                          ? _EmptyStateWidget(filter: _selectedFilter)
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 48, right: 48, bottom: 32),
                              itemCount: peopleToDisplay.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final person = peopleToDisplay[index];
                                return _PersonCard(
                                  person: person,
                                  onTap: () => _showPersonDetailsDialog(person),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter Pill Chip with hover, focus, and inner glowing shadow
class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    // Matching screenshot:
    // Selected chip has purple border + subtle lavender background
    // Unselected chips have dark crisp border + white background
    final backgroundColor = widget.isSelected
        ? const Color(0xFFFAF5FF)
        : (active ? const Color(0xFFFBF8FF) : Colors.white);

    final borderColor = widget.isSelected
        ? const Color(0xFF8B5CF6)
        : (active ? const Color(0xFF8B5CF6) : const Color(0xFF334155));

    final textColor = widget.isSelected || active
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF1E293B);

    final innerShadowColor = active
        ? const Color(0xFF9333EA).withValues(alpha: 0.38)
        : (widget.isSelected
            ? const Color(0xFF9333EA).withValues(alpha: 0.16)
            : Colors.transparent);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 2.0 : 1.3,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  else if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: widget.isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (innerShadowColor != Colors.transparent)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PillInnerShadowPainter(
                              shadowColor: innerShadowColor,
                              borderRadius: 22,
                              blurRadius: active ? 6.0 : 3.5,
                              strokeWidth: active ? 4.0 : 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for soft inner primary shadow around rounded pill border
class _PillInnerShadowPainter extends CustomPainter {
  const _PillInnerShadowPainter({
    required this.shadowColor,
    required this.borderRadius,
    this.blurRadius = 6.0,
    this.strokeWidth = 3.5,
  });

  final Color shadowColor;
  final double borderRadius;
  final double blurRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadowColor.a == 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PillInnerShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.blurRadius != blurRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Person Card widget matching the design screenshot.
/// Features avatar icon, full name, status badge, optional "You" tag,
/// email, role shield, and last active timestamp.
class _PersonCard extends StatefulWidget {
  const _PersonCard({
    required this.person,
    required this.onTap,
  });

  final PersonModel person;
  final VoidCallback onTap;

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    String lastActiveText = widget.person.lastLoginAt ?? 'Last in active';
    if (!lastActiveText.startsWith('Last') && !lastActiveText.startsWith('Invited')) {
      lastActiveText = 'Last in $lastActiveText';
    }

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: active ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1),
                  width: active ? 2.0 : 1.3,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.32),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    )
                  else ...const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x059333EA),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ],
              ),
              child: Row(
                children: [
                  // Left avatar user outline icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 28,
                      color: active
                          ? const Color(0xFF9333EA)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Middle Information Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Name + Status badge + (optional "You" badge)
                        Row(
                          children: [
                            Text(
                              widget.person.fullName,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Status Pill Badge
                            _buildStatusBadge(widget.person.status),

                            // "You" Tag Pill Badge
                            if (widget.person.isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Mail + Email, Shield + Role, Last active
                        Row(
                          children: [
                            // Email with Mail Icon
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.person.email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Role with Shield Icon
                            const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.person.roleDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Last Active Text
                            Text(
                              lastActiveText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Chevron Arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: active
                        ? const Color(0xFF9333EA)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bgColor = const Color(0xFFDCFCE7); // Soft mint green
        textColor = const Color(0xFF16A34A); // Forest green
        label = 'Active';
        break;
      case 'INVITED':
        bgColor = const Color(0xFFFEF3C7); // Soft amber
        textColor = const Color(0xFFD97706); // Dark amber
        label = 'Invited';
        break;
      case 'DISABLED':
      default:
        bgColor = const Color(0xFFF1F5F9); // Soft slate gray
        textColor = const Color(0xFF64748B); // Slate gray
        label = 'Disabled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

/// Empty state when no people match filter
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({required this.filter});

  final PeopleFilter filter;

  @override
  Widget build(BuildContext context) {
    String message = 'No people found';
    switch (filter) {
      case PeopleFilter.active:
        message = 'No active accounts found.';
        break;
      case PeopleFilter.invited:
        message = 'No invited accounts found.';
        break;
      case PeopleFilter.disabled:
        message = 'No disabled accounts found.';
        break;
      case PeopleFilter.all:
        message = 'No accounts found in your organization scope.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: const Color(0xFF9333EA).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF18181B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
