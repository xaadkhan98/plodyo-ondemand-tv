import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';

enum RoomFormField {
  name,
  languageOverride,
}

/// Add a Room View matching Plodyo UI design with interactive TV keyboard and real API integration.
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

  RoomFormField _activeField = RoomFormField.name;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  List<PropertyModel> _activeProperties = [];
  String? _selectedPropertyId;
  bool _isLoadingProperties = true;
  bool _isSubmitting = false;

  bool _isUpperCase = false;
  bool _showCursor = true;
  Timer? _cursorTimer;

  final FocusNode _screenFocusNode = FocusNode();

  final List<List<String>> _keyboardRows = const [
    ['a', 'b', 'c', 'd', 'e', 'f'],
    ['g', 'h', 'i', 'j', 'k', 'l'],
    ['m', 'n', 'o', 'p', 'q', 'r'],
    ['s', 't', 'u', 'v', 'w', 'x'],
    ['y', 'z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
    ['-', '.', '\''],
  ];

  @override
  void initState() {
    super.initState();
    _roomsRepository = widget.roomsRepository ?? sharedRoomsRepository;
    _propertiesRepository = widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final token = _authRepository.currentAuth?.accessToken ?? '';
    try {
      final res = await _propertiesRepository.getProperties(
        accessToken: token,
        status: 'ACTIVE',
      );
      if (mounted) {
        setState(() {
          _activeProperties = res.data;
          if (_activeProperties.isNotEmpty) {
            _selectedPropertyId = _activeProperties.first.id;
          }
          _isLoadingProperties = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingProperties = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _nameController.dispose();
    _languageController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  TextEditingController get _activeController {
    switch (_activeField) {
      case RoomFormField.name:
        return _nameController;
      case RoomFormField.languageOverride:
        return _languageController;
    }
  }

  String get _activeFieldLabel {
    switch (_activeField) {
      case RoomFormField.name:
        return 'Entering Room name';
      case RoomFormField.languageOverride:
        return 'Entering Language override';
    }
  }

  void _handleVirtualKeyPress(String key) {
    setState(() {
      _activeController.text += key;
    });
  }

  void _handleBackspace() {
    final text = _activeController.text;
    if (text.isNotEmpty) {
      setState(() {
        _activeController.text = text.substring(0, text.length - 1);
      });
    }
  }

  void _handleSpace() {
    setState(() {
      _activeController.text += ' ';
    });
  }

  void _handleClear() {
    setState(() {
      _activeController.clear();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a room name'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPropertyId == null || _selectedPropertyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an active property to add this room to.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final languageOverride = _languageController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final created = await _roomsRepository.createRoom(
        accessToken: token,
        propertyId: _selectedPropertyId!,
        roomLabel: name,
        defaultLanguage: languageOverride.isNotEmpty ? languageOverride : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "${created.roomLabel}" created successfully!'),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onRoomCreated?.call(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  KeyEventResult _handlePhysicalKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.tab) {
        setState(() {
          _activeField = _activeField == RoomFormField.name
              ? RoomFormField.languageOverride
              : RoomFormField.name;
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _activeField = _activeField == RoomFormField.name
              ? RoomFormField.languageOverride
              : RoomFormField.name;
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.escape) {
        widget.onCancel?.call();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space) {
        _handleSpace();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        _submit();
        return KeyEventResult.handled;
      } else if (event.character != null &&
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalSpacing = screenWidth * 0.10;

    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: _handlePhysicalKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7FC),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar Branding: Logo + "Plodyo"
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: PlodyoHeader(padding: EdgeInsets.only(bottom: 12)),
              ),

              // Main Section UI
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Form
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title: "Add a room"
                          const Text(
                            'Add a room',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF18181B),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          const Text(
                            'A room is one TV. It stays unprovisioned until a device is paired with it, and counts against the partner\'s room limit either way.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF71717A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Property Section
                          const Text(
                            'Property',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_isLoadingProperties)
                            Row(
                              children: const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Loading active properties...',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                                ),
                              ],
                            )
                          else if (_activeProperties.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'There are no active properties to add a room to yet. Please create or activate a property first.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF71717A),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPropertyId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                                ),
                              ),
                              items: _activeProperties.map((prop) {
                                return DropdownMenuItem(
                                  value: prop.id,
                                  child: Text(prop.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedPropertyId = val;
                                  });
                                }
                              },
                            ),

                          const SizedBox(height: 18),

                          // Field 1: Room name (Required)
                          _buildFormField(
                            field: RoomFormField.name,
                            icon: Icons.door_sliding_outlined,
                            label: 'Room name',
                            hintText: 'e.g. Room 214',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 10),

                          // Field 2: Language override (optional)
                          _buildFormField(
                            field: RoomFormField.languageOverride,
                            icon: Icons.translate_rounded,
                            label: 'Language override (optional)',
                            hintText: 'Follows the property (e.g. es)',
                            controller: _languageController,
                          ),
                          const SizedBox(height: 6),

                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              'Leave the override empty to follow the property\'s language.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons: "✓ Create room" and "← Cancel"
                          Row(
                            children: [
                              _CreateRoomButton(
                                isSubmitting: _isSubmitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(width: 14),
                              _CancelButton(onPressed: () {
                                widget.onCancel?.call();
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 48),

                    // Right Column: TV Virtual Keyboard
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeFieldLabel,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF71717A),
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildVirtualKeyboard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required RoomFormField field,
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    final isActive = _activeField == field;

    return Focus(
      onFocusChange: (focused) {
        if (focused) {
          setState(() {
            _activeField = field;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeField = field;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
              width: isActive ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              else
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
              Icon(
                icon,
                size: 20,
                color: isActive ? const Color(0xFF9333EA) : const Color(0xFF71717A),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isActive ? const Color(0xFF9333EA) : const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            controller.text.isEmpty ? hintText : controller.text,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
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
                              width: 1.8,
                              height: 15,
                              color: const Color(0xFF9333EA),
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
    );
  }

  Widget _buildVirtualKeyboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._keyboardRows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((char) {
                final displayChar = _isUpperCase ? char.toUpperCase() : char;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TvRoomKeyButton(
                    label: displayChar,
                    width: 44,
                    height: 44,
                    onPressed: () => _handleVirtualKeyPress(displayChar),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvRoomKeyButton(
                label: _isUpperCase ? '↑ ABC' : '↑ abc',
                width: 66,
                height: 44,
                fontSize: 12.5,
                onPressed: () {
                  setState(() {
                    _isUpperCase = !_isUpperCase;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvRoomKeyButton(
                label: '— Space',
                width: 82,
                height: 44,
                fontSize: 12.5,
                onPressed: _handleSpace,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvRoomKeyButton(
                icon: Icons.backspace_outlined,
                width: 50,
                height: 44,
                isPurpleAccent: true,
                onPressed: _handleBackspace,
              ),
            ),
            _TvRoomKeyButton(
              label: 'Clear',
              width: 56,
              height: 44,
              fontSize: 12.5,
              onPressed: _handleClear,
            ),
          ],
        ),
      ],
    );
  }
}

class _TvRoomKeyButton extends StatefulWidget {
  const _TvRoomKeyButton({
    this.label,
    this.icon,
    this.width = 44,
    this.height = 44,
    this.fontSize = 15,
    this.isPurpleAccent = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final bool isPurpleAccent;
  final VoidCallback onPressed;

  @override
  State<_TvRoomKeyButton> createState() => _TvRoomKeyButtonState();
}

class _TvRoomKeyButtonState extends State<_TvRoomKeyButton> {
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
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.numpadEnter) {
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
            scale: active ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: widget.isPurpleAccent
                    ? const LinearGradient(
                        colors: [Color(0xFFC026D3), Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isPurpleAccent
                    ? null
                    : (active ? const Color(0xFFFAF5FF) : Colors.white),
                border: Border.all(
                  color: widget.isPurpleAccent
                      ? Colors.transparent
                      : (active ? const Color(0xFFC084FC) : const Color(0xFFE4E4E7)),
                  width: active ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (widget.isPurpleAccent)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    )
                  else if (active)
                    BoxShadow(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Center(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 17,
                        color: widget.isPurpleAccent
                            ? Colors.white
                            : (active ? const Color(0xFF7E22CE) : const Color(0xFF27272A)),
                      )
                    : Text(
                        widget.label ?? '',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: widget.isPurpleAccent
                              ? Colors.white
                              : (active ? const Color(0xFF7E22CE) : const Color(0xFF27272A)),
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

class _CreateRoomButton extends StatefulWidget {
  const _CreateRoomButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  State<_CreateRoomButton> createState() => _CreateRoomButtonState();
}

class _CreateRoomButtonState extends State<_CreateRoomButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isSubmitting ? null : widget.onPressed,
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isSubmitting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isSubmitting ? 'Creating...' : 'Create room',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _CancelButton extends StatefulWidget {
  const _CancelButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
                width: 1.2,
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF71717A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
