import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/rooms_repository.dart';
import 'add_room_view.dart';

enum RoomFilter {
  all,
  notSetUp,
  active,
  revoked,
}

/// Rooms View with filter pills, "+ Add room" action, real API data, and interactive room cards.
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

  RoomFilter _selectedFilter = RoomFilter.all;
  List<RoomModel> _rooms = [];
  Map<String, String> _propertyNames = {};
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isAddingRoom;

  @override
  void initState() {
    super.initState();
    _roomsRepository = widget.roomsRepository ?? sharedRoomsRepository;
    _propertiesRepository = widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _isAddingRoom = widget.initialIsAddingRoom;
    _loadRooms();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case RoomFilter.notSetUp:
        return 'UNPROVISIONED';
      case RoomFilter.active:
        return 'ACTIVE';
      case RoomFilter.revoked:
        return 'REVOKED';
      case RoomFilter.all:
        return null;
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final roomsFuture = _roomsRepository.getRooms(
        accessToken: token,
        status: _apiStatusQuery,
      );
      final propertiesFuture = _propertiesRepository.getProperties(
        accessToken: token,
      );

      final results = await Future.wait([roomsFuture, propertiesFuture]);
      final roomsRes = results[0] as dynamic;
      final propertiesRes = results[1] as dynamic;

      final propertyMap = <String, String>{};
      if (propertiesRes.data is List<PropertyModel>) {
        for (final p in propertiesRes.data as List<PropertyModel>) {
          propertyMap[p.id] = p.name;
        }
      }

      if (mounted) {
        setState(() {
          _rooms = roomsRes.data as List<RoomModel>;
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

  void _onFilterChanged(RoomFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadRooms();
    }
  }

  Future<void> _handleDeleteRoom(RoomModel room) async {
    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final msg = await _roomsRepository.deleteRoom(
        accessToken: token,
        roomId: room.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Room deleted.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadRooms();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting room: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRoomDetails(RoomModel room) {
    final propName = _propertyNames[room.propertyId] ?? 'Property #${room.propertyId}';

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
                Icons.tv_rounded,
                color: Color(0xFF9333EA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                room.roomLabel,
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
              _buildDetailRow('Property', propName),
              const SizedBox(height: 8),
              _buildDetailRow('Status', _statusLabel(room.status)),
              const SizedBox(height: 8),
              if (room.defaultLanguage != null && room.defaultLanguage!.isNotEmpty) ...[
                _buildDetailRow('Language Override', room.defaultLanguage!),
                const SizedBox(height: 8),
              ],
              if (room.provisionedAt != null && room.provisionedAt!.isNotEmpty) ...[
                _buildDetailRow('Provisioned', room.provisionedAt!),
                const SizedBox(height: 8),
              ],
              if (room.lastSeenAt != null && room.lastSeenAt!.isNotEmpty) ...[
                _buildDetailRow('Last Seen', room.lastSeenAt!),
                const SizedBox(height: 8),
              ],
              _buildDetailRow('Created', room.createdAt),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF71717A)),
            ),
          ),
          if (room.isUnprovisioned)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _handleDeleteRoom(room);
              },
              child: const Text('Delete Room'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'UNPROVISIONED':
        return 'Not set up';
      case 'ACTIVE':
        return 'Active';
      case 'REVOKED':
        return 'Revoked';
      default:
        return status;
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
          _loadRooms();
        },
        onCancel: () {
          setState(() {
            _isAddingRoom = false;
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
                  // Header Row: Title & Subtitle on Left, "+ Add room" on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title: "Rooms"
                            const Text(
                              'Rooms',
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
                              'One row per TV. A room counts against the partner\'s room limit from the moment it is created, whether or not a device has been paired.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF71717A),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // "+ Add room" Pill Button
                      _AddRoomButton(
                        onPressed: () {
                          setState(() {
                            _isAddingRoom = true;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Filter Pills Row (All, Not set up, Active, Revoked)
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == RoomFilter.all,
                        onTap: () => _onFilterChanged(RoomFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Not set up',
                        isSelected: _selectedFilter == RoomFilter.notSetUp,
                        onTap: () => _onFilterChanged(RoomFilter.notSetUp),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Active',
                        isSelected: _selectedFilter == RoomFilter.active,
                        onTap: () => _onFilterChanged(RoomFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Revoked',
                        isSelected: _selectedFilter == RoomFilter.revoked,
                        onTap: () => _onFilterChanged(RoomFilter.revoked),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Loading, Error, or Rooms List
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
                              onPressed: _loadRooms,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_rooms.isEmpty)
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
                              'No rooms yet. Add one to get a TV signed in.',
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
                      itemCount: _rooms.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final propName = _propertyNames[room.propertyId] ?? 'Property #${room.propertyId}';
                        return _RoomCard(
                          room: room,
                          propertyName: propName,
                          onTap: () {
                            widget.onRoomSelected?.call(room);
                            _showRoomDetails(room);
                          },
                          onDelete: room.isUnprovisioned ? () => _handleDeleteRoom(room) : null,
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
    final active = widget.isSelected || _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
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
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : (active ? const Color(0xFFC084FC) : const Color(0xFFE4E4E7)),
                width: widget.isSelected ? 1.4 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : const Color(0xFF71717A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddRoomButton extends StatefulWidget {
  const _AddRoomButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_AddRoomButton> createState() => _AddRoomButtonState();
}

class _AddRoomButtonState extends State<_AddRoomButton> {
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
                event.logicalKey == LogicalKeyboardKey.enter)) {
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
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+ Add room',
                    style: TextStyle(
                      fontSize: 13.5,
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

class _RoomCard extends StatefulWidget {
  const _RoomCard({
    required this.room,
    required this.propertyName,
    required this.onTap,
    this.onDelete,
  });

  final RoomModel room;
  final String propertyName;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
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
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: active ? 1.012 : 1.0,
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
                  width: active ? 1.6 : 1.0,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // TV Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF4F4F5)),
                    ),
                    child: const Icon(
                      Icons.tv_rounded,
                      size: 22,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Room Label and Property Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.room.roomLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildStatusBadge(widget.room.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.propertyName} · Language: ${widget.room.defaultLanguage ?? "Default"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF71717A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Button
                  if (widget.room.isUnprovisioned && widget.onDelete != null)
                    TextButton(
                      onPressed: widget.onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      child: const Text('Delete'),
                    ),

                  const SizedBox(width: 6),

                  // Arrow Chevron
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFA1A1AA),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'UNPROVISIONED':
        bg = const Color(0xFFF4F4F5);
        fg = const Color(0xFF71717A);
        label = 'Not set up';
        break;
      case 'ACTIVE':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Active';
        break;
      case 'REVOKED':
      default:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Revoked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
