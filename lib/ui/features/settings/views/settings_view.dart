import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/actor.dart';
import '../../../../data/models/roles.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Settings View displaying authenticated TV account info, role badge, scope, and sign out flow
/// matching the exact Plodyo TV specification and design aesthetics.
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
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    Actor? actor;
    try {
      actor = (await _authRepository.getMe()).actor;
    } catch (_) {
      // Offline or expired: fall back to the account this session signed in with.
      actor = _authRepository.currentUser;
    }
    if (!mounted) return;
    setState(() {
      _name = widget.name ?? _orNotSet(actor?.fullName);
      _email = widget.email ?? _orNotSet(actor?.email);
      _role = widget.role ?? (actor == null ? 'Not set' : roleLabel(actor.role));
      _scope = widget.scope ?? (actor == null ? 'Not set' : _describeScope(actor));
      _isLoading = false;
    });
  }

  static String _orNotSet(String? value) => (value == null || value.isEmpty) ? 'Not set' : value;

  // Ids are shown in full: they are what support asks for when a scope looks wrong.
  static String _describeScope(Actor actor) {
    if (actor.partnerId == null) return 'All partners and properties';
    if (actor.propertyId == null) return 'Partner ${actor.partnerId}';
    return 'Property ${actor.propertyId}';
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
        title: const Row(
          children: [
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

            // Header Row (Sticky): Floating Angled Settings Badge Icon + Title + Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Settings Badge: Floating vertically & angled to the left (-8 degrees)
                  const TvSectionBadge(
                    icon: Icons.settings_rounded,
                    gradientColors: [
                      Color(0xFFF472B6),
                      Color(0xFFE879F9),
                      Color(0xFF9333EA),
                      Color(0xFF7E22CE),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: GoogleFonts.baloo2(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFA855F7),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The account this console session is signed in with.',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Scrollable Body Content: Account 2x2 Grid + Sign Out
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section Header
                    Row(
                      children: [
                        Text(
                          'Account',
                          style: GoogleFonts.baloo2(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF18181B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_isLoading) ...[
                          const SizedBox(width: 12),
                          const PlodyoThreeDotsLoading(
                            dotSize: 6,
                            spacing: 4,
                            bounceHeight: 4,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

            // 2x2 Grid of Account Info Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1
                Expanded(
                  child: Column(
                    children: [
                      // Card 1: Name
                      _SettingsInfoCard(
                        icon: Icons.person_outline_rounded,
                        label: 'Name',
                        value: _isLoading ? 'Loading...' : _name,
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Role
                      _SettingsInfoCard(
                        icon: Icons.shield_outlined,
                        label: 'Role',
                        value: _isLoading ? '...' : _role,
                        isBadge: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Column 2
                Expanded(
                  child: Column(
                    children: [
                      // Card 2: Email
                      _SettingsInfoCard(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: _isLoading ? 'Loading...' : _email,
                      ),
                      const SizedBox(height: 16),

                      // Card 4: Scope
                      _SettingsInfoCard(
                        icon: Icons.domain_rounded,
                        label: 'Scope',
                        value: _isLoading ? 'Loading...' : _scope,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Sign out Section
            const Text(
              'Sign out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ends every session started from this login, on every device.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Sign out Outlined Button
            _SignOutButton(onPressed: _confirmSignOut),

            const SizedBox(height: 48),
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

/// Styled Information Card for the Settings 2x2 Grid
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
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFFCBD5E1),
              width: active ? 2.0 : 1.3,
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 1.5,
                  offset: const Offset(0, 4),
                )
              else ...const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
                BoxShadow(
                  color: Color(0x059333EA),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container on the left
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFF3E8FF)
                      : const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFDDD6FE)
                        : const Color(0xFFF1EBF5),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: const Color(0xFF9333EA),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Label & Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.isBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          widget.value,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
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

/// Outlined "Sign out" Pill Button with focus/hover effects
class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
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
    final isFocused = _focusNode.hasFocus;
    final active = isFocused || _isHovered;

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
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: active
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFFCA5A5),
                  width: active ? 2.0 : 1.4,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 1.5),
                    ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
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
