import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/setup_scene.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/device_repository.dart';

enum _Field { code }

/// Claims this set for a room with the code the console just issued. The dash is added on read-back
/// rather than being one more key to travel to.
class TvPairingView extends StatefulWidget {
  const TvPairingView({super.key, this.onPaired, this.onBack});

  final VoidCallback? onPaired;
  final VoidCallback? onBack;

  @override
  State<TvPairingView> createState() => _TvPairingViewState();
}

class _TvPairingViewState extends State<TvPairingView> {
  static const _codeLength = 8;

  // Room for the dash a person may type themselves.
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: _codeLength + 1,
    onEdit: () => setState(() => _error = null),
  );
  bool _pairing = false;
  String? _error;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _back() => widget.onBack != null
      ? widget.onBack!()
      : (context.canPop() ? context.pop() : context.go('/splash'));

  /// The code as typed, normalised for display: capitals and digits, with the dash as presentation only.
  static String _normalise(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (cleaned.length <= 4) return cleaned;
    return '${cleaned.substring(0, 4)}-${cleaned.substring(4, cleaned.length.clamp(4, _codeLength))}';
  }

  Future<void> _pair() async {
    setState(() => _pairing = true);
    try {
      await sharedDeviceRepository.pair(_entry[_Field.code]);
      if (!mounted) return;
      widget.onPaired != null ? widget.onPaired!() : context.go('/home');
    } catch (e) {
      // The API does not say whether a code was wrong or expired; staff go back to the console either way.
      if (!mounted) return;
      setState(() => _error = messageOf(e, 'Could not pair this TV.'));
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = TvText.base.copyWith(color: TvColors.mutedForeground);

    return Scaffold(
      body: TextEntryScope(
        controller: _entry,
        onExit: _back,
        child: Stack(
          children: [
            const Positioned.fill(child: NightBackdrop()),
            CenteredScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 75 * rem),
                child: Row(
                  spacing: 4 * rem,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Badge(),
                          const SizedBox(height: 1.25 * rem),
                          Text(
                            'Enter the pairing code',
                            style: TvText.xl.copyWith(
                              fontFamily: TvText.baloo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 0.75 * rem),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 48 * TvText.ch(body),
                            ),
                            child: Text.rich(
                              const TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'Open this room in the Plodyo console, choose ',
                                  ),
                                  TextSpan(
                                    text: 'Set up TV',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ', and type the eight characters it shows. The code works once and lasts fifteen minutes.',
                                  ),
                                ],
                              ),
                              style: body,
                            ),
                          ),
                          const SizedBox(height: 2 * rem),
                          Text(
                            'Pairing code',
                            style: TvText.sm.copyWith(
                              color: TvColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 0.5 * rem),
                          ListenableBuilder(
                            listenable: _entry,
                            builder: (context, _) => _CodeSlots(
                              code: _normalise(_entry[_Field.code]),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 1.25 * rem),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 32 * rem,
                              ),
                              child: StatusMessage(
                                tone: StatusTone.error,
                                message: _error!,
                              ),
                            ),
                          ],
                          const SizedBox(height: 1.75 * rem),
                          Wrap(
                            spacing: rem,
                            runSpacing: rem,
                            children: [
                              TvButton(
                                label: 'Pair this TV',
                                icon: LucideIcons.check,
                                autofocus: true,
                                busy: _pairing,
                                busyLabel: 'Pairing…',
                                onSelect: _pair,
                              ),
                              TvButton(
                                label: 'Back',
                                icon: LucideIcons.arrowLeft,
                                variant: TvButtonVariant.outline,
                                disabled: _pairing,
                                onSelect: _back,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // One tray rather than forty loose keys floating on the wash.
                    Container(
                      padding: const EdgeInsets.all(1.5 * rem),
                      decoration: BoxDecoration(
                        color: TvColors.secondary,
                        borderRadius: BorderRadius.circular(2 * rem),
                        border: Border.all(
                          color: TvColors.border.withValues(alpha: 0.5),
                          width: 2 * px,
                        ),
                        boxShadow: TvShadows.xl(
                          TvColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      // A pairing code is printed in capitals; starting lowercase would show every character wrong.
                      child: OnScreenKeyboard(
                        controller: _entry,
                        defaultShift: true,
                      ),
                    ),
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

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: rem,
        vertical: 0.375 * rem,
      ),
      decoration: BoxDecoration(
        gradient: TvColors.brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.5 * rem,
        children: [
          const Icon(LucideIcons.tv, size: rem, color: Colors.white),
          Text(
            'Set up this TV',
            style: TvText.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eight tiles rather than a line of text: they also say how much is left and where the next character lands.
class _CodeSlots extends StatelessWidget {
  const _CodeSlots({required this.code});

  /// Normalised, e.g. "4F7K-92".
  final String code;

  @override
  Widget build(BuildContext context) {
    final chars = code.replaceAll('-', '');
    Widget slot(int i) => _Slot(
      char: i < chars.length ? chars[i] : null,
      isNext: i == chars.length,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 0.625 * rem,
      children: [
        for (var i = 0; i < 4; i++) slot(i),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.25 * rem),
          child: Text(
            '-',
            style: TvText.lg.copyWith(color: TvColors.mutedForeground),
          ),
        ),
        for (var i = 4; i < 8; i++) slot(i),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.char, required this.isNext});

  final String? char;
  final bool isNext;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    final filled = char != null;
    final outlined = filled || isNext;
    final box = Container(
      width: 4 * rem,
      height: 5 * rem,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: _radius,
        border: outlined
            ? Border.all(color: TvColors.primary, width: 2 * px)
            : null,
        boxShadow: filled
            ? TvShadows.md(TvColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: switch ((filled, isNext)) {
        (true, _) => Text(
          char!,
          style: TvText.x2l.copyWith(
            fontFamily: TvText.baloo,
            fontWeight: FontWeight.w600,
            height: 1,
            color: TvColors.primaryInk,
          ),
        ),
        (false, true) => const _BlinkingBar(),
        _ => null,
      },
    );
    // Empty tiles are dashed: room still to fill, not a control.
    return outlined
        ? box
        : CustomPaint(
            foregroundPainter: const _DashedBorder(_radius),
            child: box,
          );
  }
}

/// The caret in the next empty tile; the one thing on the screen allowed to loop, because it is the cursor.
class _BlinkingBar extends StatefulWidget {
  const _BlinkingBar();

  @override
  State<_BlinkingBar> createState() => _BlinkingBarState();
}

class _BlinkingBarState extends State<_BlinkingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink.drive(
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
        ]),
      ),
      child: Container(
        width: 0.25 * rem,
        height: 1.6 * rem,
        decoration: BoxDecoration(
          color: TvColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// CSS `border-2 border-dashed` in the border colour: dashes and gaps three border-widths long, as Chrome draws them.
class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.radius);

  static const double _width = 2 * px;
  static const double _dash = 3 * _width;

  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    final paint = Paint()
      ..color = TvColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final PathMetric metric
        in (Path()..addRRect(radius.toRRect(rect))).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 2 * _dash) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.radius != radius;
}
