import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
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
  language,
}

/// Add a Property View matching Plodyo UI design with interactive TV keyboard and real API integration.
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
  final TextEditingController _countryController = TextEditingController(text: 'US');
  final TextEditingController _cityController = TextEditingController(text: 'Austin');
  final TextEditingController _timezoneController = TextEditingController(text: 'America/Chicago');
  final TextEditingController _languageController = TextEditingController(text: 'en');

  List<PartnerModel> _availablePartners = [];
  String? _selectedPartnerId;
  String _partnerDisplayName = 'Loading partner...';
  bool _isLoadingPartner = true;
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
    _propertiesRepository = widget.propertiesRepository ?? sharedPropertiesRepository;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final token = _authRepository.currentAuth?.accessToken ?? '';
    final actor = _authRepository.currentUser;

    try {
      final res = await _partnersRepository.getPartners(
        accessToken: token,
        status: 'ACTIVE',
      );
      if (mounted) {
        setState(() {
          _availablePartners = res.data;
          if (actor?.partnerId != null && actor!.partnerId!.isNotEmpty) {
            _selectedPartnerId = actor.partnerId;
            final match = _availablePartners.where((p) => p.id == actor.partnerId).firstOrNull;
            _partnerDisplayName = match?.name ?? 'Partner #${actor.partnerId}';
          } else if (_availablePartners.isNotEmpty) {
            _selectedPartnerId = _availablePartners.first.id;
            _partnerDisplayName = _availablePartners.first.name;
          } else {
            _selectedPartnerId = '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b';
            _partnerDisplayName = 'Grand Hotel Downtown';
          }
          _isLoadingPartner = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedPartnerId = actor?.partnerId ?? '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b';
          _partnerDisplayName = 'Grand Hotel Downtown';
          _isLoadingPartner = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _timezoneController.dispose();
    _languageController.dispose();
    _screenFocusNode.dispose();
    super.dispose();
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
      case PropertyFormField.language:
        return _languageController;
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
      case PropertyFormField.language:
        return 'Entering Default language';
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
          content: Text('Please enter a property name'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final partnerId = _selectedPartnerId ?? '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b';
    final country = _countryController.text.trim();
    final city = _cityController.text.trim();
    final timezone = _timezoneController.text.trim();
    final defaultLanguage = _languageController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final created = await _propertiesRepository.createProperty(
        accessToken: token,
        partnerId: partnerId,
        name: name,
        country: country.isNotEmpty ? country : null,
        city: city.isNotEmpty ? city : null,
        timezone: timezone.isNotEmpty ? timezone : null,
        defaultLanguage: defaultLanguage.isNotEmpty ? defaultLanguage : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Property "${created.name}" created successfully!'),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onPropertyCreated?.call(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create property: $e'),
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
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        final fields = PropertyFormField.values;
        final currentIndex = fields.indexOf(_activeField);
        final nextIndex = isShift
            ? (currentIndex - 1 + fields.length) % fields.length
            : (currentIndex + 1) % fields.length;
        setState(() {
          _activeField = fields[nextIndex];
        });
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.arrowDown) {
        final fields = PropertyFormField.values;
        final currentIndex = fields.indexOf(_activeField);
        if (currentIndex < fields.length - 1) {
          setState(() {
            _activeField = fields[currentIndex + 1];
          });
          return KeyEventResult.handled;
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        final fields = PropertyFormField.values;
        final currentIndex = fields.indexOf(_activeField);
        if (currentIndex > 0) {
          setState(() {
            _activeField = fields[currentIndex - 1];
          });
          return KeyEventResult.handled;
        }
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
                          // Title: "Add a property"
                          const Text(
                            'Add a property',
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
                            'A property is one building or site. Rooms are created under it, and the room limit is shared across every property this partner owns.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF71717A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Partner Section
                          const Text(
                            'Partner',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF71717A),
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_isLoadingPartner)
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
                                  'Loading partner...',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                                ),
                              ],
                            )
                          else if (_availablePartners.length > 1 && _authRepository.currentUser?.partnerId == null)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPartnerId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                                ),
                              ),
                              items: _availablePartners.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedPartnerId = val;
                                    final match = _availablePartners.where((p) => p.id == val).firstOrNull;
                                    _partnerDisplayName = match?.name ?? '';
                                  });
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF71717A)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _partnerDisplayName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF18181B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 18),

                          // Field 1: Property name (Required)
                          _buildFormField(
                            field: PropertyFormField.name,
                            icon: Icons.account_balance_outlined,
                            label: 'Property name',
                            hintText: 'e.g. Grand Hotel Downtown - Riverside',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 10),

                          // Field 2: Country (optional)
                          _buildFormField(
                            field: PropertyFormField.country,
                            icon: Icons.language_outlined,
                            label: 'Country (optional)',
                            hintText: 'US',
                            controller: _countryController,
                          ),
                          const SizedBox(height: 10),

                          // Field 3: City (optional)
                          _buildFormField(
                            field: PropertyFormField.city,
                            icon: Icons.location_on_outlined,
                            label: 'City (optional)',
                            hintText: 'Austin',
                            controller: _cityController,
                          ),
                          const SizedBox(height: 10),

                          // Field 4: Timezone (optional)
                          _buildFormField(
                            field: PropertyFormField.timezone,
                            icon: Icons.access_time_rounded,
                            label: 'Timezone (optional)',
                            hintText: 'America/Chicago',
                            controller: _timezoneController,
                          ),
                          const SizedBox(height: 10),

                          // Field 5: Default language (optional)
                          _buildFormField(
                            field: PropertyFormField.language,
                            icon: Icons.translate_rounded,
                            label: 'Default language (optional)',
                            hintText: 'en',
                            controller: _languageController,
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons: "✓ Create property" and "← Cancel"
                          Row(
                            children: [
                              _CreatePropertyButton(
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
    required PropertyFormField field,
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
                  child: _TvFormKeyButton(
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
              child: _TvFormKeyButton(
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
              child: _TvFormKeyButton(
                label: '— Space',
                width: 82,
                height: 44,
                fontSize: 12.5,
                onPressed: _handleSpace,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TvFormKeyButton(
                icon: Icons.backspace_outlined,
                width: 50,
                height: 44,
                isPurpleAccent: true,
                onPressed: _handleBackspace,
              ),
            ),
            _TvFormKeyButton(
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

class _TvFormKeyButton extends StatefulWidget {
  const _TvFormKeyButton({
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
  State<_TvFormKeyButton> createState() => _TvFormKeyButtonState();
}

class _TvFormKeyButtonState extends State<_TvFormKeyButton> {
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

class _CreatePropertyButton extends StatefulWidget {
  const _CreatePropertyButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  State<_CreatePropertyButton> createState() => _CreatePropertyButtonState();
}

class _CreatePropertyButtonState extends State<_CreatePropertyButton> {
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
                    widget.isSubmitting ? 'Creating...' : 'Create property',
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
