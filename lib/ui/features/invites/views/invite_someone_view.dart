import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/invite_model.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/invites_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

/// "Invite Someone" full-screen view matching the exact Plodyo TV specification.
/// Features Email address input with blinking cursor, 2-card Role selector
/// (Partner admin vs Property admin), selectable Partner / Property list,
/// Send invite gradient pill button & Cancel outline button, and an integrated
/// 6-column on-screen TV virtual keyboard.
class InviteSomeoneView extends StatefulWidget {
  const InviteSomeoneView({
    super.key,
    this.invitesRepository,
    this.partnersRepository,
    this.propertiesRepository,
    this.authRepository,
    this.onBack,
    this.onInviteSent,
  });

  final InvitesRepository? invitesRepository;
  final PartnersRepository? partnersRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final ValueChanged<InviteModel>? onInviteSent;

  @override
  State<InviteSomeoneView> createState() => _InviteSomeoneViewState();
}

class _InviteSomeoneViewState extends State<InviteSomeoneView> {
  late final InvitesRepository _invitesRepository;
  late final PartnersRepository _partnersRepository;
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  String _selectedRole = 'PARTNER_ADMIN'; // 'PARTNER_ADMIN' or 'PROPERTY_ADMIN'
  String? _selectedPartnerId;
  String? _selectedPropertyId;

  List<PartnerModel> _partners = [];
  List<PropertyModel> _properties = [];
  bool _isLoadingData = false;
  bool _isSending = false;
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
    _invitesRepository = widget.invitesRepository ?? sharedInvitesRepository;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _propertiesRepository =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    // Start blinking cursor timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _emailController.addListener(_onTextChanged);
    _loadInitialData();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    final token = _authRepository.currentAuth?.accessToken ?? '';
    final actor = _authRepository.currentUser;

    try {
      final partnersRes = await _partnersRepository.getPartners(
        accessToken: token,
        status: 'ACTIVE',
      );
      _partners = partnersRes.data;

      if (_partners.isNotEmpty) {
        if (actor?.partnerId != null &&
            _partners.any((p) => p.id == actor!.partnerId)) {
          _selectedPartnerId = actor!.partnerId;
        } else {
          _selectedPartnerId = _partners.first.id;
        }
      }

      await _loadPropertiesForPartner(_selectedPartnerId);
    } catch (e) {
      // Fallback is handled inside repositories, but catch safety
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadPropertiesForPartner(String? partnerId) async {
    final token = _authRepository.currentAuth?.accessToken ?? '';
    try {
      final propertiesRes = await _propertiesRepository.getProperties(
        accessToken: token,
        partnerId: partnerId,
        status: 'ACTIVE',
      );
      _properties = propertiesRes.data;
      if (_properties.isNotEmpty) {
        _selectedPropertyId = _properties.first.id;
      } else {
        _selectedPropertyId = null;
      }
    } catch (_) {}
  }

  void _handleRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _handlePartnerSelected(String partnerId) {
    setState(() {
      _selectedPartnerId = partnerId;
    });
    _loadPropertiesForPartner(partnerId);
  }

  void _handlePropertySelected(String propertyId) {
    setState(() {
      _selectedPropertyId = propertyId;
    });
  }

  void _handleVirtualKeyPress(String char) {
    final controller = _emailController;
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
    final controller = _emailController;
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
    _emailController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/invites');
    }
  }

  Future<void> _handleSendInvite() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Email address is required.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (_selectedPartnerId == null && _partners.isNotEmpty) {
      _selectedPartnerId = _partners.first.id;
    }

