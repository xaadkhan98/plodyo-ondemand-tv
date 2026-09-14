import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/invite_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/invites_repository.dart';

enum InviteFilter {
  all,
  pending,
  accepted,
  expired,
  revoked,
}

/// Invites View matching the refined Plodyo TV specification.
/// Features angled floating badge icon animation, custom filter pills,
/// styled invite cards with status badges and Resend/Revoke actions,
/// and direct navigation to dedicated Invite Someone screen.
class InvitesView extends StatefulWidget {
  const InvitesView({
    super.key,
    this.invitesRepository,
    this.authRepository,
    this.onInviteAction,
  });

  final InvitesRepository? invitesRepository;
  final AuthRepository? authRepository;
  final ValueChanged<String>? onInviteAction;

  @override
  State<InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<InvitesView> {
  late final InvitesRepository _invitesRepository;
  late final AuthRepository _authRepository;

  InviteFilter _selectedFilter = InviteFilter.all;
  List<InviteModel> _invites = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invitesRepository = widget.invitesRepository ?? sharedInvitesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    _loadInvites();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _apiStatusQuery {
    switch (_selectedFilter) {
      case InviteFilter.pending:
        return 'PENDING';
      case InviteFilter.accepted:
        return 'ACCEPTED';
      case InviteFilter.expired:
        return 'EXPIRED';
      case InviteFilter.revoked:
        return 'REVOKED';
      case InviteFilter.all:
        return null;
    }
  }

  List<InviteModel> get _filteredInvites {
    if (_selectedFilter == InviteFilter.all) {
      return _invites;
    }
    return _invites.where((inv) {
      switch (_selectedFilter) {
        case InviteFilter.pending:
          return inv.status.toUpperCase() == 'PENDING';
        case InviteFilter.accepted:
          return inv.status.toUpperCase() == 'ACCEPTED';
        case InviteFilter.expired:
          return inv.status.toUpperCase() == 'EXPIRED';
        case InviteFilter.revoked:
          return inv.status.toUpperCase() == 'REVOKED';
        case InviteFilter.all:
          return true;
      }
    }).toList();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final response = await _invitesRepository.getInvites(
        accessToken: token,
        status: _apiStatusQuery,
      );

      if (mounted) {
        setState(() {
          _invites = response.data;
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
          _errorMessage = 'Failed to load invites: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterChanged(InviteFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadInvites();
    }
  }

  Future<void> _handleResend(InviteModel invite) async {
    widget.onInviteAction?.call('resend_${invite.id}');
    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      await _invitesRepository.resendInvite(
        accessToken: token,
        inviteId: invite.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation resent to ${invite.email}'),
            backgroundColor: const Color(0xFF9333EA),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending invite: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRevoke(InviteModel invite) async {
    widget.onInviteAction?.call('revoke_${invite.id}');
    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final msg = await _invitesRepository.revokeInvite(
        accessToken: token,
        inviteId: invite.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty
                ? msg
                : 'Invitation revoked for ${invite.email}'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error revoking invite: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final invitesToDisplay = _filteredInvites;

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

            // Title Row & Filter Controls Section (Sticky)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row: Angled Floating Badge Icon + "Invites" Title + "+ Invite someone" Action Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Angled Floating Mail Badge Icon
                            const TvSectionBadge(
                              icon: Icons.mail_rounded,
                              gradientColors: [
                                Color(0xFFD946EF), // Vibrant Magenta
                                Color(0xFF9333EA), // Royal Purple
                              ],
                            ),
                            const SizedBox(width: 18),

                            // Title & Subtitle Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Invites',
                                    style: GoogleFonts.baloo2(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF9333EA),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'People invited to administer a partner or one of its properties. Invites expire after seven days.',
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

                      // Right "+ Invite someone" Action Button
                      _InviteSomeoneButton(
                        onPressed: () async {
                          await context.push('/invites/add');
                          _loadInvites();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Filter Chips / Tabs Row
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == InviteFilter.all,
                        onTap: () => _onFilterChanged(InviteFilter.all),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Pending',
                        isSelected: _selectedFilter == InviteFilter.pending,
                        onTap: () => _onFilterChanged(InviteFilter.pending),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Accepted',
                        isSelected: _selectedFilter == InviteFilter.accepted,
                        onTap: () => _onFilterChanged(InviteFilter.accepted),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Expired',
                        isSelected: _selectedFilter == InviteFilter.expired,
                        onTap: () => _onFilterChanged(InviteFilter.expired),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(
                        label: 'Revoked',
                        isSelected: _selectedFilter == InviteFilter.revoked,
                        onTap: () => _onFilterChanged(InviteFilter.revoked),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Scrollable Content: Loading, Error, or Invites List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: PlodyoPageLoading(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626), size: 36),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Color(0xFF71717A), fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _loadInvites,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : invitesToDisplay.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mark_email_unread_outlined,
                                    size: 48,
                                    color: const Color(0xFF9333EA).withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No ${_selectedFilter == InviteFilter.all ? "" : "${_selectedFilter.name} "}invites found.',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF18181B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 48, right: 48, bottom: 32),
                              itemCount: invitesToDisplay.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final invite = invitesToDisplay[index];
                                return _InviteCard(
                                  invite: invite,
                                  onResend: () => _handleResend(invite),
                                  onRevoke: () => _handleRevoke(invite),
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

/// "+ Invite someone" Action Button
class _InviteSomeoneButton extends StatefulWidget {
  const _InviteSomeoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_InviteSomeoneButton> createState() => _InviteSomeoneButtonState();
}

class _InviteSomeoneButtonState extends State<_InviteSomeoneButton> {
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
            scale: isHighlighted ? 1.05 : 1.0,
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA)
                        .withValues(alpha: isHighlighted ? 0.55 : 0.38),
                    blurRadius: isHighlighted ? 18 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Invite someone',
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

/// Filter Pill Chip with subtle hover and selection styles matching Plodyo TV
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

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

    final backgroundColor = widget.isSelected
        ? const Color(0xFFFAF5FF)
        : (active ? const Color(0xFFFBF8FF) : Colors.white);

    final borderColor = widget.isSelected
        ? const Color(0xFF8B5CF6)
        : (active ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1));

    final textColor = widget.isSelected || active
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF1E293B);

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
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
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 1.6 : 1.2,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : (active
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 1.5),
                            ),
                          ]),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Invite List Card Item matching design screenshot
class _InviteCard extends StatefulWidget {
  const _InviteCard({
    required this.invite,
    required this.onResend,
    required this.onRevoke,
  });

  final InviteModel invite;
  final VoidCallback onResend;
  final VoidCallback onRevoke;

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final isHighlighted = isFocused || _isHovered;

    String subtitleText = 'Partner admin';
    if (widget.invite.isPending) {
      if (widget.invite.expiresAt != null) {
        subtitleText =
            'Partner admin \u00B7 Expires ${_formatDate(widget.invite.expiresAt)}';
      } else {
        subtitleText = 'Partner admin \u00B7 Expires in 7 days';
      }
    } else if (widget.invite.isAccepted) {
      final date = widget.invite.acceptedAt ?? widget.invite.createdAt;
      subtitleText =
          'Partner admin \u00B7 Accepted ${_formatDate(date)}';
    } else if (widget.invite.isRevoked) {
      final date = widget.invite.sentAt ?? widget.invite.createdAt;
      subtitleText =
          'Partner admin \u00B7 Sent ${_formatDate(date)}';
    } else if (widget.invite.isExpired) {
      final date = widget.invite.expiresAt ?? widget.invite.createdAt;
      subtitleText =
          'Partner admin \u00B7 Expired ${_formatDate(date)}';
    }

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
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
                      color: const Color(0xFF9333EA).withValues(alpha: 0.38),
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
                      color: const Color(0xFF9333EA).withValues(alpha: 0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Left mail envelope icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  size: 24,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 18),

              // Email + Status Badge + Subtitle Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.invite.email,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181B),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _InviteStatusBadge(status: widget.invite.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitleText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action buttons (Resend & Revoke) only for Pending invites
              if (widget.invite.isPending) ...[
                _ResendPillButton(onPressed: widget.onResend),
                const SizedBox(width: 10),
                _RevokePillButton(onPressed: widget.onRevoke),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Resend" Action Pill Button
class _ResendPillButton extends StatefulWidget {
  const _ResendPillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ResendPillButton> createState() => _ResendPillButtonState();
}

class _ResendPillButtonState extends State<_ResendPillButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
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
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Resend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

/// "Revoke" Action Pill Button
class _RevokePillButton extends StatefulWidget {
  const _RevokePillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RevokePillButton> createState() => _RevokePillButtonState();
}

class _RevokePillButtonState extends State<_RevokePillButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _focusNode.hasFocus || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
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
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isHighlighted ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                  width: 1.5,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Revoke',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
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

/// Status Badge (Pending, Accepted, Revoked, Expired)
class _InviteStatusBadge extends StatelessWidget {
  const _InviteStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status.toUpperCase()) {
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        text = 'Pending';
        break;
      case 'ACCEPTED':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        text = 'Accepted';
        break;
      case 'EXPIRED':
        bgColor = const Color(0xFFF4F4F5);
        textColor = const Color(0xFF71717A);
        text = 'Expired';
        break;
      case 'REVOKED':
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        text = 'Revoked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
