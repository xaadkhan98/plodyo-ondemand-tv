import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/languages.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

enum PropertyFormField {
  name,
  country,
  city,
  timezone,
}


/// "Add a property" full-screen view matching the exact Plodyo TV specification.
/// Features Partner Selection list, styled property inputs with active field indicator,
/// 18-Language selection grid with "Not set" option, Create/Cancel action buttons,
/// and an integrated 6-column on-screen TV virtual keyboard.
class AddPropertyView extends StatefulWidget {
  const AddPropertyView({
    super.key,
    this.propertiesRepository,
    this.partnersRepository,
    this.authRepository,
    this.onPropertyCreated,
    this.onCancel,
  });

  final PropertiesRepository? propertiesRepository;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final ValueChanged<PropertyModel>? onPropertyCreated;
  final VoidCallback? onCancel;

  @override
  State<AddPropertyView> createState() => _AddPropertyViewState();
}

class _AddPropertyViewState extends State<AddPropertyView> {
  late final PropertiesRepository _propertiesRepository;
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  PropertyFormField _activeField = PropertyFormField.name;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();

  List<PartnerModel> _availablePartners = [];
  String? _selectedPartnerId;
  String? _selectedLanguageCode; // null means "Not set"

  bool _isLoadingPartners = true;
  bool _isCreating = false;
  String? _errorMessage;

  // Blinking cursor state
  bool _showCursor = true;
  Timer? _cursorTimer;

  // Virtual keyboard state
  bool _isUpperCase = false;
  bool _showSymbols = false;


