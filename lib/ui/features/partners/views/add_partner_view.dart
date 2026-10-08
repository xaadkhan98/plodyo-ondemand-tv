import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';

enum AddPartnerField {
  venueName,
  contactEmail,
  contactName,
  phone,
  contractReference,
}

/// "Add a Partner" full-screen view matching the exact Plodyo TV specification.
/// Features 3-card Business Type selector, 5 styled inputs with active field indicator,
/// Room limit stepper controls, Create/Cancel action buttons, and an integrated
/// 6-column on-screen TV virtual keyboard.
class AddPartnerView extends StatefulWidget {
  const AddPartnerView({
    super.key,
    this.partnersRepository,
    this.authRepository,
    this.onBack,
    this.onPartnerCreated,
  });

  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final ValueChanged<PartnerModel>? onPartnerCreated;

  @override
  State<AddPartnerView> createState() => _AddPartnerViewState();
}

class _AddPartnerViewState extends State<AddPartnerView> {
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  String _selectedBusinessType = 'CHAIN'; // CHAIN, INDEPENDENT, HOST
  AddPartnerField _activeField = AddPartnerField.venueName;

  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contractRefController = TextEditingController();

  int _roomLimit = 0;
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
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    // Start cursor blink timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    // Listeners for controllers to trigger rebuilds
    _venueNameController.addListener(_onTextChanged);
    _contactEmailController.addListener(_onTextChanged);
    _contactNameController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _contractRefController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _venueNameController.dispose();
    _contactEmailController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _contractRefController.dispose();
    super.dispose();
  }

  TextEditingController get _activeController {
    switch (_activeField) {
      case AddPartnerField.venueName:
        return _venueNameController;
      case AddPartnerField.contactEmail:
        return _contactEmailController;
      case AddPartnerField.contactName:
        return _contactNameController;
      case AddPartnerField.phone:
        return _phoneController;
      case AddPartnerField.contractReference:
        return _contractRefController;
    }
  }

  String get _activeFieldLabel {
    switch (_activeField) {
      case AddPartnerField.venueName:
        return 'Venue name';
      case AddPartnerField.contactEmail:
        return 'Contact email';
      case AddPartnerField.contactName:
        return 'Contact name';
      case AddPartnerField.phone:
        return 'Phone';
      case AddPartnerField.contractReference:
        return 'Contract reference';
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
    final controller = _activeController;
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  void _handleNextField() {
    final values = AddPartnerField.values;
    final nextIndex = (_activeField.index + 1) % values.length;
    setState(() {
      _activeField = values[nextIndex];
    });
  }

  void _handlePrevField() {
    final values = AddPartnerField.values;
    final prevIndex = (_activeField.index - 1 + values.length) % values.length;
    setState(() {
      _activeField = values[prevIndex];
    });
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/partners');
    }
  }

  Future<void> _handleCreatePartner() async {
    final venueName = _venueNameController.text.trim();
    final contactEmail = _contactEmailController.text.trim();
    final contactName = _contactNameController.text.trim();
    final phone = _phoneController.text.trim();
    final contractRef = _contractRefController.text.trim();

    if (venueName.isEmpty) {
      setState(() {
        _errorMessage = 'Venue name is required.';
        _activeField = AddPartnerField.venueName;
      });
      return;
    }

    if (contactEmail.isEmpty || !contactEmail.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid contact email.';
        _activeField = AddPartnerField.contactEmail;
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final newPartner = await _partnersRepository.createPartner(
        accessToken: token,
        name: venueName,
        partnerType: _selectedBusinessType,
        contactEmail: contactEmail,
        contactName: contactName.isNotEmpty ? contactName : null,
        phone: phone.isNotEmpty ? phone : null,
        contractReference: contractRef.isNotEmpty ? contractRef : null,
        roomLimit: _roomLimit,
      );

      if (mounted) {
        widget.onPartnerCreated?.call(newPartner);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partner "$venueName" onboarded successfully!'),
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

      if (key == LogicalKeyboardKey.tab) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _handlePrevField();
        } else {
          _handleNextField();
        }
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowDown &&
          HardwareKeyboard.instance.isMetaPressed) {
        _handleNextField();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowUp &&
          HardwareKeyboard.instance.isMetaPressed) {
        _handlePrevField();
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

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_activeField == AddPartnerField.contractReference) {
          _handleCreatePartner();
        } else {
          _handleNextField();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7FC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Plodyo Logo Header (Sticky)
              const Padding(
                padding: EdgeInsets.only(
                  left: 48,
                  right: 48,
                  top: 20,
                  bottom: 8,
                ),
                child: PlodyoHeader(padding: EdgeInsets.zero),
              ),

              // Main Scrollable Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Form + Controls + Actions
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
                                  icon: Icons.business_rounded,
                                  gradientColors: [
                                    Color(0xFFF472B6),
                                    Color(0xFFD946EF),
                                    Color(0xFF9333EA),
                                  ],
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a partner',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF18181B),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Onboards a venue that is not going through the public registration form. It is active straight away, and no invite is sent \u2014 invite the first partner admin separately.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14.5,
                                          color: const Color(0xFF64748B),
                                          height: 1.45,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Business Type Section Label
                            Text(
                              'Business type',
                              style: GoogleFonts.nunito(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Business Type 3 Cards Row
                            Row(
                              children: [
                                Expanded(
                                  child: _BusinessTypeCard(
                                    title: 'Chain',
                                    description:
                                        'Several venues under one contract. Cannot self-register.',
                                    isSelected:
                                        _selectedBusinessType == 'CHAIN',
                                    onTap: () {
                                      setState(() {
                                        _selectedBusinessType = 'CHAIN';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _BusinessTypeCard(
                                    title: 'Independent',
                                    description:
                                        'A single hotel or guest house.',
                                    isSelected:
                                        _selectedBusinessType == 'INDEPENDENT',
                                    onTap: () {
                                      setState(() {
                                        _selectedBusinessType = 'INDEPENDENT';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _BusinessTypeCard(
                                    title: 'Host',
                                    description:
                                        'A short-let host with a handful of rooms.',
                                    isSelected: _selectedBusinessType == 'HOST',
                                    onTap: () {
                                      setState(() {
                                        _selectedBusinessType = 'HOST';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Error Banner if present
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF87171),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 5 Styled Form Fields
                            _FormInputField(
                              icon: Icons.apartment_rounded,
                              label: 'Venue name',
                              hint: 'Grand Hotel Group',
                              controller: _venueNameController,
                              isActive:
                                  _activeField == AddPartnerField.venueName,
                              showCursor: _showCursor,
                              onTap: () {
                                setState(() {
                                  _activeField = AddPartnerField.venueName;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            _FormInputField(
                              icon: Icons.mail_outline_rounded,
                              label: 'Contact email',
                              hint: 'ops@grandhotelgroup.com',
                              controller: _contactEmailController,
                              isActive:
                                  _activeField == AddPartnerField.contactEmail,
                              showCursor: _showCursor,
                              onTap: () {
                                setState(() {
                                  _activeField = AddPartnerField.contactEmail;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            _FormInputField(
                              icon: Icons.person_outline_rounded,
                              label: 'Contact name (optional)',
                              hint: 'Jordan Lee',
                              controller: _contactNameController,
                              isActive:
                                  _activeField == AddPartnerField.contactName,
                              showCursor: _showCursor,
                              onTap: () {
                                setState(() {
                                  _activeField = AddPartnerField.contactName;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            _FormInputField(
                              icon: Icons.phone_outlined,
                              label: 'Phone (optional)',
                              hint: '+1-555-0100',
                              controller: _phoneController,
                              isActive: _activeField == AddPartnerField.phone,
                              showCursor: _showCursor,
                              onTap: () {
                                setState(() {
                                  _activeField = AddPartnerField.phone;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            _FormInputField(
                              icon: Icons.description_outlined,
                              label: 'Contract reference (optional)',
                              hint: 'CTR-2026-0142',
                              controller: _contractRefController,
                              isActive:
                                  _activeField ==
                                  AddPartnerField.contractReference,
                              showCursor: _showCursor,
                              onTap: () {
                                setState(() {
                                  _activeField =
                                      AddPartnerField.contractReference;
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // Room limit Section
                            const Text(
                              'Room limit',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Room limit Stepper Row: [-10] [-] [0 rooms] [+] [+10]
                            Row(
                              children: [
                                _StepperButton(
                                  label: '- 10',
                                  onPressed: () {
                                    setState(() {
                                      _roomLimit = (_roomLimit - 10).clamp(
                                        0,
                                        9999,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _StepperButton(
                                  label: '—',
                                  onPressed: () {
                                    setState(() {
                                      _roomLimit = (_roomLimit - 1).clamp(
                                        0,
                                        9999,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF1E293B),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$_roomLimit',
                                          style: const TextStyle(
                                            color: Color(0xFF18181B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' rooms',
                                          style: TextStyle(
                                            color: Color(0xFF18181B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StepperButton(
                                  label: '+',
                                  onPressed: () {
                                    setState(() {
                                      _roomLimit = (_roomLimit + 1).clamp(
                                        0,
                                        9999,
                                      );
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _StepperButton(
                                  label: '+ 10',
                                  onPressed: () {
                                    setState(() {
                                      _roomLimit = (_roomLimit + 10).clamp(
                                        0,
                                        9999,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Caption below room limit
                            const Text(
                              'At 0 no room can be created, so a TV cannot be signed in. It can be raised later from the partner\u2019s own screen.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Bottom Action Buttons: [Create partner] [Cancel]
                            Row(
                              children: [
                                // Create Partner Primary Gradient Pill Button
                                _CreatePartnerButton(
                                  isLoading: _isCreating,
                                  onPressed: _handleCreatePartner,
                                ),
                                const SizedBox(width: 14),

                                // Cancel Outline Pill Button
                                _CancelButton(onPressed: _handleBack),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),

                      const SizedBox(width: 48),

                      // RIGHT COLUMN: Dedicated On-Screen TV Virtual Keyboard
                      SizedBox(
                        width: 380,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Active Field Indicator Header
                            Text(
                              'Entering $_activeFieldLabel',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // TV Keyboard Grid
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

/// Business Type Selector Card (Chain, Independent, Host)
class _BusinessTypeCard extends StatefulWidget {
  const _BusinessTypeCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_BusinessTypeCard> createState() => _BusinessTypeCardState();
}

class _BusinessTypeCardState extends State<_BusinessTypeCard> {
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
    final isFocused = _focusNode.hasFocus;
    final isHighlighted = isFocused || _isHovered;

    final borderColor = widget.isSelected
        ? const Color(0xFF8B5CF6)
        : (isHighlighted ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1));

    final borderWidth = widget.isSelected ? 1.8 : 1.0;
    final backgroundColor = widget.isSelected
        ? const Color(0xFFFAF5FF)
        : Colors.white;

    final titleColor = widget.isSelected
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF18181B);

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
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
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

/// Custom Styled Form Input Field Box with Icon, Label, Value/Placeholder, and Blinking Cursor
class _FormInputField extends StatelessWidget {
  const _FormInputField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.isActive,
    required this.showCursor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isActive;
  final bool showCursor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final hasText = text.isNotEmpty;

    final borderColor = isActive
        ? const Color(0xFF8B5CF6)
        : const Color(0xFFCBD5E1);
    final borderWidth = isActive ? 1.8 : 1.0;
    final iconColor = isActive
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF64748B);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
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
          child: Row(
            children: [
              // Left Icon
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),

              // Text Content Column: Label at top, Value/Hint at bottom
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasText ? text : hint,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: hasText
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: hasText
                                  ? const Color(0xFF18181B)
                                  : const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Opacity(
                            opacity: showCursor ? 1.0 : 0.0,
                            child: Container(
                              margin: const EdgeInsets.only(left: 2),
                              width: 1.8,
                              height: 16,
                              color: const Color(0xFF8B5CF6),
                            ),
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
    );
  }
}

/// Stepper Button ([-10], [-], [+], [+10])
class _StepperButton extends StatefulWidget {
  const _StepperButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
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
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFF3E8FF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF475569),
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

/// "Create partner" Primary Gradient Pill Button
class _CreatePartnerButton extends StatefulWidget {
  const _CreatePartnerButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_CreatePartnerButton> createState() => _CreatePartnerButtonState();
}

class _CreatePartnerButtonState extends State<_CreatePartnerButton> {
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
                  colors: [Color(0xFFD946EF), Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF9333EA,
                    ).withValues(alpha: isHighlighted ? 0.5 : 0.35),
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
                          'Creating partner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        SizedBox(width: 8),
                        LoadingDots(color: Colors.white),
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
                          'Create partner',
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
                border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.25),
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
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
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
                        colors: [Color(0xFFD946EF), Color(0xFF9333EA)],
                      )
                    : null,
                color: isHighlighted ? null : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: isHighlighted
                    ? null
                    : Border.all(color: const Color(0xFFE4E4E7), width: 1.0),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFD946EF,
                          ).withValues(alpha: 0.45),
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
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w500,
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
