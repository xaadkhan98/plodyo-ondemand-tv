import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/input/text_entry.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/blinking_caret.dart';
import '../../../../core/widgets/dashed_border.dart';
import '../../../../core/widgets/on_screen_keyboard.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/setup_scene.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/models/device_models.dart';

enum _Field { code }

/// Claims this set for a room with the code the console just issued. The dash is added on read-back
/// rather than being one more key to travel to.
class PairView extends StatefulWidget {
  const PairView({super.key, required this.pair, required this.onCancel});

  /// Trades the code for this TV's token; on success the device gate moves on, so nothing is called back.
  final Future<void> Function(String code) pair;
  final VoidCallback onCancel;

  @override
  State<PairView> createState() => _PairViewState();
}

class _PairViewState extends State<PairView> {
  // Room for the dash a person may type themselves.
  late final _entry = TextEntryController<_Field>(
    _Field.values,
    maxLength: pairingCodeLength + 1,
    onEdit: () => setState(() => _error = null),
  );
  bool _pairing = false;
  String? _error;

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    setState(() => _pairing = true);
    try {
      await widget.pair(_entry[_Field.code]);
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
        onExit: widget.onCancel,
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
                              code: normalisePairingCode(_entry[_Field.code]),
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
                                onSelect: widget.onCancel,
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
        (false, true) => const BlinkingCaret(
          width: 0.25 * rem,
          height: 1.6 * rem,
          rounded: true,
        ),
        _ => null,
      },
    );
    // Empty tiles are dashed: room still to fill, not a control.
    return outlined
        ? box
        : CustomPaint(
            foregroundPainter: const DashedBorder(radius: _radius),
            child: box,
          );
  }
}
