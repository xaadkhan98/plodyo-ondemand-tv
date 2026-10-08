import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/languages.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';

class RoomRange {
  const RoomRange({
    required this.prefix,
    required this.start,
    required this.end,
  });

  final String prefix;
  final int start;
  final int end;

  int get count => (end >= start) ? (end - start + 1) : 0;
  String get label =>
      '${prefix.trim().isNotEmpty ? prefix : ''}$start – ${prefix.trim().isNotEmpty ? prefix : ''}$end ($count ${count == 1 ? 'room' : 'rooms'})';
}

/// "Add many rooms" full-screen view matching the exact Plodyo TV specification.
/// Features Property Selection list, Range Builder with Prefix input and Dual Steppers,
/// Range staging list on the right, 18-Language selection grid with "Follows the property" option,
/// Add rooms / Cancel action buttons, and an integrated 6-column on-screen TV virtual keyboard.
class AddManyRoomsView extends StatefulWidget {
  const AddManyRoomsView({
    super.key,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
    this.onRoomsCreated,
    this.onCancel,
  });

  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final ValueChanged<List<RoomModel>>? onRoomsCreated;
  final VoidCallback? onCancel;

  @override
  State<AddManyRoomsView> createState() => _AddManyRoomsViewState();
}

class _AddManyRoomsViewState extends State<AddManyRoomsView> {
  late final RoomsRepository _roomsRepository;
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  final TextEditingController _prefixController = TextEditingController();

  int _firstNumber = 101;
  int _lastNumber = 110;
  final List<RoomRange> _ranges = [];

  List<PropertyModel> _availableProperties = [];
  String? _selectedPropertyId;
  String? _selectedLanguageCode; // null means "Follows the property"

  bool _isLoadingProperties = true;
  bool _isCreating = false;
  String? _errorMessage;

  // Blinking cursor state for prefix box
  bool _showCursor = true;
  Timer? _cursorTimer;

  // Virtual keyboard state
  bool _isUpperCase = false;
  bool _showSymbols = false;

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

