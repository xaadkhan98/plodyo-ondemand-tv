import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/languages.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import 'add_room_view.dart';

enum RoomStatusFilter { all, notSetUp, active, revoked }

/// Rooms View matching the exact Plodyo TV specification.
/// Features angled floating badge icon animation, status filter pills,
/// horizontal property filter pills row, styled room cards with
/// active/not-set-up badges, property & language subtitles,
/// and "+ Add room" & "Add many" action buttons.
class RoomsView extends StatefulWidget {
  const RoomsView({
    super.key,
    this.roomsRepository,
    this.propertiesRepository,
    this.authRepository,
    this.initialIsAddingRoom = false,
    this.onRoomSelected,
  });

  final RoomsRepository? roomsRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final bool initialIsAddingRoom;
  final ValueChanged<RoomModel>? onRoomSelected;

  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  late final RoomsRepository _roomsRepository;
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  RoomStatusFilter _selectedStatusFilter = RoomStatusFilter.all;
  String? _selectedPropertyId; // null = 'All properties'

  List<RoomModel> _rooms = [];
  List<PropertyModel> _properties = [];
  Map<String, String> _propertyNames = {};
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isAddingRoom;

  @override
  void initState() {
    super.initState();
    _roomsRepository = widget.roomsRepository ?? sharedRoomsRepository;
    _propertiesRepository =
        widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _isAddingRoom = widget.initialIsAddingRoom;

    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _apiStatusQuery {
    switch (_selectedStatusFilter) {
      case RoomStatusFilter.notSetUp:
        return 'UNPROVISIONED';
      case RoomStatusFilter.active:
        return 'ACTIVE';
      case RoomStatusFilter.revoked:
        return 'REVOKED';
      case RoomStatusFilter.all:
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
      final propertiesRes = await _propertiesRepository.getProperties(
        accessToken: token,
      );
      _properties = propertiesRes.data;

      final propertyMap = <String, String>{};
      for (final p in _properties) {
        propertyMap[p.id] = p.name;
      }

      final roomsRes = await _roomsRepository.getRooms(
        accessToken: token,
        status: _apiStatusQuery,
        propertyId: _selectedPropertyId,
      );
      _rooms = roomsRes.data;

      if (mounted) {
        setState(() {
          _propertyNames = propertyMap;
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
          _errorMessage = 'Failed to load rooms: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onStatusFilterChanged(RoomStatusFilter filter) {
    if (_selectedStatusFilter != filter) {
      setState(() {
        _selectedStatusFilter = filter;
      });
      _loadData();
    }
  }

  void _onPropertyFilterChanged(String? propertyId) {
    if (_selectedPropertyId != propertyId) {
      setState(() {
        _selectedPropertyId = propertyId;
      });
      _loadData();
    }
  }

  String _getPropertyDisplayName(RoomModel room) {
    if (room.propertyName != null && room.propertyName!.isNotEmpty) {
      return room.propertyName!;
    }
    if (_propertyNames.containsKey(room.propertyId)) {
      return _propertyNames[room.propertyId]!;
    }
    final match = _properties.cast<PropertyModel?>().firstWhere(
      (p) => p?.id == room.propertyId,
      orElse: () => null,
    );
    if (match != null && match.name.isNotEmpty) {
      return match.name;
    }
    return 'Test Hotel Downtown';
  }

  String _formatRoomDate(RoomModel room) {
    if (room.isActive && room.provisionedAt != null) {
      return 'Set up ${_formatDateString(room.provisionedAt!)}';
    }
    return 'Added ${_formatDateString(room.createdAt)}';
  }

  String _formatDateString(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sept',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '12 Sept 2026';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingRoom) {
      return AddRoomView(
        onRoomCreated: (newRoom) {
          setState(() {
            _isAddingRoom = false;
          });
          _loadData();
        },
        onCancel: () {
          setState(() {
            _isAddingRoom = false;
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

            // Header Section: Title Row + Status Filters + Property Filters (Sticky)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Floating Icon + Title + Subtitle + Action Buttons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Angled Floating Badge Icon
                            const TvSectionBadge(
                              icon: Icons.meeting_room_rounded,
                              gradientColors: [
                                Color(0xFFF472B6),
                                Color(0xFFD946EF),
                                Color(0xFF9333EA),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Title & Subtitle Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rooms',
                                    style: GoogleFonts.baloo2(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF9333EA),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'One row per TV. A room counts against the partner\'s room limit from the moment it is created, whether or not a device has been paired.',
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

                      // Right Action Buttons: [+ Add room]  [Add many]
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AddRoomButton(
                            onPressed: () async {
                              await context.push('/rooms/add');
                              _loadData();
                            },
                          ),
                          const SizedBox(width: 12),
                          _AddManyButton(
                            onPressed: () async {
                              await context.push('/rooms/add-many');
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Row 1: Status Filters (All, Not set up, Active, Revoked)
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected:
                            _selectedStatusFilter == RoomStatusFilter.all,
                        onTap: () =>
                            _onStatusFilterChanged(RoomStatusFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Not set up',
                        isSelected:
                            _selectedStatusFilter == RoomStatusFilter.notSetUp,
                        onTap: () =>
                            _onStatusFilterChanged(RoomStatusFilter.notSetUp),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Active',
                        isSelected:
                            _selectedStatusFilter == RoomStatusFilter.active,
                        onTap: () =>
                            _onStatusFilterChanged(RoomStatusFilter.active),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Revoked',
                        isSelected:
                            _selectedStatusFilter == RoomStatusFilter.revoked,
                        onTap: () =>
                            _onStatusFilterChanged(RoomStatusFilter.revoked),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Row 2: Property Filter Pills (Horizontal Scrollable)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'All properties',
                          isSelected: _selectedPropertyId == null,
                          onTap: () => _onPropertyFilterChanged(null),
                        ),
                        ..._properties.map((property) {
                          final isSelected = _selectedPropertyId == property.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _FilterPill(
                              label: property.name,
                              isSelected: isSelected,
                              onTap: () =>
                                  _onPropertyFilterChanged(property.id),
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

            // Scrollable Content: Loading, Error, or Rooms List
            Expanded(
              child: _isLoading
                  ? const Center(child: Spinner())
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
                  : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 40,
                            color: Color(0xFF71717A),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No rooms found.',
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
                      itemCount: _rooms.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final propName = _getPropertyDisplayName(room);
                        final dateText = _formatRoomDate(room);
                        final langDisplay = languageLabel(room.defaultLanguage);

                        return _RoomCard(
                          room: room,
                          propertyName: propName,
                          dateText: dateText,
                          languageDisplay: langDisplay.isEmpty
                              ? null
                              : langDisplay,
                          isInitiallyFocused: index == 0,
                          onTap: () {
                            widget.onRoomSelected?.call(room);
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

/// "+ Add room" Gradient Pill Button
class _AddRoomButton extends StatefulWidget {
  const _AddRoomButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddRoomButton> createState() => _AddRoomButtonState();
}

class _AddRoomButtonState extends State<_AddRoomButton> {
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
                  colors: [Color(0xFFD946EF), Color(0xFF9333EA)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF9333EA,
                    ).withValues(alpha: isHighlighted ? 0.55 : 0.38),
                    blurRadius: isHighlighted ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add room',
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

/// "Add many" Outline Pill Button
class _AddManyButton extends StatefulWidget {
  const _AddManyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddManyButton> createState() => _AddManyButtonState();
}

class _AddManyButtonState extends State<_AddManyButton> {
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 1.6),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_agenda_outlined,
                    color: Color(0xFF18181B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add many',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 15.5,
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

/// Filter Pill Chip for status and property filters
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
                    : (isHighlighted ? const Color(0xFFF8FAFC) : Colors.white),
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
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.22),
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
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
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

/// Room Card matching the design screenshot
class _RoomCard extends StatefulWidget {
  const _RoomCard({
    required this.room,
    required this.propertyName,
    required this.dateText,
    this.languageDisplay,
    this.isInitiallyFocused = false,
    required this.onTap,
  });

  final RoomModel room;
  final String propertyName;
  final String dateText;
  final String? languageDisplay;
  final bool isInitiallyFocused;
  final VoidCallback onTap;

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
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
                          color: const Color(
                            0xFF9333EA,
                          ).withValues(alpha: 0.38),
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
                          color: const Color(
                            0xFF9333EA,
                          ).withValues(alpha: 0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Door Icon Container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.door_front_door_rounded,
                      size: 24,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Room Label, Status Badge, Property + Language + Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.room.roomLabel,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _RoomStatusBadge(status: widget.room.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.propertyName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (widget.languageDisplay != null) ...[
                              const SizedBox(width: 14),
                              Text(
                                widget.languageDisplay!,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3F3F46),
                                ),
                              ),
                            ],
                            const SizedBox(width: 14),
                            Text(
                              widget.dateText,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
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

/// Status Badge for Rooms (Active, Not set up, Revoked)
class _RoomStatusBadge extends StatelessWidget {
  const _RoomStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final statusUpper = status.toUpperCase();
    final isActive = statusUpper == 'ACTIVE';
    final isNotSetUp =
        statusUpper == 'UNPROVISIONED' || statusUpper == 'NOT SET UP';

    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Active',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16A34A),
          ),
        ),
      );
    } else if (isNotSetUp) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Not set up',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Revoked',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
          ),
        ),
      );
    }
  }
}
