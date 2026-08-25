import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _signInButtonFocusNode = FocusNode();

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
      _cubit = SignInCubit();
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
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _signInButtonFocusNode.dispose();
    if (_isInternalCubit) {
      _cubit.close();
    }
    super.dispose();
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
        _emailController.text = _emailController.text.substring(0, _emailController.text.length - 1);
      } else if (_activeField == ActiveAuthField.password && _passwordController.text.isNotEmpty) {
        _passwordController.text = _passwordController.text.substring(0, _passwordController.text.length - 1);
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
    if (_cubit.state is SignInLoading) return;
    _cubit.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInCubit>.value(
      value: _cubit,
      child: BlocConsumer<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            widget.onSignedIn?.call();
          }
        },
        builder: (context, state) {
          final isLoading = state is SignInLoading;
          final errorMessage = state is SignInFailure ? state.errorMessage : null;
          final successMessage = state is SignInSuccess ? state.message : null;

          return Scaffold(
            backgroundColor: const Color(0xFFFAF3F8),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFCF5FA),
                    Color(0xFFF9EEF7),
                    Color(0xFFF5EBF4),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Main content row (Left form + Right keyboard)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 1000;
                          final horizontalPadding = isCompact ? 32.0 : 52.0;
                          final columnGap = isCompact ? 28.0 : 44.0;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 24,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Branding, Headings, Form Inputs, Action Button
                                Expanded(
                                  flex: 5,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top Tag: "Plodyo for TV"
                                        _buildBrandBadge(),
                                        const SizedBox(height: 16),

                                        // Main Headline
                                        const Text(
                                          'Sign in to start reading',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF18181B),
                                            letterSpacing: -0.8,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Subtitle
                                        const Text(
                                          'Use the remote to enter the account details for this device.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF71717A),
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Email Field
                                        _buildInputField(
                                          field: ActiveAuthField.email,
                                          label: 'Email',
                                          icon: Icons.mail_outline_rounded,
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          autofocus: true,
                                        ),
                                        const SizedBox(height: 14),

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

                                        // Error Alert Banner (Dynamically shown on real failure)
                                        if (errorMessage != null) ...[
                                          _buildErrorBanner(errorMessage),
                                          const SizedBox(height: 14),
                                        ],

                                        // Success Banner
                                        if (successMessage != null) ...[
                                          _buildSuccessBanner(successMessage),
                                          const SizedBox(height: 14),
                                        ],

                                        const SizedBox(height: 4),

                                        // Sign In Action Button
                                        _buildSignInButton(isLoading: isLoading),

                                        const SizedBox(height: 48),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(width: columnGap),

                                // Right Column: Virtual On-Screen TV Keyboard
                                Expanded(
                                  flex: 5,
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
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
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE040FB),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_rounded,
            size: 16,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            'Plodyo for TV',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
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
    final isSelected = _activeField == field;

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
          scale: isSelected ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFFC084FC) : const Color(0xFFE2E8F0),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF9333EA) : const Color(0xFF94A3B8),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              controller.text.isEmpty
                                  ? '—'
                                  : (isPassword
                                      ? '•' * controller.text.length
                                      : controller.text),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: controller.text.isEmpty
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE11D48),
                fontSize: 13.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontSize: 13.5,
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
              scale: isFocused ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(26),
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
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                  border: isFocused
                      ? Border.all(color: const Color(0xFFC084FC), width: 2.0)
                      : null,
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
