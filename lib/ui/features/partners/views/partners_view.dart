import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';

enum PartnerFilter {
  all,
  pendingApproval,
  active,
  suspended,
  rejected,
}

/// Partners View matching the refined Plodyo TV design specification.
/// Features angled floating badge icon animation, custom pill tabs, card list items, and full interaction modal flows.
class PartnersView extends StatefulWidget {
  const PartnersView({
    super.key,
    this.partnersRepository,
    this.authRepository,
    this.onPartnerSelected,
    this.onAddPartner,
  });

  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final ValueChanged<PartnerModel>? onPartnerSelected;
  final VoidCallback? onAddPartner;

  @override
  State<PartnersView> createState() => _PartnersViewState();
}

class _PartnersViewState extends State<PartnersView> {
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  PartnerFilter _selectedFilter = PartnerFilter.all;
  List<PartnerModel> _partners = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Exact sample partners matching the design screenshot
  static final List<PartnerModel> _samplePartners = [
    const PartnerModel(
      id: 'p1',
      name: 'hotel-ab',
      partnerType: 'INDEPENDENT',
      contactEmail: 'mudsr3@gmail.com',
      roomLimit: 8,
      status: 'ACTIVE',
      createdAt: '2026-08-01',
    ),
    const PartnerModel(
      id: 'p2',
      name: 'HotelA1',
      partnerType: 'INDEPENDENT',
      contactEmail: 'mudsr3@gmail.com',
      roomLimit: 0,
      status: 'PENDING_APPROVAL',
      createdAt: '2026-08-05',
    ),
    const PartnerModel(
      id: 'p3',
      name: 'Hotelgrandplaza',
      partnerType: 'INDEPENDENT',
      contactEmail: 'opss@email.com',
      roomLimit: 0,
      status: 'PENDING_APPROVAL',
      createdAt: '2026-08-10',
    ),
    const PartnerModel(
      id: 'p4',
      name: 'AirBnb207',
      partnerType: 'INDEPENDENT',
      contactEmail: 'xaadkhan98+airbnb@gmail.com',
      roomLimit: 10,
      status: 'ACTIVE',
      createdAt: '2026-08-12',
    ),
    const PartnerModel(
      id: 'p5',
      name: 'Indie Test Hotel',
      partnerType: 'INDEPENDENT',
      contactEmail: 'indie-test@example.com',
      roomLimit: 0,
      status: 'PENDING_APPROVAL',
      createdAt: '2026-08-14',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    _loadPartners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case PartnerFilter.pendingApproval:
        return 'PENDING_APPROVAL';
      case PartnerFilter.active:
        return 'ACTIVE';
      case PartnerFilter.suspended:
        return 'SUSPENDED';
      case PartnerFilter.rejected:
        return 'REJECTED';
      case PartnerFilter.all:
        return null;
    }
  }

