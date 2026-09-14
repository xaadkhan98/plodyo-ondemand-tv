import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/tv_keyboard.dart';

enum ActiveVenueField {
  businessName,
  contactEmail,
  contactName,
  phone,
}

/// Screen for registering a new venue on TV with TV remote / D-pad support.
class RegisterVenueView extends StatefulWidget {
  const RegisterVenueView({
    super.key,
    this.authRepository,
    this.onBack,
  });

  final AuthRepository? authRepository;
  final VoidCallback? onBack;

  @override
  State<RegisterVenueView> createState() => _RegisterVenueViewState();
}

class _RegisterVenueViewState extends State<RegisterVenueView> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _hotelCardFocusNode = FocusNode();
  final FocusNode _shortLetCardFocusNode = FocusNode();
  final FocusNode _businessNameFocusNode = FocusNode();
  final FocusNode _contactEmailFocusNode = FocusNode();
  final FocusNode _contactNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _submitButtonFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();

  late final AuthRepository _authRepository;

  // Selected Business Type: 'hotel' or 'short_let'
  String _selectedPartnerType = 'hotel';
  ActiveVenueField _activeField = ActiveVenueField.businessName;

  bool _showCursor = true;
  Timer? _cursorTimer;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    // Blinking cursor simulation
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _hotelCardFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _shortLetCardFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _businessNameFocusNode.addListener(() {
      if (_businessNameFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveVenueField.businessName;
        });
      }
    });

    _contactEmailFocusNode.addListener(() {
      if (_contactEmailFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveVenueField.contactEmail;
        });
      }
    });

    _contactNameFocusNode.addListener(() {
      if (_contactNameFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveVenueField.contactName;
        });
      }
    });

    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveVenueField.phone;
        });
      }
    });

    _submitButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _backButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _businessNameController.dispose();
    _contactEmailController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();

    _screenFocusNode.dispose();
    _hotelCardFocusNode.dispose();
    _shortLetCardFocusNode.dispose();
    _businessNameFocusNode.dispose();
    _contactEmailFocusNode.dispose();
    _contactNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _submitButtonFocusNode.dispose();
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  TextEditingController get _currentController {
    switch (_activeField) {
      case ActiveVenueField.businessName:
        return _businessNameController;
      case ActiveVenueField.contactEmail:
        return _contactEmailController;
      case ActiveVenueField.contactName:
        return _contactNameController;
      case ActiveVenueField.phone:
        return _phoneController;
    }
  }

  String get _statusHeader {
    switch (_activeField) {
      case ActiveVenueField.businessName:
        return 'Entering Business name';
      case ActiveVenueField.contactEmail:
        return 'Entering Contact email';
      case ActiveVenueField.contactName:
        return 'Entering Contact name';
      case ActiveVenueField.phone:
        return 'Entering Phone';
    }
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/sign-in');
    }
  }

  void _handleVirtualKeyPress(String key) {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _currentController.text += key;
    });
  }

  void _handleBackspace() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      final text = _currentController.text;
      if (text.isNotEmpty) {
        _currentController.text = text.substring(0, text.length - 1);
      }
    });
  }

  void _handleSpace() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _currentController.text += ' ';
    });
  }

  void _handleClear() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _currentController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    final businessName = _businessNameController.text.trim();
    final email = _contactEmailController.text.trim();
    final contactName = _contactNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (businessName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your business name.';
        _successMessage = null;
      });
      _businessNameFocusNode.requestFocus();
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid contact email.';
        _successMessage = null;
      });
      _contactEmailFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authRepository.registerVenue(
        name: businessName,
        partnerType: _selectedPartnerType,
        contactEmail: email,
        contactName: contactName.isNotEmpty ? contactName : null,
        phone: phone.isNotEmpty ? phone : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage =
              'Registration request received! Our team will contact you shortly.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  KeyEventResult _handlePhysicalKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Remote Back button or Escape key
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.gameButtonB ||
          key == LogicalKeyboardKey.goBack) {
        _handleBack();
        return KeyEventResult.handled;
      }

      // Tab navigation
      if (key == LogicalKeyboardKey.tab) {
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        setState(() {
          if (isShift) {
            if (_backButtonFocusNode.hasFocus) {
              _submitButtonFocusNode.requestFocus();
            } else if (_submitButtonFocusNode.hasFocus) {
              _phoneFocusNode.requestFocus();
            } else if (_phoneFocusNode.hasFocus) {
              _contactNameFocusNode.requestFocus();
            } else if (_contactNameFocusNode.hasFocus) {
              _contactEmailFocusNode.requestFocus();
            } else if (_contactEmailFocusNode.hasFocus) {
              _businessNameFocusNode.requestFocus();
            } else if (_businessNameFocusNode.hasFocus) {
              _hotelCardFocusNode.requestFocus();
            }
          } else {
            if (_hotelCardFocusNode.hasFocus || _shortLetCardFocusNode.hasFocus) {
              _businessNameFocusNode.requestFocus();
            } else if (_businessNameFocusNode.hasFocus) {
              _contactEmailFocusNode.requestFocus();
            } else if (_contactEmailFocusNode.hasFocus) {
              _contactNameFocusNode.requestFocus();
            } else if (_contactNameFocusNode.hasFocus) {
              _phoneFocusNode.requestFocus();
            } else if (_phoneFocusNode.hasFocus) {
              _submitButtonFocusNode.requestFocus();
            } else if (_submitButtonFocusNode.hasFocus) {
              _backButtonFocusNode.requestFocus();
            }
          }
        });
        return KeyEventResult.handled;
      }

      // Arrow Left / Right between Business Type Cards
      if (_hotelCardFocusNode.hasFocus && key == LogicalKeyboardKey.arrowRight) {
        _shortLetCardFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (_shortLetCardFocusNode.hasFocus && key == LogicalKeyboardKey.arrowLeft) {
        _hotelCardFocusNode.requestFocus();
        return KeyEventResult.handled;
      }

      // Arrow Down navigation
      if (key == LogicalKeyboardKey.arrowDown) {
        if (_hotelCardFocusNode.hasFocus || _shortLetCardFocusNode.hasFocus) {
          _businessNameFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_businessNameFocusNode.hasFocus) {
          _contactEmailFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_contactEmailFocusNode.hasFocus) {
          _contactNameFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_contactNameFocusNode.hasFocus) {
          _phoneFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_phoneFocusNode.hasFocus) {
          _submitButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_submitButtonFocusNode.hasFocus) {
          _backButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }

      // Arrow Up navigation
      if (key == LogicalKeyboardKey.arrowUp) {
        if (_backButtonFocusNode.hasFocus) {
          _submitButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_submitButtonFocusNode.hasFocus) {
          _phoneFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_phoneFocusNode.hasFocus) {
          _contactNameFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_contactNameFocusNode.hasFocus) {
          _contactEmailFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_contactEmailFocusNode.hasFocus) {
          _businessNameFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_businessNameFocusNode.hasFocus) {
          if (_selectedPartnerType == 'short_let') {
            _shortLetCardFocusNode.requestFocus();
          } else {
            _hotelCardFocusNode.requestFocus();
          }
          return KeyEventResult.handled;
        }
      }

      // Backspace
      if (key == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return KeyEventResult.handled;
      }

      // Space
      if (key == LogicalKeyboardKey.space) {
        _handleSpace();
        return KeyEventResult.handled;
      }

      // Enter / Numpad Enter / Select
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA) {
        if (_hotelCardFocusNode.hasFocus) {
          setState(() {
            _selectedPartnerType = 'hotel';
          });
          return KeyEventResult.handled;
        } else if (_shortLetCardFocusNode.hasFocus) {
          setState(() {
            _selectedPartnerType = 'short_let';
          });
          return KeyEventResult.handled;
        } else if (_backButtonFocusNode.hasFocus) {
          _handleBack();
          return KeyEventResult.handled;
        } else {
          _handleSubmit();
          return KeyEventResult.handled;
        }
      }

      // Physical character typing
      if (event.character != null &&
          event.character!.isNotEmpty &&
          event.character!.codeUnitAt(0) >= 32) {
        _handleVirtualKeyPress(event.character!);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Focus(
        focusNode: _screenFocusNode,
        autofocus: true,
        onKeyEvent: _handlePhysicalKey,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF7FC),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFCFAFE),
                  Color(0xFFFAF6FC),
                  Color(0xFFF7F0FA),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Register Form & Actions
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main Headline: "Register your venue" with animated tilted badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const TvSectionBadge(
                                    icon: Icons.app_registration_rounded,
                                    size: 44,
                                    iconSize: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Register your venue',
                                      style: GoogleFonts.baloo2(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF18181B),
                                        letterSpacing: -0.6,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Tell us who you are and we will set up a Plodyo TV account for your\nrooms.',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF52525B),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Business Type Label
                              Text(
                                'Business type',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Business Type Cards Row
                              Row(
                                children: [
                                  // Hotel or guest house
                                  Expanded(
                                    child: _buildBusinessTypeCard(
                                      focusNode: _hotelCardFocusNode,
                                      title: 'Hotel or guest house',
                                      description:
                                          'Reviewed by our team before the account opens.',
                                      isSelected:
                                          _selectedPartnerType == 'hotel',
                                      onTap: () {
                                        setState(() {
                                          _selectedPartnerType = 'hotel';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Short-let host
                                  Expanded(
                                    child: _buildBusinessTypeCard(
                                      focusNode: _shortLetCardFocusNode,
                                      title: 'Short-let host',
                                      description:
                                          'Activated straight away, no review needed.',
                                      isSelected:
                                          _selectedPartnerType == 'short_let',
                                      onTap: () {
                                        setState(() {
                                          _selectedPartnerType = 'short_let';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Input 1: Business name
                              _buildInputField(
                                focusNode: _businessNameFocusNode,
                                fieldType: ActiveVenueField.businessName,
                                label: 'Business name',
                                placeholder: 'Grand Plaza Hotel',
                                icon: Icons.apartment_outlined,
                                controller: _businessNameController,
                              ),
                              const SizedBox(height: 10),

                              // Input 2: Contact email
                              _buildInputField(
                                focusNode: _contactEmailFocusNode,
                                fieldType: ActiveVenueField.contactEmail,
                                label: 'Contact email',
                                placeholder: 'ops@grandplaza.com',
                                icon: Icons.mail_outline_rounded,
                                controller: _contactEmailController,
                              ),
                              const SizedBox(height: 10),

                              // Input 3: Contact name (optional)
                              _buildInputField(
                                focusNode: _contactNameFocusNode,
                                fieldType: ActiveVenueField.contactName,
                                label: 'Contact name (optional)',
                                placeholder: 'Jordan Lee',
                                icon: Icons.person_outline_rounded,
                                controller: _contactNameController,
                              ),
                              const SizedBox(height: 10),

                              // Input 4: Phone (optional)
                              _buildInputField(
                                focusNode: _phoneFocusNode,
                                fieldType: ActiveVenueField.phone,
                                label: 'Phone (optional)',
                                placeholder: '+1-555-0100',
                                icon: Icons.phone_outlined,
                                controller: _phoneController,
                              ),
                              const SizedBox(height: 14),

                              // Error Banner
                              if (_errorMessage != null) ...[
                                _buildErrorBanner(_errorMessage!),
                                const SizedBox(height: 12),
                              ],

                              // Success Banner
                              if (_successMessage != null) ...[
                                _buildSuccessBanner(_successMessage!),
                                const SizedBox(height: 12),
                              ],

                              // "Send registration" Button (Full Width Gradient Pill)
                              _buildSubmitButton(),
                              const SizedBox(height: 12),

                              // "← Back to sign in" Button (Full Width White Pill)
                              _buildBackToSignInButton(),
                            ],
                          ),
                        ),

                        const SizedBox(width: 48),

                        // Right Column: Virtual On-Screen TV Keyboard
                        Expanded(
                          flex: 10,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TvKeyboard(
                              statusText: _statusHeader,
                              customSymbolsRow: const ['-', '&', '.', '\''],
                              onKeyPress: _handleVirtualKeyPress,
                              onBackspace: _handleBackspace,
                              onSpace: _handleSpace,
                              onClear: _handleClear,
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
        ),
      ),
    );
  }

  Widget _buildBusinessTypeCard({
    required FocusNode focusNode,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isFocused = focusNode.hasFocus;
    final isHighlighted = isFocused || isSelected;

    return Focus(
      focusNode: focusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
            onTap();
          },
          child: AnimatedScale(
            scale: isFocused ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFE4E4E7),
                  width: isHighlighted ? 1.8 : 1.2,
                ),
                boxShadow: [
                  if (isFocused)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    )
                  else if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF71717A),
                      height: 1.3,
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

  Widget _buildInputField({
    required FocusNode focusNode,
    required ActiveVenueField fieldType,
    required String label,
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
  }) {
    final isActive = _activeField == fieldType;
    final isFocused = focusNode.hasFocus;

    return Focus(
      focusNode: focusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
            setState(() {
              _activeField = fieldType;
            });
          },
          child: AnimatedScale(
            scale: (isFocused || isActive) ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isActive || isFocused)
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFE4E4E7),
                  width: (isActive || isFocused) ? 1.8 : 1.2,
                ),
                boxShadow: [
                  if (isActive || isFocused)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: (isActive || isFocused)
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF71717A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                controller.text.isEmpty
                                    ? placeholder
                                    : controller.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: controller.text.isEmpty
                                      ? const Color(0xFFA1A1AA)
                                      : const Color(0xFF18181B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 2),
                              Opacity(
                                opacity: _showCursor ? 1.0 : 0.0,
                                child: Container(
                                  width: 2,
                                  height: 16,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isFocused = _submitButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _submitButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleSubmit,
          child: AnimatedScale(
            scale: isFocused ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE11D89),
                    Color(0xFF8B5CF6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFocused
                        ? const Color(0xFFA855F7).withValues(alpha: 0.7)
                        : const Color(0xFF9333EA).withValues(alpha: 0.45),
                    blurRadius: isFocused ? 24 : 18,
                    spreadRadius: isFocused ? 3 : 1,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: isFocused
                    ? Border.all(color: Colors.white, width: 2.0)
                    : Border.all(color: Colors.transparent, width: 2.0),
              ),
              child: Center(
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sending registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          PlodyoThreeDotsLoading(
                            dotSize: 5.5,
                            spacing: 4,
                            bounceHeight: 4.5,
                            color: Colors.white,
                          ),
                        ],
                      )
                    : const Text(
                        'Send registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToSignInButton() {
    final isFocused = _backButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _backButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleBack,
          child: AnimatedScale(
            scale: isFocused ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF9333EA)
                      : const Color(0xFFF4F4F5),
                  width: isFocused ? 2.0 : 1.0,
                ),
                boxShadow: [
                  if (isFocused)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 15,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Back to sign in',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFECDD3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE11D48),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE11D48),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF16A34A),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
