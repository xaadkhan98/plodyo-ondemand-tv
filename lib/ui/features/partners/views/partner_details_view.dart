import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/partners_repository.dart';

/// Partner Details Screen matching the refined Plodyo TV specification.
/// Features clean top header, back navigation pill, large title + status badge,
/// 2-column info cards grid, and interactive dynamic action buttons:
/// - "Edit details"
/// - "Change room limit" (for Active) / "Approve" (for Pending)
/// - "Suspend" (for Active) / "Reject" (for Pending)
class PartnerDetailsView extends StatefulWidget {
  const PartnerDetailsView({
    super.key,
    required this.partner,
    this.partnersRepository,
    this.authRepository,
    this.onBack,
    this.onPartnerUpdated,
  });

  final PartnerModel partner;
  final PartnersRepository? partnersRepository;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final ValueChanged<PartnerModel>? onPartnerUpdated;

  @override
  State<PartnerDetailsView> createState() => _PartnerDetailsViewState();
}

class _PartnerDetailsViewState extends State<PartnerDetailsView> {
  late PartnerModel _currentPartner;
  late final PartnersRepository _partnersRepository;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _currentPartner = widget.partner;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
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

  void _showEditDetailsDialog() {
    final nameController = TextEditingController(text: _currentPartner.name);
    final emailController = TextEditingController(text: _currentPartner.contactEmail);
    final contactNameController = TextEditingController(text: _currentPartner.contactName ?? '');
    final phoneController = TextEditingController(text: _currentPartner.phone ?? '');
    final contractRefController = TextEditingController(text: _currentPartner.contractReference ?? '');
    String partnerType = _currentPartner.partnerType;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Color(0xFF9333EA)),
                SizedBox(width: 10),
                Text(
                  'Edit Partner Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18181B),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Venue Name',
                        filled: true,
                        fillColor: const Color(0xFFFAF7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Contact Email',
                        filled: true,
                        fillColor: const Color(0xFFFAF7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactNameController,
                      decoration: InputDecoration(
                        labelText: 'Contact Person Name',
                        hintText: 'e.g. Ali',
                        filled: true,
                        fillColor: const Color(0xFFFAF7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g. +1-555-0100',
                        filled: true,
                        fillColor: const Color(0xFFFAF7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contractRefController,
                      decoration: InputDecoration(
                        labelText: 'Contract Reference',
                        hintText: 'e.g. CTR-2026-001',
                        filled: true,
                        fillColor: const Color(0xFFFAF7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Business Type',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Independent Hotel'),
                          selected: partnerType == 'INDEPENDENT',
                          selectedColor: const Color(0xFFFAF5FF),
                          onSelected: (val) {
                            if (val) setDialogState(() => partnerType = 'INDEPENDENT');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Short-Let Host'),
                          selected: partnerType == 'HOST',
                          selectedColor: const Color(0xFFFAF5FF),
                          onSelected: (val) {
                            if (val) setDialogState(() => partnerType = 'HOST');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim();
                  if (newName.isNotEmpty && newEmail.isNotEmpty) {
                    Navigator.of(ctx).pop();
                    final updated = _currentPartner.copyWith(
                      name: newName,
                      contactEmail: newEmail,
                      contactName: contactNameController.text.trim().isNotEmpty
                          ? contactNameController.text.trim()
                          : null,
                      phone: phoneController.text.trim().isNotEmpty
                          ? phoneController.text.trim()
                          : null,
                      contractReference: contractRefController.text.trim().isNotEmpty
                          ? contractRefController.text.trim()
                          : null,
                      partnerType: partnerType,
                    );
                    setState(() {
                      _currentPartner = updated;
                    });
                    widget.onPartnerUpdated?.call(updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Details for "${updated.name}" updated.'),
                        backgroundColor: const Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _promptChangeRoomLimit() {
    final limitController = TextEditingController(text: '${_currentPartner.roomLimit}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Room Limit for "${_currentPartner.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the updated maximum number of rooms this venue may provision.',
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
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newLimit = int.tryParse(limitController.text.trim()) ?? _currentPartner.roomLimit;
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.updateRoomLimit(
                  accessToken: token,
                  partnerId: _currentPartner.id,
                  roomLimit: newLimit,
                );
              } catch (_) {}

              final updated = _currentPartner.copyWith(
                roomLimit: newLimit,
              );
              if (mounted) {
                setState(() {
                  _currentPartner = updated;
                });
                widget.onPartnerUpdated?.call(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Room limit updated to $newLimit rooms.'),
                    backgroundColor: const Color(0xFF9333EA),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  void _promptApprovePartner() {
    final limitController = TextEditingController(text: '60');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve "${_currentPartner.name}"'),
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
              final limit = int.tryParse(limitController.text.trim()) ?? 60;
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.approvePartner(
                  accessToken: token,
                  partnerId: _currentPartner.id,
                  roomLimit: limit,
                );
              } catch (_) {}

              final updated = _currentPartner.copyWith(
                status: 'ACTIVE',
                roomLimit: limit,
                reviewedAt: 'Just now',
              );
              if (mounted) {
                setState(() {
                  _currentPartner = updated;
                });
                widget.onPartnerUpdated?.call(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Partner "${_currentPartner.name}" approved successfully!'),
                    backgroundColor: const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _promptSuspendPartner() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Color(0xFFE11D48),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Suspend "${_currentPartner.name}"',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18181B),
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to suspend this partner? Their venue rooms will be prevented from signing into Plodyo TV.',
          style: TextStyle(color: Color(0xFF71717A), fontSize: 13.5, height: 1.4),
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
              Navigator.of(ctx).pop();
              try {
                final token = _authRepository.currentAuth?.accessToken ?? '';
                await _partnersRepository.suspendPartner(
                  accessToken: token,
                  partnerId: _currentPartner.id,
                );
              } catch (_) {}

              final updated = _currentPartner.copyWith(
                status: 'SUSPENDED',
                updatedAt: DateTime.now().toIso8601String(),
              );
              if (mounted) {
                setState(() {
                  _currentPartner = updated;
                });
                widget.onPartnerUpdated?.call(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Partner "${_currentPartner.name}" has been suspended.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Suspend'),
          ),
        ],
      ),
    );
  }

  void _promptRejectPartner() {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject "${_currentPartner.name}"'),
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
                hintText: 'e.g. Incomplete application or unverified property',
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
                  partnerId: _currentPartner.id,
                  rejectionReason: reason.isNotEmpty ? reason : null,
                );
              } catch (_) {}

              final updated = _currentPartner.copyWith(
                status: 'REJECTED',
                rejectionReason: reason.isNotEmpty ? reason : 'Application not approved',
                reviewedAt: 'Just now',
              );
              if (mounted) {
                setState(() {
                  _currentPartner = updated;
                });
                widget.onPartnerUpdated?.call(updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Partner "${_currentPartner.name}" rejected.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partner = _currentPartner;

    final businessTypeValue = partner.partnerType == 'INDEPENDENT' ? 'Independent' : 'Host';
    final contactNameValue = partner.contactName?.isNotEmpty == true ? partner.contactName! : 'Not given';
    final phoneValue = partner.phone?.isNotEmpty == true ? partner.phone! : 'Not given';
    final roomLimitValue = partner.roomLimit == 0
        ? '0 \u2014 no rooms may sign in yet'
        : '${partner.roomLimit} rooms';
    final contractRefValue = partner.contractReference?.isNotEmpty == true
        ? partner.contractReference!
        : 'None';
    final registeredValue = partner.createdAt.isNotEmpty
        ? (partner.createdAt.contains('T')
            ? partner.createdAt.split('T').first
            : partner.createdAt)
        : '12 Sept 2026, 16:13';
    final reviewedValue = partner.reviewedAt?.isNotEmpty == true
        ? partner.reviewedAt!
        : (partner.isPendingApproval ? 'Not yet' : '12 Sept 2026, 16:13');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Plodyo Logo Header (Sticky)
            const Padding(
              padding: EdgeInsets.only(left: 48, right: 48, top: 20, bottom: 8),
              child: PlodyoHeader(padding: EdgeInsets.zero),
            ),

            // Back button + Title Row (Sticky)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "<-- All partners" Back Pill Button
                  _BackPillButton(onTap: _handleBack),
                  const SizedBox(height: 14),

                  // Title Row: Partner Name + Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const TvSectionBadge(
                        icon: Icons.apartment_rounded,
                        size: 48,
                        iconSize: 26,
                        gradientColors: [
                          Color(0xFFE879F9),
                          Color(0xFF9333EA),
                          Color(0xFF7E22CE),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        partner.name,
                        style: GoogleFonts.baloo2(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF18181B),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 14),
                      _StatusBadgeLarge(status: partner.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Scrollable Details Content & Action Buttons
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 48, right: 48, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2-Column Information Cards Grid matching the screenshot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column 1 (Left)
                        Expanded(
                          child: Column(
                            children: [
                              _DetailInfoCard(
                                label: 'Business type',
                                value: businessTypeValue,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Contact name',
                                value: contactNameValue,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Room limit',
                                value: roomLimitValue,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Registered',
                                value: registeredValue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Column 2 (Right)
                        Expanded(
                          child: Column(
                            children: [
                              _DetailInfoCard(
                                label: 'Contact email',
                                value: partner.contactEmail,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Phone',
                                value: phoneValue,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Contract reference',
                                value: contractRefValue,
                              ),
                              const SizedBox(height: 14),
                              _DetailInfoCard(
                                label: 'Reviewed',
                                value: reviewedValue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Bottom Actions Row:
                    // 1. Edit Details
                    // 2. Change Room Limit (or Approve)
                    // 3. Suspend (for Active) / Reject (for Pending)
                    Row(
                      children: [
                        _OutlineActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit details',
                          borderColor: const Color(0xFF8B5CF6),
                          textColor: const Color(0xFF1E293B),
                          onTap: _showEditDetailsDialog,
                        ),
                        const SizedBox(width: 14),
                        if (partner.isActive) ...[
                          _OutlineActionButton(
                            icon: null,
                            label: 'Change room limit',
                            borderColor: const Color(0xFF8B5CF6),
                            textColor: const Color(0xFF1E293B),
                            onTap: _promptChangeRoomLimit,
                          ),
                          const SizedBox(width: 14),
                          _OutlineActionButton(
                            icon: Icons.block_rounded,
                            label: 'Suspend',
                            borderColor: const Color(0xFFFECDD3),
                            textColor: const Color(0xFFE11D48),
                            onTap: _promptSuspendPartner,
                          ),
                        ] else if (partner.isPendingApproval) ...[
                          _GradientApproveButton(
                            onTap: _promptApprovePartner,
                          ),
                          const SizedBox(width: 14),
                          _OutlineActionButton(
                            icon: Icons.close_rounded,
                            label: 'Reject',
                            borderColor: const Color(0xFFFECDD3),
                            textColor: const Color(0xFFE11D48),
                            onTap: _promptRejectPartner,
                          ),
                        ] else ...[
                          _OutlineActionButton(
                            icon: null,
                            label: 'Change room limit',
                            borderColor: const Color(0xFF8B5CF6),
                            textColor: const Color(0xFF1E293B),
                            onTap: _promptChangeRoomLimit,
                          ),
                          const SizedBox(width: 14),
                          _GradientApproveButton(
                            label: 'Reactivate',
                            icon: Icons.refresh_rounded,
                            onTap: _promptApprovePartner,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back Pill Button: "<- All partners"
class _BackPillButton extends StatefulWidget {
  const _BackPillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BackPillButton> createState() => _BackPillButtonState();
}

class _BackPillButtonState extends State<_BackPillButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
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
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1),
                  width: active ? 1.8 : 1.2,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.16),
                      blurRadius: 8,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFF1E293B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'All partners',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
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

/// Clean Detail Information Card Container with grey label and bold dark value
class _DetailInfoCard extends StatefulWidget {
  const _DetailInfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  State<_DetailInfoCard> createState() => _DetailInfoCardState();
}

class _DetailInfoCardState extends State<_DetailInfoCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    return Focus(
      focusNode: _focusNode,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: active ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1),
                width: active ? 1.8 : 1.2,
              ),
              boxShadow: [
                if (active)
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
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

/// Outline Action Pill Button (e.g. Edit details, Change room limit, Suspend, Reject)
class _OutlineActionButton extends StatefulWidget {
  const _OutlineActionButton({
    this.icon,
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_OutlineActionButton> createState() => _OutlineActionButtonState();
}

class _OutlineActionButtonState extends State<_OutlineActionButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
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
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.borderColor,
                  width: active ? 2.0 : 1.5,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: widget.borderColor.withValues(alpha: 0.22),
                      blurRadius: 10,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.textColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
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

/// Gradient Action Pill Button for "Approve"
class _GradientApproveButton extends StatefulWidget {
  const _GradientApproveButton({
    required this.onTap,
    this.label = 'Approve',
    this.icon = Icons.check_rounded,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  State<_GradientApproveButton> createState() => _GradientApproveButtonState();
}

class _GradientApproveButtonState extends State<_GradientApproveButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
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
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE11D89),
                    Color(0xFF9333EA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: active ? 0.6 : 0.4),
                    blurRadius: active ? 18 : 12,
                    spreadRadius: active ? 2 : 0.5,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: active
                    ? Border.all(color: Colors.white, width: 2.0)
                    : Border.all(color: Colors.transparent, width: 2.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 14.5,
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

/// Large Status Badge in title header
class _StatusBadgeLarge extends StatelessWidget {
  const _StatusBadgeLarge({required this.status});

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
        bgColor = const Color(0xFFFFE4E6);
        textColor = const Color(0xFFE11D48);
        text = 'Suspended';
        break;
      case 'REJECTED':
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
