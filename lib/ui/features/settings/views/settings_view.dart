import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../data/models/actor.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Settings View displaying authenticated TV account info, role badge, scope, and sign out flow.
class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    this.authRepository,
    this.name,
    this.email,
    this.role,
    this.scope,
    this.onSignOut,
  });

  final AuthRepository? authRepository;
  final String? name;
  final String? email;
  final String? role;
  final String? scope;
  final VoidCallback? onSignOut;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final AuthRepository _authRepository;
  bool _isLoading = true;

  String _name = '';
  String _email = '';
  String _role = '';
  String _scope = '';

  @override
  void initState() {
    super.initState();
    _name = _cleanName(widget.name ?? 'Dana Okafor');
    _email = widget.email ?? 'ops@grandhotel.com';
    _role = widget.role ?? 'Partner admin';
    _scope = widget.scope ?? 'All partners and properties';
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _loadUserDetails();
  }

  static String _cleanName(String rawName) {
    return rawName
        .replaceAll(RegExp(r'\s*\(\s*demo\s*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bdemo\b', caseSensitive: false), '')
        .trim();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);

    try {
      final meResponse = await _authRepository.getMe();
      final actor = meResponse.actor;

      if (mounted) {
        setState(() {
          final rawName = widget.name ??
              (actor.fullName.isNotEmpty ? actor.fullName : 'Dana Okafor');
          _name = _cleanName(rawName);
          _email = widget.email ??
              (actor.email.isNotEmpty ? actor.email : 'ops@grandhotel.com');
          _role = widget.role ??
              (actor.role.isNotEmpty ? _formatRole(actor.role) : 'Partner admin');
          _scope = widget.scope ?? _computeScope(actor);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final currentActor = _authRepository.currentUser;
        setState(() {
          final rawName = widget.name ?? currentActor?.fullName ?? 'Dana Okafor';
          _name = _cleanName(rawName);
          _email = widget.email ?? currentActor?.email ?? 'ops@grandhotel.com';
          _role = widget.role ??
              (currentActor != null
                  ? _formatRole(currentActor.role)
                  : 'Partner admin');
          _scope = widget.scope ??
              (currentActor != null
                  ? _computeScope(currentActor)
                  : 'All partners and properties');
          _isLoading = false;
        });
      }
    }
  }

  static String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'Super admin';
      case 'PARTNER_ADMIN':
        return 'Partner admin';
      case 'PROPERTY_ADMIN':
        return 'Property admin';
      default:
        return role;
    }
  }

  static String _computeScope(Actor actor) {
    if (actor.role == 'SUPER_ADMIN' ||
        (actor.partnerId == null && actor.propertyId == null)) {
      return 'All partners and properties';
    } else if (actor.role == 'PARTNER_ADMIN' || actor.propertyId == null) {
      return actor.partnerId != null
          ? 'Partner: ${actor.partnerId}'
          : 'Partner scope';
    } else {
      return actor.propertyId != null
          ? 'Property: ${actor.propertyId}'
          : 'Property scope';
    }
  }

  Future<void> _handleSignOut() async {
    await _authRepository.signOut();
    if (mounted) {
      if (widget.onSignOut != null) {
        widget.onSignOut!();
      } else {
        context.go('/sign-in');
      }
    }
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Sign out this TV?',
              style: TextStyle(
                color: Color(0xFF18181B),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          'Ends every session started from this login on this device. You will need to sign in again to access Plodyo TV.',
          style: TextStyle(
            color: Color(0xFF71717A),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleSignOut();
            },
            child: const Text(
              'Sign out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
            // Top App Bar Branding: Logo + "Plodyo" (kept at default padding)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: PlodyoHeader(padding: EdgeInsets.only(bottom: 12)),
            ),

            // Main Section UI with 10% horizontal screen spacing
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: "Settings"
                  const Text(
                    'Settings',
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
                    'The account this TV is signed in with.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Account Section Header
                  Row(
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2x2 Grid of Info Cards
                  Row(
                    children: [
                      // Card 1: Name
                      Expanded(
                        child: _SettingsInfoCard(
                          icon: Icons.person_outline_rounded,
                          label: 'Name',
                          value: _isLoading ? 'Loading...' : _name,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Card 2: Email
                      Expanded(
                        child: _SettingsInfoCard(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: _isLoading ? 'Loading...' : _email,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Card 3: Role
                      Expanded(
                        child: _SettingsInfoCard(
                          icon: Icons.shield_outlined,
                          label: 'Role',
                          value: _isLoading ? '...' : _role,
                          isBadge: true,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Card 4: Scope
                      Expanded(
                        child: _SettingsInfoCard(
                          icon: Icons.corporate_fare_outlined,
                          label: 'Scope',
                          value: _isLoading ? 'Loading...' : _scope,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Sign out Section
                  const Text(
                    'Sign out this TV',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ends every session started from this login, on every device.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign out Button
                  _SignOutButton(onPressed: _confirmSignOut),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsInfoCard extends StatefulWidget {
  const _SettingsInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isBadge = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isBadge;

  @override
  State<_SettingsInfoCard> createState() => _SettingsInfoCardState();
}

class _SettingsInfoCardState extends State<_SettingsInfoCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
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
              // Icon on the left
              Icon(
                widget.icon,
                size: 20,
                color: active ? const Color(0xFF9333EA) : const Color(0xFF71717A),
              ),
              const SizedBox(width: 14),

              // Label & Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (widget.isBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.value,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
                  width: active ? 1.4 : 1.0,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 13.5,
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