  @override
  void initState() {
    super.initState();
    _propertiesRepository =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    // Start cursor timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _nameController.addListener(_onTextChanged);
    _countryController.addListener(_onTextChanged);
    _cityController.addListener(_onTextChanged);
    _timezoneController.addListener(_onTextChanged);

    _loadPartners();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoadingPartners = true;
      _errorMessage = null;
    });

    final token = _authRepository.currentAuth?.accessToken ?? '';
    final actor = _authRepository.currentUser;

    try {
      final res = await _partnersRepository.getPartners(
        accessToken: token,
        status: 'ACTIVE',
      );
      _availablePartners = res.data;

      if (_availablePartners.isNotEmpty) {
        if (actor?.partnerId != null &&
            _availablePartners.any((p) => p.id == actor!.partnerId)) {
          _selectedPartnerId = actor!.partnerId;
        } else {
          _selectedPartnerId = _availablePartners.first.id;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingPartners = false;
      });
    }
  }

  TextEditingController get _activeController {
    switch (_activeField) {
      case PropertyFormField.name:
        return _nameController;
      case PropertyFormField.country:
        return _countryController;
      case PropertyFormField.city:
        return _cityController;
      case PropertyFormField.timezone:
        return _timezoneController;
    }
  }

  String get _activeFieldLabel {
    switch (_activeField) {
      case PropertyFormField.name:
        return 'Entering Property name';
      case PropertyFormField.country:
        return 'Entering Country';
      case PropertyFormField.city:
        return 'Entering City';
      case PropertyFormField.timezone:
        return 'Entering Timezone';
    }
  }

  void _handleVirtualKeyPress(String char) {
    final controller = _activeController;
    final text = controller.text;
    final selection = controller.selection;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, char);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
  }

  void _handleVirtualBackspace() {
    final controller = _activeController;
    final text = controller.text;
    final selection = controller.selection;

    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  void _handleVirtualSpace() {
    _handleVirtualKeyPress(' ');
  }

  void _handleVirtualClear() {
    _activeController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  void _handleNextField() {
    final values = PropertyFormField.values;
    final nextIndex = (_activeField.index + 1) % values.length;
    setState(() {
      _activeField = values[nextIndex];
    });
  }

  void _handlePrevField() {
    final values = PropertyFormField.values;
    final prevIndex =
        (_activeField.index - 1 + values.length) % values.length;
    setState(() {
      _activeField = values[prevIndex];
    });
  }

  void _handleBack() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/properties');
    }
  }

  Future<void> _handleCreateProperty() async {
    final name = _nameController.text.trim();
    final country = _countryController.text.trim();
    final city = _cityController.text.trim();
    final timezone = _timezoneController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Property name is required.';
        _activeField = PropertyFormField.name;
      });
      return;
    }

    if (_selectedPartnerId == null && _availablePartners.isNotEmpty) {
      _selectedPartnerId = _availablePartners.first.id;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final newProperty = await _propertiesRepository.createProperty(
        accessToken: token,
        partnerId: _selectedPartnerId ?? 'p-0',
        name: name,
        country: country.isNotEmpty ? country : null,
        city: city.isNotEmpty ? city : null,
        timezone: timezone.isNotEmpty ? timezone : null,
        defaultLanguage: _selectedLanguageCode,
      );

      if (mounted) {
        widget.onPropertyCreated?.call(newProperty);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property "$name" created successfully!'),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.escape) {
        _handleBack();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.tab) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _handlePrevField();
        } else {
          _handleNextField();
        }
        return KeyEventResult.handled;
      }

      // Handle direct character input from physical keyboard
      if (event.character != null && event.character!.isNotEmpty) {
        final char = event.character!;
        if (char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) != 127) {
          _handleVirtualKeyPress(char);
          return KeyEventResult.handled;
        }
      }

      if (key == LogicalKeyboardKey.backspace ||
          key == LogicalKeyboardKey.delete) {
        _handleVirtualBackspace();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.space) {
        _handleVirtualSpace();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(24.0, 56.0);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7FC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header (Sticky)
              Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 20,
                  bottom: 8,
                ),
                child: const PlodyoHeader(padding: EdgeInsets.zero),
              ),

              // Main 2-Column Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Form Content
                      Expanded(
                        flex: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: TvSectionBadge + Title + Subtitle
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TvSectionBadge(
                                  icon: Icons.add_home_work_rounded,
                                  gradientColors: [
                                    Color(0xFFF472B6),
                                    Color(0xFFD946EF),
                                    Color(0xFF9333EA),
                                  ],
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a property',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF18181B),
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'A property is one building or site. Rooms are created under it, and the room limit is shared across every property this partner owns.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Error Banner if present
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // SECTION 1: PARTNER SELECTION LIST
                            const Text(
                              'Partner',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoadingPartners)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF9333EA),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._availablePartners.map((partner) {
                                final isSelected =
                                    _selectedPartnerId == partner.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PartnerSelectCard(
                                    name: partner.name,
                                    subtitle: partner.contactEmail.isNotEmpty
                                        ? partner.contactEmail
                                        : 'partner@example.com',
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedPartnerId = partner.id;
                                      });
                                    },
                                  ),
                                );
                              }),
                            const SizedBox(height: 20),

                            // SECTION 2: INPUT FIELDS (Property name, Country, City, Timezone)
                            _PropertyInputField(
                              icon: Icons.account_balance_rounded,
                              label: 'Property name',
                              controller: _nameController,
                              isActive: _activeField == PropertyFormField.name,
                              showCursor: _showCursor,
                              onTap: () => setState(
                                  () => _activeField = PropertyFormField.name),
                            ),
                            const SizedBox(height: 14),

                            _PropertyInputField(
                              icon: Icons.public_rounded,
                              label: 'Country (optional)',
                              controller: _countryController,
                              isActive:
                                  _activeField == PropertyFormField.country,
                              showCursor: _showCursor,
                              onTap: () => setState(() =>
                                  _activeField = PropertyFormField.country),
                            ),
                            const SizedBox(height: 14),

                            _PropertyInputField(
                              icon: Icons.location_on_outlined,
                              label: 'City (optional)',
                              controller: _cityController,
                              isActive: _activeField == PropertyFormField.city,
                              showCursor: _showCursor,
                              onTap: () => setState(
                                  () => _activeField = PropertyFormField.city),
                            ),
                            const SizedBox(height: 14),

                            _PropertyInputField(
                              icon: Icons.public_rounded,
                              label: 'Timezone (optional)',
                              controller: _timezoneController,
                              isActive:
                                  _activeField == PropertyFormField.timezone,
                              showCursor: _showCursor,
                              onTap: () => setState(() =>
                                  _activeField = PropertyFormField.timezone),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 3: DEFAULT LANGUAGE (OPTIONAL)
                            const Row(
                              children: [
                                Icon(
                                  Icons.translate_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Default language (optional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // "Not set" full-width card
                            _NotSetLanguageCard(
                              isSelected: _selectedLanguageCode == null,
                              onTap: () {
                                setState(() {
                                  _selectedLanguageCode = null;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // 18 Languages Grid (4 columns)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    (constraints.maxWidth - (3 * 12)) / 4;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: languages.map((lang) {
                                    final isSelected =
                                        _selectedLanguageCode == lang.code;
                                    return SizedBox(
                                      width: cardWidth,
                                      child: _LanguageCard(
                                        language: lang,
                                        isSelected: isSelected,
                                        onTap: () {
                                          setState(() {
                                            _selectedLanguageCode = lang.code;
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // BOTTOM ACTION BUTTONS: [Create property]  [Cancel]
                            Row(
                              children: [
                                _CreatePropertyButton(
                                  isLoading: _isCreating,
                                  onPressed: _handleCreateProperty,
                                ),
                                const SizedBox(width: 16),
                                _CancelButton(
                                  onPressed: _handleBack,
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),

                      const SizedBox(width: 36),

                      // RIGHT COLUMN: Dedicated On-Screen TV Virtual Keyboard
                      SizedBox(
                        width: 380,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // "Entering Property name" Header
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16, right: 4),
                              child: Text(
                                _activeFieldLabel,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),

                            // 6-Column Virtual Keyboard
                            _DedicatedTvKeyboard(
                              isUpperCase: _isUpperCase,
                              showSymbols: _showSymbols,
                              onToggleCase: () {
                                setState(() {
                                  _isUpperCase = !_isUpperCase;
                                });
                              },
                              onToggleSymbols: () {
                                setState(() {
                                  _showSymbols = !_showSymbols;
                                });
                              },
                              onKeyPress: _handleVirtualKeyPress,
                              onBackspace: _handleVirtualBackspace,
                              onSpace: _handleVirtualSpace,
                              onClear: _handleVirtualClear,
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// Property Input Field Card (with active purple glow and blinking cursor)
class _PropertyInputField extends StatefulWidget {
  const _PropertyInputField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.isActive,
    required this.showCursor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isActive;
  final bool showCursor;
  final VoidCallback onTap;

  @override
  State<_PropertyInputField> createState() => _PropertyInputFieldState();
}

class _PropertyInputFieldState extends State<_PropertyInputField> {
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
    final isHighlighted = widget.isActive || _focusNode.hasFocus || _isHovered;
    final hasText = widget.controller.text.isNotEmpty;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isActive
                    ? const Color(0xFF8B5CF6)
                    : (isHighlighted
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFFCBD5E1)),
                width: widget.isActive ? 2.0 : 1.4,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Field Icon
                Icon(
                  widget.icon,
                  color: widget.isActive
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 14),

                // Label & Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (hasText)
                            Text(
                              widget.controller.text,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF18181B),
                                letterSpacing: 0.1,
                              ),
                            ),
                          if (widget.isActive && widget.showCursor)
                            Container(
                              margin:
                                  EdgeInsets.only(left: hasText ? 2.0 : 0.0),
                              width: 2,
                              height: 18,
                              color: const Color(0xFF8B5CF6),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Not set" Language Option Card (Full Width)
class _NotSetLanguageCard extends StatefulWidget {
  const _NotSetLanguageCard({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NotSetLanguageCard> createState() => _NotSetLanguageCardState();
}

class _NotSetLanguageCardState extends State<_NotSetLanguageCard> {
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
            scale: isHighlighted ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted
                        ? const Color(0xFFF8FAFC)
                        : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.4,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Not set',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF18181B),
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 20,
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

/// Single Language Grid Card (Flag + Language Name)
class _LanguageCard extends StatefulWidget {
  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
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
            scale: isHighlighted ? 1.025 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted
                        ? const Color(0xFFF8FAFC)
                        : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.4,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LanguageFlag(code: widget.language.code),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.language.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF18181B),
                      ),
                      overflow: TextOverflow.ellipsis,
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

/// Partner Selectable Item Card
class _PartnerSelectCard extends StatefulWidget {
  const _PartnerSelectCard({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PartnerSelectCard> createState() => _PartnerSelectCardState();
}

class _PartnerSelectCardState extends State<_PartnerSelectCard> {
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
            scale: isHighlighted ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted
                        ? const Color(0xFFF8FAFC)
                        : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.4,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Building Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? const Color(0xFFEDE9FE)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 20,
                      color: widget.isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtle indicator if selected
                  if (widget.isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 20,
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

/// "Create property" Gradient Pill Button
class _CreatePropertyButton extends StatefulWidget {
  const _CreatePropertyButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_CreatePropertyButton> createState() => _CreatePropertyButtonState();
}

class _CreatePropertyButtonState extends State<_CreatePropertyButton> {
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
        if (!widget.isLoading) {
          widget.onPressed();
        }
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
        cursor: widget.isLoading
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
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
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA)
                        .withValues(alpha: isHighlighted ? 0.5 : 0.35),
                    blurRadius: isHighlighted ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Creating property',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        SizedBox(width: 8),
                        PlodyoThreeDotsLoading(
                          dotSize: 5,
                          spacing: 3.5,
                          bounceHeight: 4,
                          color: Colors.white,
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Create property',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
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

/// "Cancel" Outline Pill Button
class _CancelButton extends StatefulWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFF8B5CF6),
                  width: 1.5,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF18181B),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
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

/// 6-Column On-Screen TV Virtual Keyboard matching design screenshot
class _DedicatedTvKeyboard extends StatelessWidget {
  const _DedicatedTvKeyboard({
    required this.isUpperCase,
    required this.showSymbols,
    required this.onToggleCase,
    required this.onToggleSymbols,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onSpace,
    required this.onClear,
  });

  final bool isUpperCase;
  final bool showSymbols;
  final VoidCallback onToggleCase;
  final VoidCallback onToggleSymbols;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback onClear;

  List<List<String>> get _standardRows => [
        ['a', 'b', 'c', 'd', 'e', 'f'],
        ['g', 'h', 'i', 'j', 'k', 'l'],
        ['m', 'n', 'o', 'p', 'q', 'r'],
        ['s', 't', 'u', 'v', 'w', 'x'],
        ['y', 'z', '0', '1', '2', '3'],
        ['4', '5', '6', '7', '8', '9'],
        ['-', '.', '\''],
      ];

  List<List<String>> get _symbolsRows => [
        ['!', '@', '#', '\$', '%', '^'],
        ['&', '*', '(', ')', '_', '+'],
        ['[', ']', '{', '}', ';', ':'],
        ['\'', '"', ',', '.', '/', '?'],
        ['~', '`', '<', '>', '=', '\\'],
        ['4', '5', '6', '7', '8', '9'],
        ['-', '.', '\''],
      ];

  @override
  Widget build(BuildContext context) {
    final rows = showSymbols ? _symbolsRows : _standardRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Rows 1 to 7
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((char) {
                final displayChar = isUpperCase ? char.toUpperCase() : char;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _KeyButton(
                    label: displayChar,
                    width: 44,
                    height: 44,
                    onPressed: () => onKeyPress(displayChar),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom Action Keys Row: [↑ abc] [!#?] [—] [⌫] [Clear]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shift / Case toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: isUpperCase ? '↑ ABC' : '↑ abc',
                width: 58,
                height: 44,
                fontSize: 12,
                onPressed: onToggleCase,
              ),
            ),

            // Symbols Toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: showSymbols ? 'ABC' : '!#?',
                isActive: showSymbols,
                width: 48,
                height: 44,
                fontSize: 12,
                onPressed: onToggleSymbols,
              ),
            ),

            // Space key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: '—',
                width: 44,
                height: 44,
                fontSize: 15,
                onPressed: onSpace,
              ),
            ),

            // Backspace key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                width: 44,
                height: 44,
                onPressed: onBackspace,
              ),
            ),

            // Clear key
            _KeyButton(
              label: 'Clear',
              width: 54,
              height: 44,
              fontSize: 12,
              onPressed: onClear,
            ),
          ],
        ),
      ],
    );
  }
}

/// Single Key Button on TV Keyboard with hover & focus glow effects
class _KeyButton extends StatefulWidget {
  const _KeyButton({
    this.label,
    this.icon,
    this.width = 44,
    this.height = 44,
    this.fontSize = 15,
    this.isActive = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
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
    final isHighlighted = _focusNode.hasFocus || _isHovered || widget.isActive;

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
            scale: isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFD946EF),
                          Color(0xFF9333EA),
                        ],
                      )
                    : null,
                color: isHighlighted ? null : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: isHighlighted
                    ? null
                    : Border.all(
                        color: const Color(0xFFE4E4E7),
                        width: 1.0,
                      ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD946EF).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: Center(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 18,
                        color: isHighlighted
                            ? Colors.white
                            : const Color(0xFF27272A),
                      )
                    : Text(
                        widget.label ?? '',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight:
                              isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          color: isHighlighted
                              ? Colors.white
                              : const Color(0xFF18181B),
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
