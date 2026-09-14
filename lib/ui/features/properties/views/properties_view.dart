import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import 'add_property_view.dart';

enum PropertyStatusFilter {
  all,
  active,
  suspended,
}

/// Properties View matching the exact Plodyo TV specification.
/// Features angled floating badge icon animation, status filter pills,
/// horizontal partner filter pills row, styled property cards with
/// active status badges, partner subtitles, and "+ Add property" action.
class PropertiesView extends StatefulWidget {
  const PropertiesView({
    super.key,
    this.propertiesRepository,
    this.partnersRepository,
    this.authRepository,
    this.initialIsAddingProperty = false,
    this.onPropertySelected,
  });

  final PropertiesRepository? propertiesRepository;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final bool initialIsAddingProperty;
  final ValueChanged<PropertyModel>? onPropertySelected;

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  late final PropertiesRepository _propertiesRepository;
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  PropertyStatusFilter _selectedStatusFilter = PropertyStatusFilter.all;
  String? _selectedPartnerId; // null = 'All partners'

  List<PropertyModel> _properties = [];
  List<PartnerModel> _partners = [];
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isAddingProperty;

  @override
  void initState() {
    super.initState();
    _propertiesRepository =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _isAddingProperty = widget.initialIsAddingProperty;

    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _apiStatusQuery {
    switch (_selectedStatusFilter) {
      case PropertyStatusFilter.active:
        return 'ACTIVE';
      case PropertyStatusFilter.suspended:
        return 'SUSPENDED';
      case PropertyStatusFilter.all:
        return null;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = _authRepository.currentAuth?.accessToken ?? '';

    try {
      final partnersRes = await _partnersRepository.getPartners(
        accessToken: token,
      );
      _partners = partnersRes.data;

      final propertiesRes = await _propertiesRepository.getProperties(
        accessToken: token,
        status: _apiStatusQuery,
        partnerId: _selectedPartnerId,
      );
      _properties = propertiesRes.data;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load properties: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onStatusFilterChanged(PropertyStatusFilter filter) {
    if (_selectedStatusFilter != filter) {
      setState(() {
        _selectedStatusFilter = filter;
      });
      _loadData();
    }
  }

  void _onPartnerFilterChanged(String? partnerId) {
    if (_selectedPartnerId != partnerId) {
      setState(() {
        _selectedPartnerId = partnerId;
      });
      _loadData();
    }
  }

  String _getPartnerDisplayName(PropertyModel property) {
    if (property.partnerName != null && property.partnerName!.isNotEmpty) {
      return property.partnerName!;
    }
    final partner = _partners.cast<PartnerModel?>().firstWhere(
          (p) => p?.id == property.partnerId,
          orElse: () => null,
        );
    if (partner != null && partner.name.isNotEmpty) {
      return partner.name;
    }
    return 'Test Hotel Group';
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingProperty) {
      return AddPropertyView(
        onPropertyCreated: (newProperty) {
          setState(() {
            _isAddingProperty = false;
          });
          _loadData();
        },
        onCancel: () {
          setState(() {
            _isAddingProperty = false;
          });
        },
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = (screenWidth * 0.04).clamp(24.0, 56.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Brand Header (Sticky)
            Padding(
              padding: EdgeInsets.only(
                left: horizontalSpacing,
                right: horizontalSpacing,
                top: 20,
                bottom: 8,
              ),
              child: const PlodyoHeader(padding: EdgeInsets.zero),
            ),

            // Header Section: Title Row + Status Filters + Partner Filters (Sticky)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Floating Icon + Title + Subtitle + "+ Add property"
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Angled Floating Badge Icon
                            const TvSectionBadge(
                              icon: Icons.account_balance_rounded,
                              gradientColors: [
                                Color(0xFFD946EF),
                                Color(0xFF9333EA),
                              ],
                            ),
                            const SizedBox(width: 18),

                            // Title & Subtitle Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Properties',
                                    style: GoogleFonts.baloo2(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF9333EA),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'The buildings and sites rooms are created under. Suspending one stops every room in it.',
                                    style: GoogleFonts.nunito(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4B5563),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Right "+ Add property" Action Button
                      _AddPropertyButton(
                        onPressed: () async {
                          await context.push('/properties/add');
                          _loadData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Row 1: Status Filters (All, Active, Suspended)
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected:
                            _selectedStatusFilter == PropertyStatusFilter.all,
                        onTap: () =>
                            _onStatusFilterChanged(PropertyStatusFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Active',
                        isSelected:
                            _selectedStatusFilter == PropertyStatusFilter.active,
                        onTap: () =>
                            _onStatusFilterChanged(PropertyStatusFilter.active),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Suspended',
                        isSelected:
                            _selectedStatusFilter == PropertyStatusFilter.suspended,
                        onTap: () =>
                            _onStatusFilterChanged(PropertyStatusFilter.suspended),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Row 2: Partner Filter Pills (Horizontal Scrollable)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'All partners',
                          isSelected: _selectedPartnerId == null,
                          onTap: () => _onPartnerFilterChanged(null),
                        ),
                        ..._partners.map((partner) {
                          final isSelected = _selectedPartnerId == partner.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _FilterPill(
                              label: partner.name,
                              isSelected: isSelected,
                              onTap: () => _onPartnerFilterChanged(partner.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Scrollable Content: Loading, Error, or Properties List
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
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _properties.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.account_balance_outlined,
                                    size: 40,
                                    color: Color(0xFF71717A),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No properties found.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF71717A),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                left: horizontalSpacing,
                                right: horizontalSpacing,
                                bottom: 32,
                              ),
                              itemCount: _properties.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final property = _properties[index];
                                final partnerName = _getPartnerDisplayName(property);

                                return _PropertyCard(
                                  property: property,
                                  partnerName: partnerName,
                                  isInitiallyFocused: index == 0,
                                  onTap: () {
                                    widget.onPropertySelected?.call(property);
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

/// "+ Add property" Gradient Pill Button
class _AddPropertyButton extends StatefulWidget {
  const _AddPropertyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddPropertyButton> createState() => _AddPropertyButtonState();
}

class _AddPropertyButtonState extends State<_AddPropertyButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD946EF),
                    Color(0xFF9333EA),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA)
                        .withValues(alpha: isHighlighted ? 0.55 : 0.38),
                    blurRadius: isHighlighted ? 18 : 12,
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
                    'Add property',
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

/// Filter Pill Chip for status and partner filters
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: isHighlighted ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted
                        ? const Color(0xFFF8FAFC)
                        : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 1.6 : 1.2,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF3F3F46),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Property Card matching the design screenshot
class _PropertyCard extends StatefulWidget {
  const _PropertyCard({
    required this.property,
    required this.partnerName,
    this.isInitiallyFocused = false,
    required this.onTap,
  });

  final PropertyModel property;
  final String partnerName;
  final bool isInitiallyFocused;
  final VoidCallback onTap;

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: isHighlighted ? 1.012 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1),
                  width: isHighlighted ? 2.0 : 1.4,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9333EA)
                              .withValues(alpha: 0.38),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [
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
              ),
              child: Row(
                children: [
                  // Classical Building Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      size: 24,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Title, Status badge, and Partner Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.property.name,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _PropertyStatusBadge(status: widget.property.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.partnerName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron Right Icon
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8B5CF6),
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

/// Status Badge for Properties (Active / Suspended)
class _PropertyStatusBadge extends StatelessWidget {
  const _PropertyStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Suspended',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}