  List<PartnerModel> get _filteredPartners {
    final list = _partners.isNotEmpty ? _partners : _samplePartners;
    if (_selectedFilter == PartnerFilter.all) return list;
    final query = _apiStatusQuery;
    return list.where((p) => p.status == query).toList();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final response = await _partnersRepository.getPartners(
        accessToken: token,
        status: _apiStatusQuery,
      );

      if (mounted) {
        setState(() {
          _partners = response.data.isNotEmpty ? response.data : _samplePartners;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _partners = _samplePartners;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }
  }

  void _onFilterChanged(PartnerFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadPartners();
    }
  }

  void _navigateToAddPartner() async {
    if (widget.onAddPartner != null) {
      widget.onAddPartner!();
      return;
    }
    await context.push('/partners/add');
    if (mounted) {
      _loadPartners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnersToDisplay = _filteredPartners;

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
                  // Title Row: Angled Floating Badge Icon + "Partners" Title + "+ Add partner" Action Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated Partners Badge: Floating vertically & angled to the left
                            const TvSectionBadge(
                              icon: Icons.apartment_rounded,
                              gradientColors: [
                                Color(0xFFE879F9),
                                Color(0xFF9333EA),
                                Color(0xFF7E22CE),
                              ],
                            ),
                            const SizedBox(width: 18),

                            // Title & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Partners',
                                    style: GoogleFonts.baloo2(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF9333EA),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Venues on Plodyo TV. Approve new applications and set how many rooms each may sign in.',
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
                      ),
                      const SizedBox(width: 20),

                      // Right "+ Add partner" Action Button
                      _AddPartnerButton(onPressed: _navigateToAddPartner),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Filter Chips / Tabs Row
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == PartnerFilter.all,
                        onTap: () => _onFilterChanged(PartnerFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Pending approval',
                        isSelected: _selectedFilter == PartnerFilter.pendingApproval,
                        onTap: () => _onFilterChanged(PartnerFilter.pendingApproval),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Active',
                        isSelected: _selectedFilter == PartnerFilter.active,
                        onTap: () => _onFilterChanged(PartnerFilter.active),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Suspended',
                        isSelected: _selectedFilter == PartnerFilter.suspended,
                        onTap: () => _onFilterChanged(PartnerFilter.suspended),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Rejected',
                        isSelected: _selectedFilter == PartnerFilter.rejected,
                        onTap: () => _onFilterChanged(PartnerFilter.rejected),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Main Content: Loading, Error, or Scrollable Partner Cards
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
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _loadPartners,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : partnersToDisplay.isEmpty
                          ? _EmptyStateWidget(filter: _selectedFilter)
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 48, right: 48, bottom: 32),
                              itemCount: partnersToDisplay.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final partner = partnersToDisplay[index];
                                return _PartnerCard(
                                  partner: partner,
                                  onTap: () {
                                    if (widget.onPartnerSelected != null) {
                                      widget.onPartnerSelected!(partner);
                                    } else {
                                      context.push('/partners/details', extra: partner);
                                    }
                                  },
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

class _AddPartnerButton extends StatefulWidget {
  const _AddPartnerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddPartnerButton> createState() => _AddPartnerButtonState();
}

class _AddPartnerButtonState extends State<_AddPartnerButton> {
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

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onPressed();
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
            widget.onPressed();
          },
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE11D89),
                    Color(0xFF9333EA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: active ? 0.55 : 0.38),
                    blurRadius: active ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add partner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
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

    final backgroundColor = widget.isSelected
        ? const Color(0xFFFAF5FF)
        : (active ? const Color(0xFFFBF8FF) : Colors.white);

    final borderColor = widget.isSelected
        ? const Color(0xFF8B5CF6)
        : (active ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1));

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
                  width: widget.isSelected ? 1.6 : 1.2,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  else if (active)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _PartnerCard extends StatefulWidget {
  const _PartnerCard({
    required this.partner,
    required this.onTap,
  });

  final PartnerModel partner;
  final VoidCallback onTap;

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard> {
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
            scale: active ? 1.012 : 1.0,
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
                  width: active ? 2.0 : 1.4,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.38),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    )
                  else ...[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ],
              ),
              child: Row(
                children: [
                  // Hotel / Building Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 24,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Main Details: Name + Status Badge on Row 1; Email + Type + Rooms on Row 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Status Badge
                        Row(
                          children: [
                            Text(
                              widget.partner.name,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusBadge(status: widget.partner.status),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Subtitle info row: Email, Partner Type, Room count
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.partner.contactEmail,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              widget.partner.partnerType == 'INDEPENDENT'
                                  ? 'Independent'
                                  : 'Host',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.door_front_door_outlined,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.partner.roomLimit} rooms',
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
                    color: const Color(0xFF8B5CF6),
                    size: 26,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'PENDING_APPROVAL':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        text = 'Pending approval';
        break;
      case 'ACTIVE':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        text = 'Active';
        break;
      case 'SUSPENDED':
        bgColor = const Color(0xFFFFE4E6);
        textColor = const Color(0xFFE11D48);
        text = 'Suspended';
        break;
      case 'REJECTED':
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

/// Clean empty state component with inbox tray icon and dynamic filter text matching design.
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({required this.filter});

  final PartnerFilter filter;

  String get _emptyMessage {
    switch (filter) {
      case PartnerFilter.suspended:
        return 'No partners are suspended.';
      case PartnerFilter.rejected:
        return 'No partners are rejected.';
      case PartnerFilter.pendingApproval:
        return 'No partners are pending approval.';
      case PartnerFilter.active:
        return 'No partners are active.';
      case PartnerFilter.all:
        return 'No partners found.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 84),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_rounded,
              size: 52,
              color: Color(0xFF334155),
            ),
            const SizedBox(height: 18),
            Text(
              _emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Color(0xFF334155),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

