import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/tv_keyboard.dart';

/// Screen for requesting a password reset email link on TV.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({
    super.key,
    this.authRepository,
    this.onBack,
  });

  final AuthRepository? authRepository;
  final VoidCallback? onBack;

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _submitButtonFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();

  late final AuthRepository _authRepository;
  bool _showCursor = true;
  Timer? _cursorTimer;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? sharedAuthRepository;

    // Blinking cursor simulation
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _emailFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _submitButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _backButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _emailController.dispose();
    _screenFocusNode.dispose();
    _emailFocusNode.dispose();
    _submitButtonFocusNode.dispose();
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/sign-in');
    }
  }

  void _handleVirtualKeyPress(String key) {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _emailController.text += key;
    });
  }

  void _handleBackspace() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      if (_emailController.text.isNotEmpty) {
        _emailController.text = _emailController.text
            .substring(0, _emailController.text.length - 1);
      }
    });
  }

  void _handleSpace() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _emailController.text += ' ';
    });
  }

  void _handleClear() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _emailController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await _authRepository.forgotPassword(email: email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = message.isNotEmpty
              ? message
              : 'Password reset link sent! Check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  KeyEventResult _handlePhysicalKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Remote Back button or Escape key
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.gameButtonB ||
          key == LogicalKeyboardKey.goBack) {
        _handleBack();
        return KeyEventResult.handled;
      }

      // Tab navigation
      if (key == LogicalKeyboardKey.tab) {
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        setState(() {
          if (isShift) {
            if (_backButtonFocusNode.hasFocus) {
              _submitButtonFocusNode.requestFocus();
            } else if (_submitButtonFocusNode.hasFocus) {
              _emailFocusNode.requestFocus();
            }
          } else {
            if (_emailFocusNode.hasFocus) {
              _submitButtonFocusNode.requestFocus();
            } else if (_submitButtonFocusNode.hasFocus) {
              _backButtonFocusNode.requestFocus();
            }
          }
        });
        return KeyEventResult.handled;
      }

      // Arrow Up / Down switching between fields
      if (key == LogicalKeyboardKey.arrowDown) {
        if (_emailFocusNode.hasFocus) {
          _submitButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_submitButtonFocusNode.hasFocus) {
          _backButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (_backButtonFocusNode.hasFocus) {
          _submitButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_submitButtonFocusNode.hasFocus) {
          _emailFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }

      // Backspace
      if (key == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return KeyEventResult.handled;
      }

      // Space
      if (key == LogicalKeyboardKey.space) {
        _handleSpace();
        return KeyEventResult.handled;
      }

      // Enter / Numpad Enter
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA) {
        if (_backButtonFocusNode.hasFocus) {
          _handleBack();
        } else {
          _handleSubmit();
        }
        return KeyEventResult.handled;
      }

      // Character typing
      if (event.character != null &&
          event.character!.isNotEmpty &&
          event.character!.codeUnitAt(0) >= 32) {
        _handleVirtualKeyPress(event.character!);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Focus(
        focusNode: _screenFocusNode,
        autofocus: true,
        onKeyEvent: _handlePhysicalKey,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF7FC),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFCFAFE),
                  Color(0xFFFAF6FC),
                  Color(0xFFF7F0FA),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Reset Form & Actions
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main Headline: "Reset your password" with animated tilted badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const TvSectionBadge(
                                    icon: Icons.lock_reset_rounded,
                                    size: 46,
                                    iconSize: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Reset your password',
                                      style: GoogleFonts.baloo2(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF18181B),
                                        letterSpacing: -0.8,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                'Enter the account email and we will send a link to choose a\nnew password.',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF52525B),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              _buildInputField(),
                              const SizedBox(height: 14),

                              // Error Alert Banner
                              if (_errorMessage != null) ...[
                                _buildErrorBanner(_errorMessage!),
                                const SizedBox(height: 14),
                              ],

                              // Success Banner
                              if (_successMessage != null) ...[
                                _buildSuccessBanner(_successMessage!),
                                const SizedBox(height: 14),
                              ],

                              // "Send reset link" Button (Full Width Gradient Pill)
                              _buildSubmitButton(),
                              const SizedBox(height: 14),

                              // "← Back to sign in" Button (Full Width White Pill)
                              _buildBackToSignInButton(),
                            ],
                          ),
                        ),

                        const SizedBox(width: 56),

                        // Right Column: Virtual On-Screen TV Keyboard
                        Expanded(
                          flex: 10,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TvKeyboard(
                              statusText: 'Entering email address',
                              onKeyPress: _handleVirtualKeyPress,
                              onBackspace: _handleBackspace,
                              onSpace: _handleSpace,
                              onClear: _handleClear,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final isActive = _emailFocusNode.hasFocus;

    return Focus(
      focusNode: _emailFocusNode,
      autofocus: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: GestureDetector(
          onTap: () {
            _emailFocusNode.requestFocus();
          },
          child: AnimatedScale(
            scale: isActive ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFFE4E4E7),
                  width: isActive ? 1.8 : 1.2,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF71717A),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _emailController.text.isEmpty
                                    ? 'you@venue.com'
                                    : _emailController.text,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: _emailController.text.isEmpty
                                      ? const Color(0xFFA1A1AA)
                                      : const Color(0xFF18181B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 2),
                              Opacity(
                                opacity: _showCursor ? 1.0 : 0.0,
                                child: Container(
                                  width: 2,
                                  height: 18,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildSubmitButton() {
    final isFocused = _submitButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _submitButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleSubmit,
          child: AnimatedScale(
            scale: isFocused ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B1E7C),
                    Color(0xFF4A1B8C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFocused
                        ? const Color(0xFFA855F7).withValues(alpha: 0.7)
                        : const Color(0xFF7E22CE).withValues(alpha: 0.45),
                    blurRadius: isFocused ? 28 : 22,
                    spreadRadius: isFocused ? 3 : 1,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isFocused
                    ? Border.all(color: Colors.white, width: 2.0)
                    : Border.all(color: Colors.transparent, width: 2.0),
              ),
              child: Center(
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sending link',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          PlodyoThreeDotsLoading(
                            dotSize: 5.5,
                            spacing: 4,
                            bounceHeight: 4.5,
                            color: Colors.white,
                          ),
                        ],
                      )
                    : const Text(
                        'Send reset link',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToSignInButton() {
    final isFocused = _backButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _backButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleBack,
          child: AnimatedScale(
            scale: isFocused ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF9333EA)
                      : const Color(0xFFF4F4F5),
                  width: isFocused ? 2.0 : 1.0,
                ),
                boxShadow: [
                  if (isFocused)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Back to sign in',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 14.5,
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

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFECDD3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE11D48),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE11D48),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF16A34A),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
