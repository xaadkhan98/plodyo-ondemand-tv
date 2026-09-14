import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';

class LanguageOption {
  const LanguageOption({
    required this.name,
    required this.flag,
    required this.code,
  });

  final String name;
  final String flag;
  final String code;
}

/// "Add a room" full-screen view matching the exact Plodyo TV specification.
/// Features Property Selection list, styled Room name input with active blinking cursor,
/// 18-Language selection grid with "Follows the property" default option,
/// Create/Cancel action buttons, and an integrated 6-column on-screen TV virtual keyboard.
class AddRoomView extends StatefulWidget {
  const AddRoomView({
    super.key,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
    this.onRoomCreated,
    this.onCancel,
  });

  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final ValueChanged<RoomModel>? onRoomCreated;
  final VoidCallback? onCancel;

  @override
  State<AddRoomView> createState() => _AddRoomViewState();
}

class _AddRoomViewState extends State<AddRoomView> {
  late final RoomsRepository _roomsRepository;
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  final TextEditingController _nameController =
      TextEditingController(text: 'Room 214');

  List<PropertyModel> _availableProperties = [];
  String? _selectedPropertyId;
  String? _selectedLanguageCode; // null means "Follows the property"

  bool _isLoadingProperties = true;
  bool _isCreating = false;
  String? _errorMessage;

  // Blinking cursor state
  bool _showCursor = true;
  Timer? _cursorTimer;

  // Virtual keyboard state
  bool _isUpperCase = false;
  bool _showSymbols = false;

  static const List<LanguageOption> _languages = [
    LanguageOption(name: 'English', flag: '🇬🇧', code: 'en'),
    LanguageOption(name: 'Spanish', flag: '🇪🇸', code: 'es'),
    LanguageOption(name: 'French', flag: '🇫🇷', code: 'fr'),
    LanguageOption(name: 'German', flag: '🇩🇪', code: 'de'),
    LanguageOption(name: 'Italian', flag: '🇮🇹', code: 'it'),
    LanguageOption(name: 'Portuguese', flag: '🇵🇹', code: 'pt'),
    LanguageOption(name: 'Dutch', flag: '🇳🇱', code: 'nl'),
    LanguageOption(name: 'Polish', flag: '🇵🇱', code: 'pl'),
    LanguageOption(name: 'Arabic', flag: '🇸🇦', code: 'ar'),
    LanguageOption(name: 'Hindi', flag: '🇮🇳', code: 'hi'),
    LanguageOption(name: 'Urdu', flag: '🇵🇰', code: 'ur'),
    LanguageOption(name: 'Bengali', flag: '🇧🇩', code: 'bn'),
    LanguageOption(name: 'Mandarin', flag: '🇨🇳', code: 'zh'),
    LanguageOption(name: 'Japanese', flag: '🇯🇵', code: 'ja'),
    LanguageOption(name: 'Korean', flag: '🇰🇷', code: 'ko'),
    LanguageOption(name: 'Turkish', flag: '🇹🇷', code: 'tr'),
    LanguageOption(name: 'Russian', flag: '🇷🇺', code: 'ru'),
    LanguageOption(name: 'Swedish', flag: '🇸🇪', code: 'sv'),
  ];

