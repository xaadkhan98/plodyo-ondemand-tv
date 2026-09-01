import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import 'add_property_view.dart';

enum PropertyFilter {
  all,
  active,
  suspended,
}

/// Properties View with filter pills, "+ Add property" action, real API data, and interactive property cards.
class PropertiesView extends StatefulWidget {
  const PropertiesView({
    super.key,
    this.propertiesRepository,
    this.authRepository,
    this.initialIsAddingProperty = false,
    this.onPropertySelected,
  });

  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final bool initialIsAddingProperty;
  final ValueChanged<PropertyModel>? onPropertySelected;

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  PropertyFilter _selectedFilter = PropertyFilter.all;
  List<PropertyModel> _properties = [];
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isAddingProperty;

  @override
  void initState() {
    super.initState();
    _propertiesRepository = widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _isAddingProperty = widget.initialIsAddingProperty;
    _loadProperties();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case PropertyFilter.active:
        return 'ACTIVE';
      case PropertyFilter.suspended:
        return 'SUSPENDED';
      case PropertyFilter.all:
        return null;
    }
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final response = await _propertiesRepository.getProperties(
        accessToken: token,
        status: _apiStatusQuery,
      );

      if (mounted) {
        setState(() {
          _properties = response.data;
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

  void _onFilterChanged(PropertyFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadProperties();
    }
  }

  Future<void> _toggleSuspend(PropertyModel property) async {
    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      if (property.isActive) {
        await _propertiesRepository.suspendProperty(
          accessToken: token,
          propertyId: property.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property "${property.name}" suspended.'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _propertiesRepository.activateProperty(
          accessToken: token,
          propertyId: property.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property "${property.name}" activated.'),
              backgroundColor: const Color(0xFF15803D),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      _loadProperties();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating property status: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPropertyDetails(PropertyModel property) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF9333EA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                property.name,
                style: const TextStyle(
                  color: Color(0xFF18181B),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Status', property.status),
              const SizedBox(height: 8),
              if (property.city != null && property.city!.isNotEmpty) ...[
                _detailRow('City', property.city!),
                const SizedBox(height: 8),
              ],
              if (property.country != null && property.country!.isNotEmpty) ...[
                _detailRow('Country', property.country!),
                const SizedBox(height: 8),
              ],
              if (property.timezone != null && property.timezone!.isNotEmpty) ...[
                _detailRow('Timezone', property.timezone!),
                const SizedBox(height: 8),
              ],
              if (property.defaultLanguage != null && property.defaultLanguage!.isNotEmpty) ...[
                _detailRow('Default Language', property.defaultLanguage!),
                const SizedBox(height: 8),
              ],
              _detailRow('Created', property.createdAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: property.isActive ? const Color(0xFFDC2626) : const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _toggleSuspend(property);
            },
            child: Text(property.isActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFF71717A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF18181B),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingProperty) {
      return AddPropertyView(
        onPropertyCreated: (newProperty) {
          setState(() {
            _isAddingProperty = false;
          });
          _loadProperties();
        },
        onCancel: () {
          setState(() {
            _isAddingProperty = false;
          });
        },
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = screenWidth * 0.10;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Branding
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: PlodyoHeader(padding: EdgeInsets.only(bottom: 12)),
            ),

            // Main Section UI
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Title & Subtitle on Left, "+ Add property" on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title: "Properties"
                            const Text(
                              'Properties',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18181B),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle
                            const Text(
                              'The buildings and sites rooms are created under. Suspending one stops every room in it.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // "+ Add property" Pill Button
                      _AddPropertyButton(
                        onPressed: () {
                          setState(() {
                            _isAddingProperty = true;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Filter Pills Row (All, Active, Suspended)
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == PropertyFilter.all,
                        onTap: () => _onFilterChanged(PropertyFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Active',
                        isSelected: _selectedFilter == PropertyFilter.active,
                        onTap: () => _onFilterChanged(PropertyFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Suspended',
                        isSelected: _selectedFilter == PropertyFilter.suspended,
                        onTap: () => _onFilterChanged(PropertyFilter.suspended),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Loading, Error, or Properties List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
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
                              onPressed: _loadProperties,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_properties.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.inbox_outlined,
                              size: 38,
                              color: Color(0xFF71717A),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No properties yet.',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _properties.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return _PropertyCard(
                          property: property,
                          onTap: () {
                            widget.onPropertySelected?.call(property);
                            _showPropertyDetails(property);
                          },
                          onToggleSuspend: () => _toggleSuspend(property),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _AddPropertyButton extends StatefulWidget {
  const _AddPropertyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddPropertyButton> createState() => _AddPropertyButtonState();
}

class _AddPropertyButtonState extends State<_AddPropertyButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
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
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                border: active
                    ? Border.all(color: const Color(0xFFC084FC), width: 2.0)
                    : null,
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Add property',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
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
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xFF9333EA).withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : (active
                        ? const Color(0xFFC084FC)
                        : const Color(0xFFE4E4E7)),
                width: widget.isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else if (active)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : const Color(0xFF3F3F46),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatefulWidget {
  const _PropertyCard({
    required this.property,
    required this.onTap,
    required this.onToggleSuspend,
  });

  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onToggleSuspend;

  @override
  State<_PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<_PropertyCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    final locationParts = [
      if (widget.property.city != null && widget.property.city!.isNotEmpty) widget.property.city!,
      if (widget.property.country != null && widget.property.country!.isNotEmpty) widget.property.country!,
    ];
    final locationText = locationParts.isNotEmpty ? locationParts.join(', ') : 'Location not set';

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color(0xFFC084FC)
                    : const Color(0xFFF1EBF5),
                width: active ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.14),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Property Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_outlined,
                      size: 22,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Name, Status Badge, Location info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.property.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _PropertyStatusBadge(status: widget.property.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$locationText · Timezone: ${widget.property.timezone ?? "Default"}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF71717A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Toggle Suspend / Active Action Button
                TextButton(
                  onPressed: widget.onToggleSuspend,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.property.isActive
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF15803D),
                  ),
                  child: Text(
                    widget.property.isActive ? 'Suspend' : 'Activate',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA1A1AA),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyStatusBadge extends StatelessWidget {
  const _PropertyStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isActive ? 'Active' : 'Suspended',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}
