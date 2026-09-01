import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';

enum PartnerFilter {
  all,
  pendingApproval,
  active,
  suspended,
  rejected,
}

/// Partners View with interactive filter pills, real API data, and partner cards matching Plodyo UI design.
class PartnersView extends StatefulWidget {
  const PartnersView({
    super.key,
    this.partnersRepository,
    this.authRepository,
    this.onPartnerSelected,
  });

  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final ValueChanged<PartnerModel>? onPartnerSelected;

  @override
  State<PartnersView> createState() => _PartnersViewState();
}

class _PartnersViewState extends State<PartnersView> {
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  PartnerFilter _selectedFilter = PartnerFilter.all;
  List<PartnerModel> _partners = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _loadPartners();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case PartnerFilter.pendingApproval:
        return 'PENDING_APPROVAL';
      case PartnerFilter.active:
        return 'ACTIVE';
      case PartnerFilter.suspended:
        return 'SUSPENDED';
      case PartnerFilter.rejected:
        return 'REJECTED';
      case PartnerFilter.all:
        return null;
    }
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final response = await _partnersRepository.getPartners(
        accessToken: token,
        status: _apiStatusQuery,
      );

      if (mounted) {
        setState(() {
          _partners = response.data;
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
          _errorMessage = 'Failed to load partners: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged(PartnerFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadPartners();
    }
  }

  void _showPartnerDetails(PartnerModel partner) {
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
                Icons.apartment_rounded,
                color: Color(0xFF9333EA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                partner.name,
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
              _detailRow('Partner Type', partner.partnerType),
              const SizedBox(height: 8),
              _detailRow('Email', partner.contactEmail),
              if (partner.contactName != null && partner.contactName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow('Contact Name', partner.contactName!),
              ],
              if (partner.phone != null && partner.phone!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow('Phone', partner.phone!),
              ],
              const SizedBox(height: 8),
              _detailRow('Room Limit', '${partner.roomLimit} rooms'),
              const SizedBox(height: 8),
              _detailRow('Status', partner.status.replaceAll('_', ' ')),
              if (partner.rejectionReason != null && partner.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow('Rejection Reason', partner.rejectionReason!),
              ],
              if (partner.createdAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow('Registered', partner.createdAt),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (partner.isPendingApproval) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _promptRejectPartner(partner);
              },
              child: const Text('Reject'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _promptApprovePartner(partner);
              },
              child: const Text('Approve'),
            ),
          ] else if (partner.isActive) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _promptUpdateRoomLimit(partner);
              },
              child: const Text('Set Room Limit'),
            ),
          ],
        ],
      ),
    );
  }

  void _promptApprovePartner(PartnerModel partner) {
    final limitController = TextEditingController(text: '60');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve "${partner.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the maximum number of room TVs this partner is allowed to provision.',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Room Limit',
                filled: true,
                fillColor: const Color(0xFFFAF7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final limit = int.tryParse(limitController.text.trim()) ?? 0;
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.approvePartner(
                  accessToken: token,
                  partnerId: partner.id,
                  roomLimit: limit,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Partner "${partner.name}" approved successfully!'),
                      backgroundColor: const Color(0xFF15803D),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadPartners();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving partner: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _promptRejectPartner(PartnerModel partner) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject "${partner.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the reason for rejection (optional):',
              style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Missing business registration details',
                filled: true,
                fillColor: const Color(0xFFFAF7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.rejectPartner(
                  accessToken: token,
                  partnerId: partner.id,
                  rejectionReason: reason.isNotEmpty ? reason : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Partner "${partner.name}" rejected.'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadPartners();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting partner: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _promptUpdateRoomLimit(PartnerModel partner) {
    final limitController = TextEditingController(text: '${partner.roomLimit}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Room Limit for "${partner.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Room Limit',
                filled: true,
                fillColor: const Color(0xFFFAF7FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newLimit = int.tryParse(limitController.text.trim()) ?? partner.roomLimit;
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.updateRoomLimit(
                  accessToken: token,
                  partnerId: partner.id,
                  roomLimit: newLimit,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Room limit updated to $newLimit rooms.'),
                      backgroundColor: const Color(0xFF9333EA),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadPartners();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating room limit: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
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

  @override
  Widget build(BuildContext context) {
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
            // Top App Bar Branding: Logo + "Plodyo"
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
                  // Title: "Partners"
                  const Text(
                    'Partners',
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
                    'Venues on OnDemand. Approve new applications and set how many rooms each may sign in.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF71717A),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Filter Pills Row
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == PartnerFilter.all,
                        onTap: () => _onFilterChanged(PartnerFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Pending approval',
                        isSelected: _selectedFilter == PartnerFilter.pendingApproval,
                        onTap: () => _onFilterChanged(PartnerFilter.pendingApproval),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Active',
                        isSelected: _selectedFilter == PartnerFilter.active,
                        onTap: () => _onFilterChanged(PartnerFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Suspended',
                        isSelected: _selectedFilter == PartnerFilter.suspended,
                        onTap: () => _onFilterChanged(PartnerFilter.suspended),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Rejected',
                        isSelected: _selectedFilter == PartnerFilter.rejected,
                        onTap: () => _onFilterChanged(PartnerFilter.rejected),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Loading, Error, or List Content
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
                              onPressed: _loadPartners,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_partners.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No partners found.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF71717A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _partners.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final partner = _partners[index];
                        return _PartnerCard(
                          partner: partner,
                          onTap: () {
                            widget.onPartnerSelected?.call(partner);
                            _showPartnerDetails(partner);
                          },
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
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
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
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xFF9333EA).withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : (active
                        ? const Color(0xFFC084FC)
                        : const Color(0xFFE4E4E7)),
                width: widget.isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else if (active)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? const Color(0xFF9333EA)
                    : const Color(0xFF3F3F46),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerCard extends StatefulWidget {
  const _PartnerCard({
    required this.partner,
    required this.onTap,
  });

  final PartnerModel partner;
  final VoidCallback onTap;

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
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
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: active ? 1.012 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? const Color(0xFFC084FC)
                      : const Color(0xFFF1EBF5),
                  width: active ? 1.8 : 1.0,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.16),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Venue / Apartment Icon in container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 22,
                        color: Color(0xFF52525B),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Main Details (Name, Status Badge, Email, PartnerType, RoomLimit)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + Status Pill Row
                        Row(
                          children: [
                            Text(
                              widget.partner.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StatusBadge(status: widget.partner.status),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Subtitle info row: Email, Partner Type, Room count
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.partner.contactEmail,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF71717A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              widget.partner.partnerType == 'INDEPENDENT'
                                  ? 'Independent'
                                  : 'Host',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF71717A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.meeting_room_outlined,
                              size: 14,
                              color: Color(0xFF71717A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.partner.roomLimit} rooms allowed',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF71717A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Chevron Arrow
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA1A1AA),
                    size: 22,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case 'PENDING_APPROVAL':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        text = 'Pending approval';
        break;
      case 'ACTIVE':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        text = 'Active';
        break;
      case 'SUSPENDED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        text = 'Suspended';
        break;
      case 'REJECTED':
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