    _prefixController.addListener(_onTextChanged);
    _loadProperties();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _prefixController.dispose();
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
        _selectedPropertyId = _availableProperties.first.id;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingProperties = false;
      });
    }
  }

  void _handleVirtualKeyPress(String char) {
    final controller = _prefixController;
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
    final controller = _prefixController;
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
    _prefixController.value = const TextEditingValue(
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

  void _handleAddRange() {
    if (_firstNumber > _lastNumber) {
      setState(() {
        _errorMessage =
            'First number ($_firstNumber) cannot be greater than last number ($_lastNumber).';
      });
      return;
    }

    final newRange = RoomRange(
      prefix: _prefixController.text,
      start: _firstNumber,
      end: _lastNumber,
    );

    setState(() {
      _ranges.add(newRange);
      _errorMessage = null;

      // Smart increment for next floor / batch
      final count = _lastNumber - _firstNumber + 1;
      _firstNumber = _lastNumber + 1;
      _lastNumber = _firstNumber + (count > 0 ? count - 1 : 9);
    });
  }

  void _handleRemoveRange(int index) {
    setState(() {
      _ranges.removeAt(index);
    });
  }

  Future<void> _handleCreateRooms() async {
    List<RoomRange> rangesToCreate = List.from(_ranges);

    // If no range has been explicitly staged, use the currently configured one
    if (rangesToCreate.isEmpty) {
      if (_firstNumber > _lastNumber) {
        setState(() {
          _errorMessage =
              'First number ($_firstNumber) cannot be greater than last number ($_lastNumber).';
        });
        return;
      }
      rangesToCreate.add(
        RoomRange(
          prefix: _prefixController.text,
          start: _firstNumber,
          end: _lastNumber,
        ),
      );
    }

    if (_selectedPropertyId == null && _availableProperties.isNotEmpty) {
      _selectedPropertyId = _availableProperties.first.id;
    }

    final totalRoomsCount = rangesToCreate.fold<int>(
      0,
      (sum, r) => sum + r.count,
    );

    if (totalRoomsCount <= 0) {
      setState(() {
        _errorMessage = 'Please specify at least one valid room range.';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final bulkRoomsPayload = <Map<String, dynamic>>[];

      for (final range in rangesToCreate) {
        for (int num = range.start; num <= range.end; num++) {
          final label = '${range.prefix}$num';
          bulkRoomsPayload.add({
            'room_label': label,
            if (_selectedLanguageCode != null)
              'default_language': _selectedLanguageCode,
          });
        }
      }

      final bulkResponse = await _roomsRepository.createRoomsBulk(
        accessToken: token,
        propertyId: _selectedPropertyId ?? '',
        rooms: bulkRoomsPayload,
        defaultLanguage: _selectedLanguageCode,
      );

      final createdRooms = bulkResponse.rooms;

      if (mounted) {
        widget.onRoomsCreated?.call(createdRooms);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${bulkResponse.created} ${bulkResponse.created == 1 ? 'room' : 'rooms'} created successfully!',
            ),
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
    final totalStagedRooms = _ranges.fold<int>(0, (sum, r) => sum + r.count);

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
                                  icon: Icons.domain_add_rounded,
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
                                        'Add many rooms',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF18181B),
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Either every room is created or none are, so a failed attempt leaves nothing to tidy up. No pairing codes are issued here — a code lasts fifteen minutes, so each TV is paired from its own room screen when someone is standing at it.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFF64748B),
                                          height: 1.45,
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
                            const SizedBox(height: 24),

                            // SECTION 2: BUILD A RANGE
                            Text(
                              'Build a range',
                              style: GoogleFonts.baloo2(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF18181B),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add one range per floor or wing. Numbering that skips or restarts is why this is several ranges rather than one.',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Prefix Input Box
                            _PrefixInputBox(
                              controller: _prefixController,
                              showCursor: _showCursor,
                            ),
                            const SizedBox(height: 20),

                            // Dual Number Steppers (First number & Last number)
                            Row(
                              children: [
                                // First number Stepper
                                Expanded(
                                  child: _buildNumberStepper(
                                    label: 'First number',
                                    value: _firstNumber,
                                    onDecrement10: () {
                                      setState(() {
                                        _firstNumber = (_firstNumber - 10)
                                            .clamp(1, 9999);
                                      });
                                    },
                                    onDecrement1: () {
                                      setState(() {
                                        _firstNumber = (_firstNumber - 1).clamp(
                                          1,
                                          9999,
                                        );
                                      });
                                    },
                                    onIncrement1: () {
                                      setState(() {
                                        _firstNumber += 1;
                                      });
                                    },
                                    onIncrement10: () {
                                      setState(() {
                                        _firstNumber += 10;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Last number Stepper
                                Expanded(
                                  child: _buildNumberStepper(
                                    label: 'Last number',
                                    value: _lastNumber,
                                    onDecrement10: () {
                                      setState(() {
                                        _lastNumber = (_lastNumber - 10).clamp(
                                          1,
                                          9999,
                                        );
                                      });
                                    },
                                    onDecrement1: () {
                                      setState(() {
                                        _lastNumber = (_lastNumber - 1).clamp(
                                          1,
                                          9999,
                                        );
                                      });
                                    },
                                    onIncrement1: () {
                                      setState(() {
                                        _lastNumber += 1;
                                      });
                                    },
                                    onIncrement10: () {
                                      setState(() {
                                        _lastNumber += 10;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // "+ Add this range" Outline Button
                            _AddThisRangeButton(onPressed: _handleAddRange),
                            const SizedBox(height: 32),

                            // SECTION 3: LANGUAGE FOR EVERY ROOM IN THIS BATCH (OPTIONAL)
                            const Row(
                              children: [
                                Icon(
                                  Icons.translate_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Language for every room in this batch (optional)',
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
                            const SizedBox(height: 36),

                            // BOTTOM ACTION BUTTONS: [Add rooms]  [Cancel]
                            Row(
                              children: [
                                _AddRoomsSubmitButton(
                                  isLoading: _isCreating,
                                  onPressed: _handleCreateRooms,
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

                      // RIGHT COLUMN: Preview List & Virtual Keyboard
                      SizedBox(
                        width: 380,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header for Staging Preview
                            Text(
                              _ranges.isEmpty
                                  ? 'Nothing in the list yet'
                                  : '${_ranges.length} ${_ranges.length == 1 ? 'range' : 'ranges'} ($totalStagedRooms ${totalStagedRooms == 1 ? 'room' : 'rooms'})',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Staged Ranges Container or Empty State Box
                            if (_ranges.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD8B4FE),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'Build a range and it appears here before anything is sent.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: _ranges.asMap().entries.map((
                                    entry,
                                  ) {
                                    final idx = entry.key;
                                    final range = entry.value;
                                    return Container(
                                      margin: EdgeInsets.only(
                                        bottom: idx == _ranges.length - 1
                                            ? 0
                                            : 8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF5FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFDDD6FE),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.meeting_room_outlined,
                                            size: 16,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              range.label,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF18181B),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            onTap: () =>
                                                _handleRemoveRange(idx),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 16,
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 20),

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

  Widget _buildNumberStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement10,
    required VoidCallback onDecrement1,
    required VoidCallback onIncrement1,
    required VoidCallback onIncrement10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepperButton(text: '– 10', onTap: onDecrement10, width: 48),
            const SizedBox(width: 6),
            _StepperButton(text: '–', onTap: onDecrement1, width: 40),
            const SizedBox(width: 6),
            // Value Box
            Container(
              width: 76,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StepperButton(text: '+', onTap: onIncrement1, width: 40),
            const SizedBox(width: 6),
            _StepperButton(text: '+ 10', onTap: onIncrement10, width: 48),
          ],
        ),
      ],
    );
  }
}

/// Stepper Button (-10, -, +, +10)
class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.text,
    required this.onTap,
    this.width = 44,
  });

  final String text;
  final VoidCallback onTap;
  final double width;

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
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: widget.width,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFCBD5E1),
                  width: isHighlighted ? 1.8 : 1.4,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ Add this range" Outline Button
class _AddThisRangeButton extends StatefulWidget {
  const _AddThisRangeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddThisRangeButton> createState() => _AddThisRangeButtonState();
}

class _AddThisRangeButtonState extends State<_AddThisRangeButton> {
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
            scale: isHighlighted ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 1.8),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: Color(0xFF18181B)),
                  SizedBox(width: 6),
                  Text(
                    'Add this range',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
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
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
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
              child: Row(
                children: [
                  // Building Icon
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

/// Prefix Input Box styled with active glowing purple border
class _PrefixInputBox extends StatefulWidget {
  const _PrefixInputBox({required this.controller, required this.showCursor});

  final TextEditingController controller;
  final bool showCursor;

  @override
  State<_PrefixInputBox> createState() => _PrefixInputBoxState();
}

class _PrefixInputBoxState extends State<_PrefixInputBox> {
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
                ).withValues(alpha: isHighlighted ? 0.32 : 0.16),
                blurRadius: isHighlighted ? 14 : 8,
                offset: const Offset(0, 3),
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
                      'Prefix (optional)',
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
                            'Room ',
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
  const _FollowsPropertyCard({required this.isSelected, required this.onTap});

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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFFFAF5FF)
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
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
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(
                    'Follows the property',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF18181B),
                    ),
                  ),
                  const Spacer(),
                  if (widget.isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 15,
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

/// Language Selection Grid Tile
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
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF8B5CF6)
                      : (isHighlighted
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFFCBD5E1)),
                  width: widget.isSelected ? 2.0 : 1.3,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LanguageFlag(code: widget.language.code),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.language.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? const Color(0xFF7C3AED)
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

/// Primary Gradient "✓ Add rooms" Button
class _AddRoomsSubmitButton extends StatefulWidget {
  const _AddRoomsSubmitButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_AddRoomsSubmitButton> createState() => _AddRoomsSubmitButtonState();
}

class _AddRoomsSubmitButtonState extends State<_AddRoomsSubmitButton> {
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD946EF), // Fuchsia / Magenta
                    Color(0xFF9333EA), // Purple
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFD946EF,
                    ).withValues(alpha: isHighlighted ? 0.45 : 0.28),
                    blurRadius: isHighlighted ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    const Text(
                      'Creating rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const LoadingDots(color: Colors.white),
                  ] else ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline "Cancel" Pill Button
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
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 1.8),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF18181B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 15,
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
}

/// 6-Column On-Screen TV Virtual Keyboard
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

  static const List<List<String>> _letterRows = [
    ['a', 'b', 'c', 'd', 'e', 'f'],
    ['g', 'h', 'i', 'j', 'k', 'l'],
    ['m', 'n', 'o', 'p', 'q', 'r'],
    ['s', 't', 'u', 'v', 'w', 'x'],
    ['y', 'z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
    ['-', '.', '\''],
  ];

  static const List<List<String>> _symbolRows = [
    ['1', '2', '3', '4', '5', '6'],
    ['7', '8', '9', '0', '@', '#'],
    ['\$', '%', '&', '*', '(', ')'],
    ['-', '+', '=', '/', ':', ';'],
    ['!', '?', '"', '\'', ',', '.'],
    ['_', '~', '`', '<', '>', '\\'],
    ['[', ']', '{', '}'],
  ];

  @override
  Widget build(BuildContext context) {
    final rows = showSymbols ? _symbolRows : _letterRows;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Character rows
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final keyChar in row) ...[
                  _TvKeyButton(
                    label: isUpperCase ? keyChar.toUpperCase() : keyChar,
                    onTap: () {
                      final val = isUpperCase ? keyChar.toUpperCase() : keyChar;
                      onKeyPress(val);
                    },
                  ),
                  if (keyChar != row.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Control row: [↑ abc] [!#?] [—] [⌫] [Clear]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shift / Case toggle
              _TvKeyButton(
                label: isUpperCase ? '↑ ABC' : '↑ abc',
                isAction: true,
                isActive: isUpperCase,
                width: 58,
                onTap: onToggleCase,
              ),
              const SizedBox(width: 8),

              // Symbols toggle
              _TvKeyButton(
                label: showSymbols ? 'ABC' : '!#?',
                isAction: true,
                isActive: showSymbols,
                width: 52,
                onTap: onToggleSymbols,
              ),
              const SizedBox(width: 8),

              // Space
              _TvKeyButton(
                label: '—',
                isAction: true,
                width: 64,
                onTap: onSpace,
              ),
              const SizedBox(width: 8),

              // Backspace
              _TvKeyButton(
                icon: Icons.backspace_outlined,
                isAction: true,
                width: 52,
                onTap: onBackspace,
              ),
              const SizedBox(width: 8),

              // Clear
              _TvKeyButton(
                label: 'Clear',
                isAction: true,
                width: 58,
                onTap: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single Virtual TV Key Button with rich TV focus/hover animations
class _TvKeyButton extends StatefulWidget {
  const _TvKeyButton({
    this.label,
    this.icon,
    this.width = 46,
    this.isAction = false,
    this.isActive = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final bool isAction;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_TvKeyButton> createState() => _TvKeyButtonState();
}

class _TvKeyButtonState extends State<_TvKeyButton> {
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

    Color bg;
    Color border;
    Color textCol;

    if (widget.isActive) {
      bg = const Color(0xFF8B5CF6);
      border = const Color(0xFF7C3AED);
      textCol = Colors.white;
    } else if (isHighlighted) {
      bg = const Color(0xFFFAF5FF);
      border = const Color(0xFF8B5CF6);
      textCol = const Color(0xFF7C3AED);
    } else if (widget.isAction) {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      textCol = const Color(0xFF475569);
    } else {
      bg = Colors.white;
      border = const Color(0xFFCBD5E1);
      textCol = const Color(0xFF18181B);
    }

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
            scale: isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.width,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: border,
                  width: isHighlighted || widget.isActive ? 1.8 : 1.2,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: widget.icon != null
                  ? Icon(widget.icon, size: 18, color: textCol)
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: widget.isAction ? 12 : 15,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
