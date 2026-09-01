import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../cubit/sign_in_cubit.dart';
import '../cubit/sign_in_state.dart';
import '../widgets/tv_keyboard.dart';

enum ActiveAuthField {
  email,
  password,
}

/// Sign In Screen tailored for TV remote and D-pad interaction with Cubit state management.
class SignInView extends StatefulWidget {
  const SignInView({
    super.key,
    this.onSignedIn,
    this.cubit,
  });

  final VoidCallback? onSignedIn;
  final SignInCubit? cubit;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _signInButtonFocusNode = FocusNode();
  final FocusNode _forgotPasswordFocusNode = FocusNode();
  final FocusNode _registerVenueFocusNode = FocusNode();

  late final SignInCubit _cubit;
  bool _isInternalCubit = false;

  ActiveAuthField _activeField = ActiveAuthField.email;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      _cubit = SignInCubit(authRepository: sharedAuthRepository);
      _isInternalCubit = true;
    }

    // Blinking cursor simulation for TV input
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveAuthField.email;
        });
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _activeField = ActiveAuthField.password;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _screenFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _signInButtonFocusNode.dispose();
    _forgotPasswordFocusNode.dispose();
    _registerVenueFocusNode.dispose();
    if (_isInternalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  KeyEventResult _handlePhysicalKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Tab navigation
      if (key == LogicalKeyboardKey.tab) {
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        setState(() {
          if (isShift) {
            if (_activeField == ActiveAuthField.password) {
              _activeField = ActiveAuthField.email;
              _emailFocusNode.requestFocus();
            } else if (_signInButtonFocusNode.hasFocus) {
              _activeField = ActiveAuthField.password;
              _passwordFocusNode.requestFocus();
            } else if (_forgotPasswordFocusNode.hasFocus) {
              _signInButtonFocusNode.requestFocus();
            }
          } else {
            if (_activeField == ActiveAuthField.email) {
              _activeField = ActiveAuthField.password;
              _passwordFocusNode.requestFocus();
            } else if (_activeField == ActiveAuthField.password) {
              _signInButtonFocusNode.requestFocus();
            } else if (_signInButtonFocusNode.hasFocus) {
              _forgotPasswordFocusNode.requestFocus();
            }
          }
        });
        return KeyEventResult.handled;
      }

      // Arrow Up / Down switching between fields
      if (key == LogicalKeyboardKey.arrowDown) {
        if (_activeField == ActiveAuthField.email) {
          setState(() {
            _activeField = ActiveAuthField.password;
          });
          _passwordFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_activeField == ActiveAuthField.password) {
          _signInButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (_signInButtonFocusNode.hasFocus || _forgotPasswordFocusNode.hasFocus) {
          setState(() {
            _activeField = ActiveAuthField.password;
          });
          _passwordFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_activeField == ActiveAuthField.password) {
          setState(() {
            _activeField = ActiveAuthField.email;
          });
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
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        if (_activeField == ActiveAuthField.email &&
            _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isEmpty) {
          setState(() {
            _activeField = ActiveAuthField.password;
          });
          _passwordFocusNode.requestFocus();
        } else {
          _handleSignIn();
        }
        return KeyEventResult.handled;
      }

      // Escape key to clear field
      if (key == LogicalKeyboardKey.escape) {
        _handleClear();
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

  void _handleVirtualKeyPress(String key) {
    _cubit.clearError();
    setState(() {
      if (_activeField == ActiveAuthField.email) {
        _emailController.text += key;
      } else {
        _passwordController.text += key;
      }
    });
  }

  void _handleBackspace() {
    _cubit.clearError();
    setState(() {
      if (_activeField == ActiveAuthField.email && _emailController.text.isNotEmpty) {
        _emailController.text =
            _emailController.text.substring(0, _emailController.text.length - 1);
      } else if (_activeField == ActiveAuthField.password &&
          _passwordController.text.isNotEmpty) {
        _passwordController.text =
            _passwordController.text.substring(0, _passwordController.text.length - 1);
      }
    });
  }

  void _handleSpace() {
    _cubit.clearError();
    setState(() {
      if (_activeField == ActiveAuthField.email) {
        _emailController.text += ' ';
      } else {
        _passwordController.text += ' ';
      }
    });
  }

  void _handleClear() {
    _cubit.clearError();
    setState(() {
      if (_activeField == ActiveAuthField.email) {
        _emailController.clear();
      } else {
        _passwordController.clear();
      }
    });
  }

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _cubit.signIn(
      email: email,
      password: password,
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF18181B),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF71717A),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF9333EA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInCubit>.value(
      value: _cubit,
      child: BlocConsumer<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            if (widget.onSignedIn != null) {
              widget.onSignedIn!();
            } else {
              context.go('/home');
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is SignInLoading;
          final errorMessage = state is SignInFailure ? state.errorMessage : null;
          final successMessage = state is SignInSuccess ? state.message : null;

          return Focus(
            focusNode: _screenFocusNode,
            autofocus: true,
            onKeyEvent: _handlePhysicalKey,
            child: Scaffold(
              backgroundColor: const Color(0xFFFAF7FC),
              body: Container(
                color: const Color(0xFFFAF7FC),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Form & Branding
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top Tag: "Plodyo for TV"
                                  _buildBrandBadge(),
                                  const SizedBox(height: 14),

                                  // Main Headline
                                  const Text(
                                    'Sign in to start reading',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF18181B),
                                      letterSpacing: -0.6,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Subtitle
                                  const Text(
                                    'Use the remote to enter the account details for this device.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF71717A),
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Email Field
                                  _buildInputField(
                                    field: ActiveAuthField.email,
                                    label: 'Email',
                                    icon: Icons.mail_outline_rounded,
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    autofocus: true,
                                  ),
                                  const SizedBox(height: 12),

                                  // Password Field
                                  _buildInputField(
                                    field: ActiveAuthField.password,
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 14),

                                  // Error Alert Banner
                                  if (errorMessage != null) ...[
                                    _buildErrorBanner(errorMessage),
                                    const SizedBox(height: 12),
                                  ],

                                  // Success Banner
                                  if (successMessage != null) ...[
                                    _buildSuccessBanner(successMessage),
                                    const SizedBox(height: 12),
                                  ],

                                  // Sign In Action Button
                                  _buildSignInButton(isLoading: isLoading),
                                  const SizedBox(height: 10),

                                  // Forgot Password Button (with glowing aura when focused)
                                  _buildForgotPasswordButton(),
                                  const SizedBox(height: 14),

                                  // Register a new venue link
                                  _buildRegisterVenueLink(),
                                ],
                              ),
                            ),

                            const SizedBox(width: 52),

                            // Right Column: Virtual On-Screen TV Keyboard
                            Expanded(
                              flex: 9,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: TvKeyboard(
                                  statusText: _activeField == ActiveAuthField.email
                                      ? 'Entering email address'
                                      : 'Entering password',
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
          );
        },
      ),
    );
  }

  Widget _buildBrandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD926A9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_rounded,
            size: 15,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'Plodyo for TV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required ActiveAuthField field,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    bool autofocus = false,
  }) {
    final isActive = _activeField == field;

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            setState(() {
              _activeField = field;
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeField = field;
          });
          focusNode.requestFocus();
        },
        child: AnimatedScale(
          scale: isActive ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? const Color(0xFF9333EA) : const Color(0xFFE4E4E7),
                width: isActive ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
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
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? const Color(0xFF9333EA) : const Color(0xFF71717A),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.text.isEmpty
                                  ? ''
                                  : (isPassword
                                      ? '•' * controller.text.length
                                      : controller.text),
                              style: TextStyle(
                                fontSize: isPassword ? 18 : 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: isPassword ? 2.5 : 0.2,
                                color: const Color(0xFF18181B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive && !isPassword) ...[
                            const SizedBox(width: 2),
                            Opacity(
                              opacity: _showCursor ? 1.0 : 0.0,
                              child: Container(
                                width: 1.8,
                                height: 16,
                                color: const Color(0xFF9333EA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActive && isPassword) ...[
                  Opacity(
                    opacity: _showCursor ? 1.0 : 0.0,
                    child: Container(
                      width: 1.8,
                      height: 18,
                      color: const Color(0xFF9333EA),
                    ),
                  ),
                ],
              ],
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

  Widget _buildSignInButton({required bool isLoading}) {
    return Focus(
      focusNode: _signInButtonFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            _handleSignIn();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          final isFocused = _signInButtonFocusNode.hasFocus;

          return GestureDetector(
            onTap: _handleSignIn,
            child: AnimatedScale(
              scale: isFocused ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (isFocused)
                      BoxShadow(
                        color: const Color(0xFFC084FC).withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: isFocused
                      ? Border.all(color: const Color(0xFFC084FC), width: 1.8)
                      : null,
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Focus(
      focusNode: _forgotPasswordFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            _showInfoDialog(
              'Forgot Password',
              'To reset your password, please visit plodyo.com/forgot on your phone or computer.',
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          final isFocused = _forgotPasswordFocusNode.hasFocus;

          return GestureDetector(
            onTap: () {
              _showInfoDialog(
                'Forgot Password',
                'To reset your password, please visit plodyo.com/forgot on your phone or computer.',
              );
            },
            child: AnimatedScale(
              scale: isFocused ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (isFocused)
                      BoxShadow(
                        color: const Color(0xFFE040FB).withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 3,
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
                child: const Center(
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegisterVenueLink() {
    return Focus(
      focusNode: _registerVenueFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.gameButtonA) {
            _showInfoDialog(
              'Register Venue',
              'To register a new venue, please visit plodyo.com/register on your phone or computer.',
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          final isFocused = _registerVenueFocusNode.hasFocus;

          return Center(
            child: GestureDetector(
              onTap: () {
                _showInfoDialog(
                  'Register Venue',
                  'To register a new venue, please visit plodyo.com/register on your phone or computer.',
                );
              },
              child: AnimatedScale(
                scale: isFocused ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isFocused
                        ? const Color(0xFF9333EA).withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Text(
                    'Register a new venue',
                    style: TextStyle(
                      color: isFocused
                          ? const Color(0xFF7E22CE)
                          : const Color(0xFF9333EA),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      decoration: isFocused ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
