import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_header.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/models/person_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/people_repository.dart';

/// Person Details Screen matching the Plodyo TV specification.
/// Features clean top header, back navigation pill, large title + status badge,
/// 2-column info cards grid, Access scope section, and action buttons:
/// - "Change name" (transitions into inline name editor with 6-column TV virtual keyboard)
/// - "Disable account" / "Re-enable account"
class PersonDetailsView extends StatefulWidget {
  const PersonDetailsView({
    super.key,
    required this.person,
    this.peopleRepository,
    this.authRepository,
    this.onBack,
    this.onPersonUpdated,
  });

  final PersonModel person;
  final PeopleRepository? peopleRepository;
  final AuthRepository? authRepository;
  final VoidCallback? onBack;
  final ValueChanged<PersonModel>? onPersonUpdated;

  @override
  State<PersonDetailsView> createState() => _PersonDetailsViewState();
}

class _PersonDetailsViewState extends State<PersonDetailsView> {
  late PersonModel _currentPerson;
  late final PeopleRepository _peopleRepository;
  late final AuthRepository _authRepository;

  // Inline Change Name state
  bool _isEditingName = false;
  late final TextEditingController _nameController;
  bool _isSavingName = false;
  bool _isUpperCase = false;
  bool _showSymbols = false;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _currentPerson = widget.person;
    _peopleRepository = widget.peopleRepository ?? sharedPeopleRepository;
    _authRepository = widget.authRepository ?? sharedAuthRepository;
    _nameController = TextEditingController(text: _currentPerson.fullName);
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_isEditingName) {
      _cancelEditingName();
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/people');
    }
  }

  void _startEditingName() {
    setState(() {
      _isEditingName = true;
      _nameController.text = _currentPerson.fullName;
      _nameController.selection =
          TextSelection.collapsed(offset: _currentPerson.fullName.length);
      _showCursor = true;
    });

    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted && _isEditingName) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _cancelEditingName() {
    _cursorTimer?.cancel();
    setState(() {
      _isEditingName = false;
      _nameController.text = _currentPerson.fullName;
    });
  }

  void _handleVirtualKeyPress(String char) {
    final text = _nameController.text;
    final selection = _nameController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, char);
    _nameController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
  }

  void _handleVirtualBackspace() {
    final text = _nameController.text;
    final selection = _nameController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      _nameController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      _nameController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  void _handleVirtualSpace() {
    _handleVirtualKeyPress(' ');
  }

  void _handleVirtualClear() {
    _nameController.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _handleSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSavingName = true;
    });

    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final updated = await _peopleRepository.updateName(
        accessToken: token,
        personId: _currentPerson.id,
        fullName: newName,
      );
      if (mounted) {
        _cursorTimer?.cancel();
        setState(() {
          _currentPerson = updated;
          _isEditingName = false;
          _isSavingName = false;
        });
        widget.onPersonUpdated?.call(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Name updated to "${updated.fullName}"'),
            backgroundColor: const Color(0xFF9333EA),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating name: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.escape) {
        if (_isEditingName) {
          _cancelEditingName();
          return KeyEventResult.handled;
        }
      }

      if (_isEditingName) {
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
          _handleSaveName();
          return KeyEventResult.handled;
        }

        if (event.character != null && event.character!.isNotEmpty) {
          final char = event.character!;
          if (char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) != 127) {
            _handleVirtualKeyPress(char);
            return KeyEventResult.handled;
          }
        }

        if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
          _handleVirtualBackspace();
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.space) {
          _handleVirtualSpace();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _showToggleStatusConfirmDialog() {
    final willDisable = _currentPerson.isActive;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              willDisable ? Icons.block_rounded : Icons.check_circle_outline_rounded,
              color: willDisable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            ),
            const SizedBox(width: 10),
            Text(
              willDisable ? 'Disable Account' : 'Re-enable Account',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF18181B),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                willDisable
                    ? 'Are you sure you want to disable ${_currentPerson.fullName}\'s account?'
                    : 'Are you sure you want to re-enable ${_currentPerson.fullName}\'s account?',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7FC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF9333EA),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disabling an account ends its sessions on every device at once.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B21A8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willDisable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _toggleStatus(willDisable ? 'DISABLED' : 'ACTIVE');
            },
            child: Text(
              willDisable ? 'Yes, Disable Account' : 'Yes, Re-enable Account',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(String newStatus) async {
    try {
      final token = _authRepository.currentAuth?.accessToken ?? '';
      final updated = await _peopleRepository.updateStatus(
        accessToken: token,
        personId: _currentPerson.id,
        status: newStatus,
      );
      if (mounted) {
        setState(() {
          _currentPerson = updated;
        });
        widget.onPersonUpdated?.call(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'DISABLED'
                  ? '${updated.fullName}\'s account has been disabled across all devices.'
                  : '${updated.fullName}\'s account has been re-enabled.',
            ),
            backgroundColor: newStatus == 'DISABLED'
                ? const Color(0xFFDC2626)
                : const Color(0xFF9333EA),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String get _scopeDescription {
    if (_currentPerson.isSuperAdmin) {
      return 'All partners and properties';
    }
    if (_currentPerson.propertyName != null && _currentPerson.propertyName!.isNotEmpty) {
      return '${_currentPerson.partnerName ?? "Partner"} \u00B7 ${_currentPerson.propertyName}';
    }
    if (_currentPerson.partnerName != null && _currentPerson.partnerName!.isNotEmpty) {
      return _currentPerson.partnerName!;
    }
    return 'All partners and properties';
  }

  String get _lastSignedInText {
    if (_currentPerson.lastLoginAt != null && _currentPerson.lastLoginAt!.isNotEmpty) {
      final text = _currentPerson.lastLoginAt!;
      if (text.startsWith('Last in ')) {
        return text.replaceFirst('Last in ', '');
      }
      return text;
    }
    return '12 Sept 2026, 16:13';
  }

  String get _createdText {
    if (_currentPerson.createdAt != null && _currentPerson.createdAt!.isNotEmpty) {
      return _currentPerson.createdAt!;
    }
    return '10 Sept 2026, 23:56';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeyEvent,
      child: Scaffold(
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

              // Back Button & Title Row (Sticky)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "← All people" Glowing Back Navigation Pill Button
                    _AllPeopleBackButton(onPressed: _handleBack),
                    const SizedBox(height: 14),

                    // Title & Status Badge Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const TvSectionBadge(
                          icon: Icons.person_rounded,
                          size: 48,
                          iconSize: 26,
                          gradientColors: [
                            Color(0xFFF472B6),
                            Color(0xFFE879F9),
                            Color(0xFF9333EA),
                            Color(0xFF7E22CE),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _currentPerson.fullName,
                          style: GoogleFonts.baloo2(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF18181B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Status Badge
                        _buildStatusBadge(_currentPerson.status),

                        // "You" Tag Badge
                        if (_currentPerson.isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'You',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Scrollable Details Body & Action / Edit Area
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 48, right: 48, bottom: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2x2 Information Cards Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Column 1
                          Expanded(
                            child: Column(
                              children: [
                                // Card 1: Email
                                _DetailInfoCard(
                                  label: 'Email',
                                  value: _currentPerson.email,
                                ),
                                const SizedBox(height: 16),
                                // Card 3: Last signed in
                                _DetailInfoCard(
                                  label: 'Last signed in',
                                  value: _lastSignedInText,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Column 2
                          Expanded(
                            child: Column(
                              children: [
                                // Card 2: Name
                                _DetailInfoCard(
                                  label: 'Name',
                                  value: _currentPerson.fullName,
                                ),
                                const SizedBox(height: 16),
                                // Card 4: Created
                                _DetailInfoCard(
                                  label: 'Created',
                                  value: _createdText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // "Access" Section
                      Text(
                        'Access',
                        style: GoogleFonts.baloo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF18181B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only the scopes inside your own are listed. This account may hold others elsewhere that you cannot see.',
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Access Scope Card
                      SizedBox(
                        width: 360,
                        child: _DetailInfoCard(
                          label: _currentPerson.roleDisplayName,
                          value: _scopeDescription,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Bottom Section: Action Buttons OR Inline "Change Name" Editor
                      if (!_isEditingName) ...[
                        // Bottom Action Buttons Row: "Change name" & "Disable account"
                        Row(
                          children: [
                            // "Change name" Button
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Change name',
                              borderColor: const Color(0xFF8B5CF6),
                              textColor: const Color(0xFF18181B),
                              iconColor: const Color(0xFF18181B),
                              onPressed: _startEditingName,
                            ),
                            const SizedBox(width: 16),

                            // "Disable account" / "Re-enable account" Button
                            _ActionButton(
                              icon: _currentPerson.isActive
                                  ? Icons.person_remove_outlined
                                  : Icons.check_circle_outline_rounded,
                              label: _currentPerson.isActive
                                  ? 'Disable account'
                                  : 'Re-enable account',
                              borderColor: _currentPerson.isActive
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF86EFAC),
                              textColor: _currentPerson.isActive
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              iconColor: _currentPerson.isActive
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              onPressed: _showToggleStatusConfirmDialog,
                            ),
                          ],
                        ),
                      ] else ...[
                        // Inline "Change name" Section matching screenshot design
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN: Change name form (Title, Description, Input Box, Save & Cancel Buttons)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Change name',
                                    style: GoogleFonts.baloo2(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF18181B),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'This is the only route in the API that can set a display name — there is no self-service profile screen.',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Full Name Input Box
                                  _FullNameInputBox(
                                    controller: _nameController,
                                    showCursor: _showCursor,
                                  ),
                                  const SizedBox(height: 20),

                                  // Save & Cancel Buttons Row
                                  Row(
                                    children: [
                                      _SaveNameButton(
                                        isLoading: _isSavingName,
                                        onPressed: _handleSaveName,
                                      ),
                                      const SizedBox(width: 14),
                                      _CancelButton(
                                        onPressed: _cancelEditingName,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 48),

                            // RIGHT COLUMN: 6-Column On-Screen TV Virtual Keyboard
                            SizedBox(
                              width: 380,
                              child: _DedicatedTvKeyboard(
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
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        label = 'Active';
        break;
      case 'INVITED':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Invited';
        break;
      case 'DISABLED':
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = 'Disabled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Full Name Input Box with purple border, "Full name" label, and cursor
class _FullNameInputBox extends StatefulWidget {
  const _FullNameInputBox({
    required this.controller,
    required this.showCursor,
  });

  final TextEditingController controller;
  final bool showCursor;

  @override
  State<_FullNameInputBox> createState() => _FullNameInputBoxState();
}

class _FullNameInputBoxState extends State<_FullNameInputBox> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: isHighlighted ? 0.28 : 0.14),
                blurRadius: isHighlighted ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Full name',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (hasText)
                    Flexible(
                      child: Text(
                        widget.controller.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                          letterSpacing: 0.1,
                        ),
                      ),
                    )
                  else
                    const Flexible(
                      child: Text(
                        'Super Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFA1A1AA),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                  // Blinking purple/black cursor bar
                  if (widget.showCursor)
                    Container(
                      margin: const EdgeInsets.only(left: 2),
                      width: 2,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  else
                    const SizedBox(width: 2, height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient "✓ Save name" Pill Button with focus glow
class _SaveNameButton extends StatefulWidget {
  const _SaveNameButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  State<_SaveNameButton> createState() => _SaveNameButtonState();
}

class _SaveNameButtonState extends State<_SaveNameButton> {
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
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
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
                        .withValues(alpha: isHighlighted ? 0.55 : 0.35),
                    blurRadius: isHighlighted ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saving name',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        PlodyoThreeDotsLoading(
                          color: Colors.white,
                          dotSize: 5,
                          spacing: 3.5,
                          bounceHeight: 4,
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Save name',
                          style: TextStyle(
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

/// "Cancel" Outlined Pill Button
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
            scale: isHighlighted ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFF9333EA)
                      : const Color(0xFF8B5CF6),
                  width: 1.6,
                ),
                boxShadow: [
                  if (isHighlighted)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.22),
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
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 6-Column On-Screen TV Virtual Keyboard matching design screenshot
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

  List<List<String>> get _standardRows => [
        ['a', 'b', 'c', 'd', 'e', 'f'],
        ['g', 'h', 'i', 'j', 'k', 'l'],
        ['m', 'n', 'o', 'p', 'q', 'r'],
        ['s', 't', 'u', 'v', 'w', 'x'],
        ['y', 'z', '0', '1', '2', '3'],
        ['4', '5', '6', '7', '8', '9'],
        ['-', '.', '\''],
      ];

  List<List<String>> get _symbolsRows => [
        ['!', '@', '#', '\$', '%', '^'],
        ['&', '*', '(', ')', '_', '+'],
        ['[', ']', '{', '}', ';', ':'],
        ['\'', '"', ',', '.', '/', '?'],
        ['~', '`', '<', '>', '=', '\\'],
        ['4', '5', '6', '7', '8', '9'],
        ['-', '.', '\''],
      ];

  @override
  Widget build(BuildContext context) {
    final rows = showSymbols ? _symbolsRows : _standardRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Rows 1 to 7
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((char) {
                final displayChar = isUpperCase ? char.toUpperCase() : char;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _KeyButton(
                    label: displayChar,
                    width: 44,
                    height: 44,
                    autofocus: char == 'a' && !showSymbols,
                    onPressed: () => onKeyPress(displayChar),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom Action Keys Row: [↑ abc] [!#?] [—] [⌫] [Clear]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shift / Case toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: isUpperCase ? '↑ ABC' : '↑ abc',
                width: 58,
                height: 44,
                fontSize: 12,
                onPressed: onToggleCase,
              ),
            ),

            // Symbols Toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: showSymbols ? 'ABC' : '!#?',
                isActive: showSymbols,
                width: 48,
                height: 44,
                fontSize: 12,
                onPressed: onToggleSymbols,
              ),
            ),

            // Space key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                label: '—',
                width: 44,
                height: 44,
                fontSize: 15,
                onPressed: onSpace,
              ),
            ),

            // Backspace key
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                width: 44,
                height: 44,
                onPressed: onBackspace,
              ),
            ),

            // Clear key
            _KeyButton(
              label: 'Clear',
              width: 54,
              height: 44,
              fontSize: 12,
              onPressed: onClear,
            ),
          ],
        ),
      ],
    );
  }
}

/// Single Key Button on TV Keyboard with hover & focus glow effects matching screenshot
class _KeyButton extends StatefulWidget {
  const _KeyButton({
    this.label,
    this.icon,
    this.width = 44,
    this.height = 44,
    this.fontSize = 15,
    this.isActive = false,
    this.autofocus = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final bool isActive;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
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
    final isHighlighted = _focusNode.hasFocus || _isHovered || widget.isActive;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      onFocusChange: (_) => setState(() {}),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: isHighlighted ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFD946EF),
                          Color(0xFF9333EA),
                        ],
                      )
                    : null,
                color: isHighlighted ? null : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: isHighlighted
                    ? null
                    : Border.all(
                        color: const Color(0xFFE4E4E7),
                        width: 1.0,
                      ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD946EF).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: Center(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: 18,
                        color: isHighlighted
                            ? Colors.white
                            : const Color(0xFF27272A),
                      )
                    : Text(
                        widget.label ?? '',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight:
                              isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          color: isHighlighted
                              ? Colors.white
                              : const Color(0xFF18181B),
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

/// "← All people" Back Navigation Button with subtle focus aura matching screenshot
class _AllPeopleBackButton extends StatefulWidget {
  const _AllPeopleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AllPeopleBackButton> createState() => _AllPeopleBackButtonState();
}

class _AllPeopleBackButtonState extends State<_AllPeopleBackButton> {
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
            scale: active ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFE2E8F0),
                  width: active ? 1.6 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: active ? 0.35 : 0.18),
                    blurRadius: active ? 18 : 12,
                    spreadRadius: active ? 2 : 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'All people',
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

/// Detail Info Card for the 2x2 grid and Access scope card
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
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
      ),
    );
  }
}

/// Outlined Action Button with focus and hover states
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: _handleKeyEvent,
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? const Color(0xFF8B5CF6) : widget.borderColor,
                  width: active ? 2.0 : 1.4,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.25),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: active ? const Color(0xFF8B5CF6) : widget.iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? const Color(0xFF8B5CF6) : widget.textColor,
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
