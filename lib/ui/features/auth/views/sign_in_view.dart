import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/plodyo_loading.dart';
import '../../../../core/widgets/tv_section_badge.dart';
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
    this.onBack,
    this.onForgotPassword,
    this.onRegisterVenue,
    this.cubit,
  });

  final VoidCallback? onSignedIn;
  final VoidCallback? onBack;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegisterVenue;
  final SignInCubit? cubit;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _signInButtonFocusNode = FocusNode();
  final FocusNode _forgotPasswordFocusNode = FocusNode();
  final FocusNode _registerVenueFocusNode = FocusNode();

  late final SignInCubit _cubit;
  bool _isInternalCubit = false;

  ActiveAuthField _activeField = ActiveAuthField.email;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      _cubit = SignInCubit(authRepository: sharedAuthRepository);
      _isInternalCubit = true;
    }

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

    _backButtonFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _screenFocusNode.dispose();
    _backButtonFocusNode.dispose();
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

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/splash');
    }
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
            } else if (_registerVenueFocusNode.hasFocus) {
              _forgotPasswordFocusNode.requestFocus();
            } else if (_emailFocusNode.hasFocus) {
              _backButtonFocusNode.requestFocus();
            }
          } else {
            if (_backButtonFocusNode.hasFocus) {
              _activeField = ActiveAuthField.email;
              _emailFocusNode.requestFocus();
            } else if (_activeField == ActiveAuthField.email) {
              _activeField = ActiveAuthField.password;
              _passwordFocusNode.requestFocus();
            } else if (_activeField == ActiveAuthField.password) {
              _signInButtonFocusNode.requestFocus();
            } else if (_signInButtonFocusNode.hasFocus) {
              _forgotPasswordFocusNode.requestFocus();
            } else if (_forgotPasswordFocusNode.hasFocus) {
              _registerVenueFocusNode.requestFocus();
            }
          }
        });
        return KeyEventResult.handled;
      }

      // Arrow Up / Down switching between fields
      if (key == LogicalKeyboardKey.arrowDown) {
        if (_backButtonFocusNode.hasFocus) {
          setState(() {
            _activeField = ActiveAuthField.email;
          });
          _emailFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_activeField == ActiveAuthField.email) {
          setState(() {
            _activeField = ActiveAuthField.password;
          });
          _passwordFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_activeField == ActiveAuthField.password) {
          _signInButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_signInButtonFocusNode.hasFocus) {
          _forgotPasswordFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_forgotPasswordFocusNode.hasFocus) {
          _registerVenueFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      } else if (key == LogicalKeyboardKey.arrowUp) {
        if (_registerVenueFocusNode.hasFocus) {
          _forgotPasswordFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_forgotPasswordFocusNode.hasFocus) {
          _signInButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        } else if (_signInButtonFocusNode.hasFocus) {
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
        } else if (_activeField == ActiveAuthField.email &&
            !_backButtonFocusNode.hasFocus) {
          _backButtonFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }

      // Backspace
      if (key == LogicalKeyboardKey.backspace) {
        if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
          return KeyEventResult.ignored;
        }
        _handleBackspace();
        return KeyEventResult.handled;
      }

      // Space
      if (key == LogicalKeyboardKey.space) {
        if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
          return KeyEventResult.ignored;
        }
        _handleSpace();
        return KeyEventResult.handled;
      }

      // Enter / Numpad Enter
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_backButtonFocusNode.hasFocus) {
          _handleBack();
        } else if (_signInButtonFocusNode.hasFocus) {
          _handleSignIn();
        } else if (_forgotPasswordFocusNode.hasFocus) {
          context.push('/forgot-password');
        } else if (_registerVenueFocusNode.hasFocus) {
          _showInfoDialog(
            'Register Venue',
            'To register a new venue, please visit plodyo.com/register on your phone or computer.',
          );
        } else if (_activeField == ActiveAuthField.email &&
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

      // Remote Back button or Escape key to go back / clear
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.gameButtonB ||
          key == LogicalKeyboardKey.goBack) {
        if (_emailController.text.isNotEmpty ||
            _passwordController.text.isNotEmpty) {
          _handleClear();
        } else {
          _handleBack();
        }
        return KeyEventResult.handled;
      }

      // Character typing
      if (event.character != null &&
          event.character!.isNotEmpty &&
          event.character!.codeUnitAt(0) >= 32) {
        if (_emailFocusNode.hasFocus || _passwordFocusNode.hasFocus) {
          return KeyEventResult.ignored;
        }
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
      if (_activeField == ActiveAuthField.email &&
          _emailController.text.isNotEmpty) {
        _emailController.text =
            _emailController.text.substring(0, _emailController.text.length - 1);
      } else if (_activeField == ActiveAuthField.password &&
          _passwordController.text.isNotEmpty) {
        _passwordController.text = _passwordController.text
            .substring(0, _passwordController.text.length - 1);
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
          final errorMessage =
              state is SignInFailure ? state.errorMessage : null;
          final successMessage =
              state is SignInSuccess ? state.message : null;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _handleBack();
              }
            },
            child: Focus(
              focusNode: _screenFocusNode,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 56, vertical: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left Column: Form & Branding
                              Expanded(
                                flex: 11,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Top Row: Back Navigation & Brand Tag
                                    Row(
                                      children: [
                                        _buildBackButton(),
                                        const SizedBox(width: 12),
                                        _buildBrandBadge(),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                     // Main Headline: "Sign in to the TV" with animated tilted badge
                                     Row(
                                       crossAxisAlignment: CrossAxisAlignment.center,
                                       children: [
                                         const TvSectionBadge(
                                           icon: Icons.tv_rounded,
                                           size: 46,
                                           iconSize: 24,
                                         ),
                                         const SizedBox(width: 14),
                                         Expanded(
                                           child: Text(
                                             'Sign in to the TV',
                                             style: GoogleFonts.baloo2(
                                               fontSize: 38,
                                               fontWeight: FontWeight.w900,
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
                                      'Manage venues, properties, rooms and the people who run them.',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF52525B),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Email Field
                                    _buildInputField(
                                      field: ActiveAuthField.email,
                                      label: 'Email',
                                      hintText: 'you@venue.com',
                                      icon: Icons.mail_outline_rounded,
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                    ),
                                    const SizedBox(height: 14),

                                    // Password Field
                                    _buildInputField(
                                      field: ActiveAuthField.password,
                                      label: 'Password',
                                      hintText: 'Your password',
                                      icon: Icons.lock_outline_rounded,
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 14),

                                    // Error Alert Banner
                                    if (errorMessage != null) ...[
                                      _buildErrorBanner(errorMessage),
                                      const SizedBox(height: 14),
                                    ],

                                    // Success Banner
                                    if (successMessage != null) ...[
                                      _buildSuccessBanner(successMessage),
                                      const SizedBox(height: 14),
                                    ],

                                    // Sign In Action Button (Full Width Gradient Pill)
                                    _buildSignInButton(isLoading: isLoading),
                                    const SizedBox(height: 14),

                                    // Forgot Password Button (Full Width White Pill)
                                    _buildPillActionCard(
                                      focusNode: _forgotPasswordFocusNode,
                                      label: 'Forgot password?',
                                      onPressed: () {
                                        if (widget.onForgotPassword != null) {
                                          widget.onForgotPassword!();
                                        } else {
                                          context.push('/forgot-password');
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Register a new venue Button (Full Width White Pill)
                                    _buildPillActionCard(
                                      focusNode: _registerVenueFocusNode,
                                      label: 'Register a new venue',
                                      onPressed: () {
                                        if (widget.onRegisterVenue != null) {
                                          widget.onRegisterVenue!();
                                        } else {
                                          context.push('/register-venue');
                                        }
                                      },
                                    ),
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
        },
      ),
    );
  }

  Widget _buildBackButton() {
    final isFocused = _backButtonFocusNode.hasFocus;
    return Focus(
      focusNode: _backButtonFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.numpadEnter) {
            _handleBack();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleBack,
          child: AnimatedScale(
            scale: isFocused ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF9333EA)
                      : const Color(0xFFE4E4E7),
                  width: isFocused ? 2 : 1.2,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: isFocused
                        ? const Color(0xFF9333EA)
                        : const Color(0xFF52525B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isFocused
                          ? const Color(0xFF9333EA)
                          : const Color(0xFF52525B),
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

  Widget _buildBrandBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD926A9),
            Color(0xFF9333EA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD926A9).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_rounded,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'Plodyo TV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
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
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
  }) {
    final isActive = _activeField == field;

    return Focus(
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
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF8B5CF6)
                      : (isPassword
                          ? const Color(0xFF71717A)
                          : const Color(0xFFE4E4E7)),
                  width: isActive ? 2.0 : 1.3,
                ),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.38),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  else ...[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : (isPassword
                            ? const Color(0xFF52525B)
                            : const Color(0xFF71717A)),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                obscureText: isPassword,
                                autofocus: field == ActiveAuthField.email,
                                autocorrect: false,
                                enableSuggestions: !isPassword,
                                keyboardType: isPassword
                                    ? TextInputType.visiblePassword
                                    : TextInputType.emailAddress,
                                textInputAction: isPassword
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: isPassword ? 19 : 16.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: isPassword ? 2.5 : 0.2,
                                  color: const Color(0xFF18181B),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: hintText,
                                  hintStyle: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA1A1AA),
                                  ),
                                ),
                                onChanged: (_) {
                                  _cubit.clearError();
                                  setState(() {});
                                },
                                onSubmitted: (_) {
                                  if (isPassword) {
                                    _handleSignIn();
                                  } else {
                                    _passwordFocusNode.requestFocus();
                                  }
                                },
                              ),
                            ),
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
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.numpadEnter) {
            _handleSignIn();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          final isFocused = _signInButtonFocusNode.hasFocus;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _handleSignIn,
              child: AnimatedScale(
                scale: isFocused ? 1.03 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE11D89),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isFocused
                            ? const Color(0xFFA855F7).withValues(alpha: 0.75)
                            : const Color(0xFF9333EA).withValues(alpha: 0.48),
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
                    child: isLoading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Signing in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
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
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
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

  Widget _buildPillActionCard({
    required FocusNode focusNode,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.numpadEnter) {
            onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: StatefulBuilder(
        builder: (context, setBtnState) {
          final isFocused = focusNode.hasFocus;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onPressed,
              child: AnimatedScale(
                scale: isFocused ? 1.03 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isFocused
                        ? const Color(0xFFFAF5FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF9333EA)
                          : const Color(0xFFCBD5E1),
                      width: isFocused ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      if (isFocused)
                        BoxShadow(
                          color:
                              const Color(0xFF9333EA).withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isFocused
                            ? const Color(0xFF9333EA)
                            : const Color(0xFF18181B),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
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
}