  @override
  void initState() {
    super.initState();
    _roomsRepository = widget.roomsRepository ?? sharedRoomsRepository;
    _propertiesRepository =
        widget.propertiesRepository ?? sharedPropertiesRepository;
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
    _loadProperties();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoadingProperties = true;
      _errorMessage = null;
    });

    final token = _authRepository.currentAuth?.accessToken ?? '';

    try {
      final res = await _propertiesRepository.getProperties(
        accessToken: token,
        status: 'ACTIVE',
      );
      _availableProperties = res.data;

      if (_availableProperties.isNotEmpty) {
        // Default to third property (e.g. Imperial Square) if matches screenshot, or first
        if (_availableProperties.length >= 3) {
          _selectedPropertyId = _availableProperties[2].id;
        } else {
          _selectedPropertyId = _availableProperties.first.id;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  void _handleVirtualKeyPress(String char) {
    final controller = _nameController;
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
    final controller = _nameController;
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
    _nameController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  void _handleBack() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/rooms');
    }
  }

  Future<void> _handleCreateRoom() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Room name is required.';
      });
      return;
    }

    if (_selectedPropertyId == null && _availableProperties.isNotEmpty) {
      _selectedPropertyId = _availableProperties.first.id;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final newRoom = await _roomsRepository.createRoom(
        accessToken: token,
        propertyId: _selectedPropertyId ?? 'prop-1',
        roomLabel: name,
        defaultLanguage: _selectedLanguageCode,
      );

      if (mounted) {
        widget.onRoomCreated?.call(newRoom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "$name" created successfully!'),
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
                                  icon: Icons.meeting_room_rounded,
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
                                        'Add a room',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF18181B),
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'A room is one TV. It stays unprovisioned until a device is paired with it, and counts against the partner\'s room limit either way.',
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

                            // SECTION 1: PROPERTY SELECTION LIST
                            const Text(
                              'Property',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_isLoadingProperties)
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
                              ..._availableProperties.map((property) {
                                final isSelected =
                                    _selectedPropertyId == property.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PropertySelectCard(
                                    name: property.name,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedPropertyId = property.id;
                                      });
                                    },
                                  ),
                                );
                              }),
                            const SizedBox(height: 18),

                            // SECTION 2: ROOM NAME INPUT FIELD CARD
                            _RoomNameInputBox(
                              controller: _nameController,
                              showCursor: _showCursor,
                            ),
                            const SizedBox(height: 24),

                            // SECTION 3: LANGUAGE OVERRIDE (OPTIONAL)
                            const Row(
                              children: [
                                Icon(
                                  Icons.translate_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Language override (optional)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // "Follows the property" full-width card
                            _FollowsPropertyCard(
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
                                  children: _languages.map((lang) {
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

                            // BOTTOM ACTION BUTTONS: [Create room]  [Cancel]
                            Row(
                              children: [
                                _CreateRoomButton(
                                  isLoading: _isCreating,
                                  onPressed: _handleCreateRoom,
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
                            // "Entering Room name" Header
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16, right: 4),
                              child: Text(
                                'Entering Room name',
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

/// Property Selectable Item Card
class _PropertySelectCard extends StatefulWidget {
  const _PropertySelectCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PropertySelectCard> createState() => _PropertySelectCardState();
}

class _PropertySelectCardState extends State<_PropertySelectCard> {
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
                              .withValues(alpha: 0.18),
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
              child: Row(
                children: [
                  // Classical Building Icon
                  Icon(
                    Icons.account_balance_rounded,
                    size: 20,
                    color: widget.isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 14),

                  // Property Name
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF18181B),
                      ),
                    ),
                  ),

                  // Subtle checkmark if selected
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

/// Room Name Input Box styled exactly like design screenshot
class _RoomNameInputBox extends StatefulWidget {
  const _RoomNameInputBox({
    required this.controller,
    required this.showCursor,
  });

  final TextEditingController controller;
  final bool showCursor;

  @override
  State<_RoomNameInputBox> createState() => _RoomNameInputBoxState();
}

class _RoomNameInputBoxState extends State<_RoomNameInputBox> {
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
            border: Border.all(
              color: const Color(0xFF8B5CF6),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: isHighlighted ? 0.28 : 0.14),
                blurRadius: isHighlighted ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Door Icon
              const Icon(
                Icons.meeting_room_rounded,
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
                      'Room name',
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
                            'Room 214',
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

/// "Follows the property" Full-Width Language Option Card
class _FollowsPropertyCard extends StatefulWidget {
  const _FollowsPropertyCard({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FollowsPropertyCard> createState() => _FollowsPropertyCardState();
}

class _FollowsPropertyCardState extends State<_FollowsPropertyCard> {
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
                      'Follows the property',
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

  final LanguageOption language;
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
                  Text(
                    widget.language.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
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

/// "Create room" Gradient Pill Button
class _CreateRoomButton extends StatefulWidget {
  const _CreateRoomButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_CreateRoomButton> createState() => _CreateRoomButtonState();
}

class _CreateRoomButtonState extends State<_CreateRoomButton> {
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
                          'Creating room',
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
                          'Create room',
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
