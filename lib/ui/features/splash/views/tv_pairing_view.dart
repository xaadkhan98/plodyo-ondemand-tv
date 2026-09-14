import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/device_repository.dart';

/// Screen for entering the 8-character pairing code to set up this TV.
/// Features a two-column layout with pairing info on the left and an on-screen TV keyboard on the right.
class TvPairingView extends StatefulWidget {
  const TvPairingView({
    super.key,
    this.onPaired,
    this.onBack,
  });

  final VoidCallback? onPaired;
  final VoidCallback? onBack;

  @override
  State<TvPairingView> createState() => _TvPairingViewState();
}

class _TvPairingViewState extends State<TvPairingView> {
  final TextEditingController _codeController =
      TextEditingController(text: '4F7K-92QT');
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _inputCardFocusNode = FocusNode();
  final FocusNode _pairButtonFocusNode = FocusNode();
  final FocusNode _backButtonFocusNode = FocusNode();

  bool _isUpperCase = true;
  bool _showSpecialSymbols = false;
  bool _showCursor = true;
  Timer? _cursorTimer;
  bool _isPairing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();

    // Blinking cursor simulation
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });

    _pairButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _backButtonFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _inputCardFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _codeController.dispose();
    _screenFocusNode.dispose();
    _inputCardFocusNode.dispose();
    _pairButtonFocusNode.dispose();
    _backButtonFocusNode.dispose();
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

  void _handleKeyPress(String char) {
    setState(() {
      _errorMessage = null;
      var raw = _codeController.text.replaceAll('-', '');
      if (raw.length < 8) {
        raw += char.toUpperCase();
        if (raw.length > 4) {
          _codeController.text =
              '${raw.substring(0, 4)}-${raw.substring(4)}';
        } else {
          _codeController.text = raw;
        }
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      _errorMessage = null;
      var text = _codeController.text;
      if (text.isNotEmpty) {
        if (text.endsWith('-')) {
          text = text.substring(0, text.length - 1);
        }
        if (text.isNotEmpty) {
          text = text.substring(0, text.length - 1);
        }
        _codeController.text = text;
      }
    });
  }

  void _handleClear() {
    setState(() {
      _errorMessage = null;
      _codeController.clear();
    });
  }

  Future<void> _handlePairThisTv() async {
    final raw = _codeController.text.replaceAll('-', '').trim();
    if (raw.length < 6) {
      setState(() {
        _errorMessage =
            'Please enter the full 8-character pairing code from the console.';
      });
      return;
    }

    setState(() {
      _isPairing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final pairRes = await sharedDeviceRepository.pair(raw);
      if (pairRes.deviceToken.isNotEmpty) {
        try {
          await sharedDeviceRepository.getSession();
          await sharedDeviceRepository.getConfig();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isPairing = false;
          _successMessage = 'TV paired successfully!';
        });

        await Future<void>.delayed(const Duration(milliseconds: 600));

        if (mounted) {
          if (widget.onPaired != null) {
            widget.onPaired!();
          } else {
            context.go('/home');
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _errorMessage = 'Pairing failed. Please check the code and try again.';
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

      // Enter / Select on focused controls
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA) {
        if (_pairButtonFocusNode.hasFocus) {
          _handlePairThisTv();
          return KeyEventResult.handled;
        } else if (_backButtonFocusNode.hasFocus) {
          _handleBack();
          return KeyEventResult.handled;
        }
      }

      // Backspace
      if (key == LogicalKeyboardKey.backspace) {
        _handleBackspace();
        return KeyEventResult.handled;
      }

      // Physical character typing
      if (event.character != null &&
          event.character!.isNotEmpty &&
          event.character!.codeUnitAt(0) >= 32) {
        final char = event.character!;
        if (RegExp(r'[a-zA-Z0-9\-]').hasMatch(char)) {
          if (char == '-') {
            // ignore manual dash
          } else {
            _handleKeyPress(char);
          }
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
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
                        // Left Column: Pairing Info & Actions
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Badge: "Set up this TV"
                              _buildTopBadge(),
                              const SizedBox(height: 18),

                              // Main Headline
                              Text(
                                'Enter the pairing\ncode',
                                style: GoogleFonts.baloo2(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF18181B),
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Subtitle / Instructions with bold highlight
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    height: 1.45,
                                    color: const Color(0xFF52525B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Open this room in the Plodyo TV console, choose ',
                                    ),
                                    TextSpan(
                                      text: 'Set up TV',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF18181B),
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ', and type the eight characters it shows. The code works once and lasts fifteen minutes.',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Pairing Code Input Card
                              _buildPairingCodeInputCard(),

                              // Error / Success Message
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                _buildStatusBanner(
                                  message: _errorMessage!,
                                  isError: true,
                                ),
                              ],
                              if (_successMessage != null) ...[
                                const SizedBox(height: 12),
                                _buildStatusBanner(
                                  message: _successMessage!,
                                  isError: false,
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Action Buttons Row: "Pair this TV" + "Back"
                              Row(
                                children: [
                                  _buildPairButton(),
                                  const SizedBox(width: 16),
                                  _buildBackButton(),
                                ],
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
                            child: _TvPairingKeyboard(
                              isUpperCase: _isUpperCase,
                              showSymbols: _showSpecialSymbols,
                              onKeyPress: _handleKeyPress,
                              onBackspace: _handleBackspace,
                              onClear: _handleClear,
                              onToggleCase: () {
                                setState(() {
                                  _isUpperCase = !_isUpperCase;
                                });
                              },
                              onToggleSymbols: () {
                                setState(() {
                                  _showSpecialSymbols = !_showSpecialSymbols;
                                });
                              },
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

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            color: const Color(0xFFD926A9).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tv_rounded,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'Set up this TV',
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

  Widget _buildPairingCodeInputCard() {
    final hasFocus = _inputCardFocusNode.hasFocus;
    final displayCode = _codeController.text;

    return Focus(
      focusNode: _inputCardFocusNode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFocus
                ? const Color(0xFF9333EA)
                : const Color(0xFF8B5CF6),
            width: hasFocus ? 2.2 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: hasFocus
                  ? const Color(0xFF9333EA).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: hasFocus ? 16 : 6,
              spreadRadius: hasFocus ? 2 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Outlined Key Icon in Purple
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.key_rounded,
                color: Color(0xFF9333EA),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Inner column with label & value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pairing code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        displayCode.isEmpty ? '4F7K-92QT' : displayCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: displayCode.isEmpty
                              ? const Color(0xFFA1A1AA)
                              : const Color(0xFF18181B),
                        ),
                      ),
                      if (_showCursor)
                        Container(
                          width: 2,
                          height: 18,
                          margin: const EdgeInsets.only(left: 2),
                          color: const Color(0xFF9333EA),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairButton() {
    final isFocused = _pairButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _pairButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handlePairThisTv,
          child: AnimatedScale(
            scale: isFocused ? 1.05 : 1.0,
            duration: AppConstants.focusAnimationDuration,
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD926A9),
                    Color(0xFF9333EA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFocused
                        ? const Color(0xFFA855F7).withValues(alpha: 0.7)
                        : const Color(0xFF9333EA).withValues(alpha: 0.4),
                    blurRadius: isFocused ? 28 : 20,
                    spreadRadius: isFocused ? 3 : 1,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isFocused
                    ? Border.all(color: Colors.white, width: 2.0)
                    : Border.all(color: Colors.transparent, width: 2.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isPairing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pair this TV',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    final isFocused = _backButtonFocusNode.hasFocus;

    return Focus(
      focusNode: _backButtonFocusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleBack,
          child: AnimatedScale(
            scale: isFocused ? 1.05 : 1.0,
            duration: AppConstants.focusAnimationDuration,
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                color: isFocused ? const Color(0xFFFAF5FF) : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isFocused
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF9333EA),
                  width: isFocused ? 2.2 : 1.5,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: Color(0xFF18181B),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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

  Widget _buildStatusBanner({
    required String message,
    required bool isError,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? const Color(0xFFF87171)
              : const Color(0xFF4ADE80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: isError
                ? const Color(0xFFB91C1C)
                : const Color(0xFF15803D),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isError
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 6-column TV Virtual Keyboard precisely matching the layout in the design.
class _TvPairingKeyboard extends StatelessWidget {
  const _TvPairingKeyboard({
    required this.isUpperCase,
    required this.showSymbols,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onClear,
    required this.onToggleCase,
    required this.onToggleSymbols,
  });

  final bool isUpperCase;
  final bool showSymbols;
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onToggleCase;
  final VoidCallback onToggleSymbols;

  static const List<List<String>> _alphaGrid = [
    ['A', 'B', 'C', 'D', 'E', 'F'],
    ['G', 'H', 'I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P', 'Q', 'R'],
    ['S', 'T', 'U', 'V', 'W', 'X'],
    ['Y', 'Z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
  ];

  static const List<List<String>> _symbolsGrid = [
    ['!', '@', '#', '\$', '%', '^'],
    ['&', '*', '(', ')', '_', '+'],
    ['[', ']', '{', '}', ';', ':'],
    ['\'', '"', ',', '.', '/', '?'],
    ['Y', 'Z', '0', '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    final currentGrid = showSymbols ? _symbolsGrid : _alphaGrid;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 6 Rows of Keys
          ...currentGrid.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: row.map((char) {
                  final displayChar =
                      isUpperCase ? char.toUpperCase() : char.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TvKeyboardKey(
                      label: displayChar,
                      width: 48,
                      height: 48,
                      onPressed: () => onKeyPress(displayChar),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom Controls Row: [↑ ABC] [!#?] [—] [⌫] [Clear]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shift / ABC Active Gradient Button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyboardKey(
                  label: isUpperCase ? '↑ ABC' : '↑ abc',
                  width: 64,
                  height: 48,
                  fontSize: 13,
                  isGradient: true,
                  onPressed: onToggleCase,
                ),
              ),

              // Symbols Toggle [!#?]
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyboardKey(
                  label: showSymbols ? 'ABC' : '!#?',
                  width: 50,
                  height: 48,
                  fontSize: 13,
                  onPressed: onToggleSymbols,
                ),
              ),

              // Dash / Hyphen Key [—]
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyboardKey(
                  label: '—',
                  width: 46,
                  height: 48,
                  fontSize: 16,
                  onPressed: () => onKeyPress('-'),
                ),
              ),

              // Backspace Key [⌫]
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TvKeyboardKey(
                  icon: Icons.backspace_outlined,
                  width: 46,
                  height: 48,
                  onPressed: onBackspace,
                ),
              ),

              // Clear Key
              _TvKeyboardKey(
                label: 'Clear',
                width: 58,
                height: 48,
                fontSize: 12.5,
                onPressed: onClear,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single TV Keyboard Key with D-pad focus and hover styling.
class _TvKeyboardKey extends StatefulWidget {
  const _TvKeyboardKey({
    this.label,
    this.icon,
    this.width = 48,
    this.height = 48,
    this.fontSize = 16,
    this.isGradient = false,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final bool isGradient;
  final VoidCallback onPressed;

  @override
  State<_TvKeyboardKey> createState() => _TvKeyboardKeyState();
}

class _TvKeyboardKeyState extends State<_TvKeyboardKey> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
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
          key == LogicalKeyboardKey.gameButtonA ||
          key == LogicalKeyboardKey.numpadEnter) {
        widget.onPressed();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isFocused || _isHovered;

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: (isHighlighted || widget.isGradient)
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFD946EF),
                          Color(0xFF9333EA),
                        ],
                      )
                    : null,
                color: (isHighlighted || widget.isGradient)
                    ? null
                    : Colors.white,
                border: isHighlighted
                    ? null
                    : (widget.isGradient
                        ? null
                        : Border.all(
                            color: const Color(0xFFE4E4E7),
                            width: 1.0,
                          )),
                boxShadow: (isHighlighted || widget.isGradient)
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
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 18,
                      color: (isHighlighted || widget.isGradient)
                          ? Colors.white
                          : const Color(0xFF27272A),
                    )
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: widget.fontSize,
                        fontWeight:
                            isHighlighted ? FontWeight.w700 : FontWeight.w600,
                        color: (isHighlighted || widget.isGradient)
                            ? Colors.white
                            : const Color(0xFF18181B),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