    if (_selectedRole == 'PROPERTY_ADMIN' && _selectedPropertyId == null) {
      setState(() {
        _errorMessage = 'Please select a property for the Property Admin.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final newInvite = await _invitesRepository.createInvite(
        accessToken: token,
        email: email,
        role: _selectedRole,
        partnerId: _selectedPartnerId ?? '',
        propertyId: _selectedRole == 'PROPERTY_ADMIN'
            ? _selectedPropertyId
            : null,
      );

      if (mounted) {
        widget.onInviteSent?.call(newInvite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to "$email" successfully!'),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
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

              // Main 2-Column Scrollable Body
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
                                  icon: Icons.person_add_rounded,
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
                                        'Invite someone',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF18181B),
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'They will get an email with a link to choose a password. The link expires after seven days.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
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

                            // EMAIL ADDRESS INPUT FIELD CARD
                            _EmailInputBox(
                              controller: _emailController,
                              showCursor: _showCursor,
                            ),
                            const SizedBox(height: 24),

                            // ROLE SELECTOR SECTION
                            const Text(
                              'Role',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Card 1: Partner admin
                                Expanded(
                                  child: _RoleCard(
                                    title: 'Partner admin',
                                    subtitle:
                                        'Administers the partner and every property under it.',
                                    isSelected:
                                        _selectedRole == 'PARTNER_ADMIN',
                                    onTap: () =>
                                        _handleRoleChanged('PARTNER_ADMIN'),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Card 2: Property admin
                                Expanded(
                                  child: _RoleCard(
                                    title: 'Property admin',
                                    subtitle: 'Administers one property only.',
                                    isSelected:
                                        _selectedRole == 'PROPERTY_ADMIN',
                                    onTap: () =>
                                        _handleRoleChanged('PROPERTY_ADMIN'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // PARTNER / PROPERTY SELECTION LIST SECTION
                            Text(
                              _selectedRole == 'PARTNER_ADMIN'
                                  ? 'Partner'
                                  : 'Property',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoadingData)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF9333EA),
                                    ),
                                  ),
                                ),
                              )
                            else if (_selectedRole == 'PARTNER_ADMIN') ...[
                              // Partners List
                              ..._partners.map((partner) {
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
                                    onTap: () =>
                                        _handlePartnerSelected(partner.id),
                                  ),
                                );
                              }),
                            ] else ...[
                              // Properties List
                              if (_properties.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: const Text(
                                    'No properties found for this partner.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              else
                                ..._properties.map((property) {
                                  final isSelected =
                                      _selectedPropertyId == property.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _PartnerSelectCard(
                                      name: property.name,
                                      subtitle:
                                          '${property.city}, ${property.country} • ${property.timezone}',
                                      isSelected: isSelected,
                                      onTap: () =>
                                          _handlePropertySelected(property.id),
                                    ),
                                  );
                                }),
                            ],
                            const SizedBox(height: 28),

                            // BOTTOM ACTION BUTTONS: [Send invite]  [Cancel]
                            Row(
                              children: [
                                _SendInviteButton(
                                  isLoading: _isSending,
                                  onPressed: _handleSendInvite,
                                ),
                                const SizedBox(width: 16),
                                _CancelButton(onPressed: _handleBack),
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
                            // "Entering email address" Header
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16, right: 4),
                              child: Text(
                                'Entering email address',
                                style: TextStyle(
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

/// Email Input Box styled exactly like design screenshot
class _EmailInputBox extends StatefulWidget {
  const _EmailInputBox({required this.controller, required this.showCursor});

  final TextEditingController controller;
  final bool showCursor;

  @override
  State<_EmailInputBox> createState() => _EmailInputBoxState();
}

class _EmailInputBoxState extends State<_EmailInputBox> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8B5CF6), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF8B5CF6,
                ).withValues(alpha: isHighlighted ? 0.25 : 0.12),
                blurRadius: isHighlighted ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email Icon
              const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
              const SizedBox(width: 14),

              // Label & Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Email address',
                      style: TextStyle(
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
                          )
                        else
                          const Text(
                            'colleague@venue.com',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.1,
                            ),
                          ),
                        // Blinking Cursor
                        if (widget.showCursor)
                          Container(
                            margin: const EdgeInsets.only(left: 2),
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
    );
  }
}

/// Role Selection Card (Partner admin / Property admin)
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
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
            scale: isHighlighted ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.18),
                          blurRadius: 10,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.35,
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

/// Partner / Property Selectable Item Card
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
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.16),
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

/// "Send invite" Gradient Pill Button
class _SendInviteButton extends StatefulWidget {
  const _SendInviteButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_SendInviteButton> createState() => _SendInviteButtonState();
}

class _SendInviteButtonState extends State<_SendInviteButton> {
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
                          'Sending invite',
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
                        Icon(Icons.send_rounded, color: Colors.white, size: 17),
                        SizedBox(width: 8),
                        Text(
                          'Send invite',
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
    ['@', '.', '-', '_'],
  ];

  List<List<String>> get _symbolsRows => [
    ['!', '@', '#', '\$', '%', '^'],
    ['&', '*', '(', ')', '_', '+'],
    ['[', ']', '{', '}', ';', ':'],
    ['\'', '"', ',', '.', '/', '?'],
    ['~', '`', '<', '>', '=', '\\'],
    ['4', '5', '6', '7', '8', '9'],
    ['@', '.', '-', '_'],
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
