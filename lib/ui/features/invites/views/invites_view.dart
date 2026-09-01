import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/invite_model.dart';
import '../../../../data/models/partner_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/invites_repository.dart';
import '../../../../data/repositories/partners_repository.dart';
import '../../../../data/repositories/properties_repository.dart';

enum InviteFilter {
  all,
  pending,
  accepted,
  expired,
  revoked,
}

/// Invites View with filter pills, "+ Invite someone" action, real API data, and interactive cards.
class InvitesView extends StatefulWidget {
  const InvitesView({
    super.key,
    this.invitesRepository,
    this.partnersRepository,
    this.propertiesRepository,
    this.authRepository,
    this.onInviteAction,
  });

  final InvitesRepository? invitesRepository;
  final PartnersRepository? partnersRepository;
  final PropertiesRepository? propertiesRepository;
  final AuthRepository? authRepository;
  final ValueChanged<String>? onInviteAction;

  @override
  State<InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<InvitesView> {
  late final InvitesRepository _invitesRepository;
  late final PartnersRepository _partnersRepository;
  late final PropertiesRepository _propertiesRepository;
  late final AuthRepository _authRepository;

  InviteFilter _selectedFilter = InviteFilter.all;
  List<InviteModel> _invites = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invitesRepository = widget.invitesRepository ?? sharedInvitesRepository;
    _partnersRepository = widget.partnersRepository ?? sharedPartnersRepository;
    _propertiesRepository = widget.propertiesRepository ?? sharedPropertiesRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _loadInvites();
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
            content: Text(msg.isNotEmpty ? msg : 'Invitation revoked for ${invite.email}'),
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

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    String selectedRole = 'PARTNER_ADMIN';
    String? selectedPartnerId;
    String? selectedPropertyId;

    final token = _authRepository.currentAuth?.accessToken ?? '';
    final actor = _authRepository.currentUser;

    List<PartnerModel> availablePartners = [];
    List<PropertyModel> availableProperties = [];

    try {
      final partnersRes = await _partnersRepository.getPartners(accessToken: token, status: 'ACTIVE');
      availablePartners = partnersRes.data;
      if (actor?.partnerId != null && actor!.partnerId!.isNotEmpty) {
        selectedPartnerId = actor.partnerId;
      } else if (availablePartners.isNotEmpty) {
        selectedPartnerId = availablePartners.first.id;
      }

      final propertiesRes = await _propertiesRepository.getProperties(
        accessToken: token,
        partnerId: selectedPartnerId,
        status: 'ACTIVE',
      );
      availableProperties = propertiesRes.data;
      if (availableProperties.isNotEmpty) {
        selectedPropertyId = availableProperties.first.id;
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Invite someone',
            style: TextStyle(
              color: Color(0xFF18181B),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the email address and role of the person you want to invite.',
                  style: TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFFAF7FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    filled: true,
                    fillColor: const Color(0xFFFAF7FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PARTNER_ADMIN',
                      child: Text('Partner admin'),
                    ),
                    DropdownMenuItem(
                      value: 'PROPERTY_ADMIN',
                      child: Text('Property admin'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
                if (availablePartners.isNotEmpty && actor?.partnerId == null) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPartnerId,
                    decoration: InputDecoration(
                      labelText: 'Partner',
                      filled: true,
                      fillColor: const Color(0xFFFAF7FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                    ),
                    items: availablePartners.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setDialogState(() => selectedPartnerId = val);
                        try {
                          final props = await _propertiesRepository.getProperties(
                            accessToken: token,
                            partnerId: val,
                            status: 'ACTIVE',
                          );
                          setDialogState(() {
                            availableProperties = props.data;
                            selectedPropertyId = availableProperties.isNotEmpty
                                ? availableProperties.first.id
                                : null;
                          });
                        } catch (_) {}
                      }
                    },
                  ),
                ],
                if (selectedRole == 'PROPERTY_ADMIN') ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPropertyId,
                    decoration: InputDecoration(
                      labelText: 'Property (Required for Property admin)',
                      filled: true,
                      fillColor: const Color(0xFFFAF7FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                    ),
                    items: availableProperties.map((prop) {
                      return DropdownMenuItem(
                        value: prop.id,
                        child: Text(prop.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPropertyId = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF71717A)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an email address.'),
                        backgroundColor: Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                final partnerId = selectedPartnerId ?? actor?.partnerId ?? '2c9a1f70-8d31-4a2b-9f10-6b7c8d9e0a1b';

                if (selectedRole == 'PROPERTY_ADMIN' &&
                    (selectedPropertyId == null || selectedPropertyId!.isEmpty)) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a property for this Property admin invite.'),
                        backgroundColor: Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                Navigator.of(dialogCtx).pop();

                try {
                  await _invitesRepository.createInvite(
                    accessToken: token,
                    email: email,
                    role: selectedRole,
                    partnerId: partnerId,
                    propertyId: selectedRole == 'PROPERTY_ADMIN' ? selectedPropertyId : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to $email'),
                        backgroundColor: const Color(0xFF9333EA),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _loadInvites();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sending invite: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
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
                  // Header Row: Title & Subtitle on Left, "+ Invite someone" on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title: "Invites"
                            const Text(
                              'Invites',
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
                              'People invited to administer a partner or one of its properties. Invites expire after seven days.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // "+ Invite someone" Pill Button
                      _InviteSomeoneButton(onPressed: _showInviteDialog),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Filter Pills Row
                  Row(
                    children: [
                      _FilterPill(
                        label: 'All',
                        isSelected: _selectedFilter == InviteFilter.all,
                        onTap: () => _onFilterChanged(InviteFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Pending',
                        isSelected: _selectedFilter == InviteFilter.pending,
                        onTap: () => _onFilterChanged(InviteFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Accepted',
                        isSelected: _selectedFilter == InviteFilter.accepted,
                        onTap: () => _onFilterChanged(InviteFilter.accepted),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Expired',
                        isSelected: _selectedFilter == InviteFilter.expired,
                        onTap: () => _onFilterChanged(InviteFilter.expired),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Revoked',
                        isSelected: _selectedFilter == InviteFilter.revoked,
                        onTap: () => _onFilterChanged(InviteFilter.revoked),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Loading, Error, or Invites List
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
                              onPressed: _loadInvites,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_invites.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No ${_selectedFilter.name} invites found.',
                          style: const TextStyle(
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
                      itemCount: _invites.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final invite = _invites[index];
                        return _InviteCard(
                          invite: invite,
                          onResend: () => _handleResend(invite),
                          onRevoke: () => _handleRevoke(invite),
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

class _InviteSomeoneButton extends StatefulWidget {
  const _InviteSomeoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_InviteSomeoneButton> createState() => _InviteSomeoneButtonState();
}

class _InviteSomeoneButtonState extends State<_InviteSomeoneButton> {
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
            scale: active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                border: active
                    ? Border.all(color: const Color(0xFFC084FC), width: 2.0)
                    : null,
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Invite someone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
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
      onFocusChange: (focused) => setState(() => _isFocused = focused),
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
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    final roleLabel = widget.invite.role == 'PROPERTY_ADMIN'
        ? 'Property admin'
        : 'Partner admin';

    final expiryText = widget.invite.expiresAt != null
        ? 'Expires ${_formatDate(widget.invite.expiresAt!)}'
        : 'Expires in 7 days';

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                  color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
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
              // Mail envelope icon
              const Icon(
                Icons.mail_outline_rounded,
                size: 20,
                color: Color(0xFF52525B),
              ),

              const SizedBox(width: 16),

              // Main Details (Email, Status Pill, Role and Expiry)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email + Status Badge Row
                    Row(
                      children: [
                        Text(
                          widget.invite.email,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _InviteStatusBadge(status: widget.invite.status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Subtitle: Role - Expiry
                    Text(
                      '$roleLabel - $expiryText',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF71717A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action Buttons: "Resend" and "Revoke" (only if pending)
              if (widget.invite.isPending) ...[
                _ActionPillButton(
                  icon: Icons.sync_rounded,
                  label: 'Resend',
                  onPressed: widget.onResend,
                ),
                const SizedBox(width: 8),
                _ActionPillButton(
                  icon: Icons.block_rounded,
                  label: 'Revoke',
                  onPressed: widget.onRevoke,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoString;
    }
  }
}

class _ActionPillButton extends StatefulWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
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
            scale: active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF9333EA).withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF9333EA)
                      : const Color(0xFFE4E4E7),
                  width: active ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.15),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 14,
                    color: active ? const Color(0xFF9333EA) : const Color(0xFF52525B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? const Color(0xFF9333EA) : const Color(0xFF3F3F46),
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
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        text = 'Expired';
        break;
      case 'REVOKED':
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        text = 'Revoked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
