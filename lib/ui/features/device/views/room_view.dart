import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/audio/chime.dart';
import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/language_picker.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tv_button.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../device_controller.dart';
import '../widgets/guest_page.dart';

/// What this TV is, and how to take it out of the room. Off the guest rail: it carries two raw ids and
/// the unpair action, so support talks a guest to the blue button instead. The ids are shown in full,
/// because support asks for them and this is the only place they exist.
class RoomView extends StatefulWidget {
  const RoomView({super.key});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  final _unpair = FocusNode();
  bool _confirming = false;

  @override
  void dispose() {
    _unpair.dispose();
    super.dispose();
  }

  void _cancel() {
    setState(() => _confirming = false);
    // Asked for, not autofocused: the scope would hand the ring back to whatever held it before.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unpair.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceScope.of(context);
    // Reached only through the gate, which routes nothing here before the TV is ready.
    final DeviceReady(:config, :session) = device.phase as DeviceReady;
    String? nameOf(String? code) =>
        config.languages.where((l) => l.code == code).firstOrNull?.name;
    final chosen = nameOf(device.language);
    final roomDefault =
        nameOf(config.defaultLanguage) ?? config.defaultLanguage;
    final note = TvText.sm.copyWith(color: TvColors.mutedForeground);
    final measure = 60 * TvText.ch(note);

    return GuestPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TvInsets.safeX,
          0,
          TvInsets.safeX,
          TvInsets.safeY,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 75 * rem),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle(
                  icon: LucideIcons.tv,
                  title: 'This TV',
                  subtitle:
                      'The room this set is paired with, and what it is showing.',
                ),
                const SizedBox(height: 2 * rem),
                // The one fact a guest is here for leads, at a size that reads from the bed.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(2 * rem),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.5 * rem),
                    boxShadow: TvShadows.lg(
                      TvColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    spacing: 1.5 * rem,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0.75 * rem),
                          boxShadow: TvShadows.md(),
                        ),
                        child: LanguageFlag(
                          code: device.language ?? config.defaultLanguage,
                          width: 6.75 * rem,
                          height: 4.5 * rem,
                          radius: 0.75 * rem,
                          fallback: const Icon(
                            LucideIcons.languages,
                            size: 4 * rem,
                            color: TvColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stories are in', style: note),
                            Text(
                              chosen ??
                                  (roomDefault != null
                                      ? '$roomDefault (room default)'
                                      : 'Everything'),
                              style: TvText.x2l.copyWith(
                                fontFamily: TvText.fredoka,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                // One id per line, each labelled: support reads these down the phone.
                DefaultTextStyle(
                  style: note.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  child: Column(
                    spacing: 0.375 * rem,
                    children: [
                      _Fact('Room', session.roomId, strong: true),
                      _Fact('Session', session.sessionId, strong: true),
                      _Fact('Started', formatDateTime(session.startedAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 2.5 * rem),
                const _Heading('Language'),
                const SizedBox(height: 0.25 * rem),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: measure),
                  child: Text(
                    'A guest’s choice, for as long as this set stays on. The same list is behind the '
                    'language pill at the top of every screen.'
                    '${device.ageGroup == null ? '' : ' Age filter: ${device.ageGroup!.label}.'}',
                    style: note,
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                if (config.languages.isEmpty)
                  const StatusMessage(
                    tone: StatusTone.info,
                    message:
                        'This room has no languages configured, so the whole catalogue is shown.',
                  )
                else
                  LanguagePicker(
                    label: null,
                    options: config.languages,
                    value: device.language,
                    // The screen's first control, so it takes the ring on arrival.
                    autofocus: true,
                    noneLabel: roomDefault != null
                        ? 'As set for this room ($roomDefault)'
                        : 'As set for this room — the whole catalogue',
                    onChanged: device.chooseLanguage,
                  ),
                const SizedBox(height: 3 * rem),
                const _Heading('Take this TV out of the room'),
                const SizedBox(height: 0.25 * rem),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: measure),
                  child: Text(
                    'Forgets the credential stored on this set. The room keeps its device in the console — '
                    'to stop it serving content anywhere, revoke it there instead.',
                    style: note,
                  ),
                ),
                const SizedBox(height: 1.25 * rem),
                // Keyed so each state is a fresh subtree, rather than one button's state handed to another.
                KeyedSubtree(
                  key: ValueKey(_confirming),
                  child: _confirming
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 1.25 * rem,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: measure),
                              child: const StatusMessage(
                                tone: StatusTone.warning,
                                message:
                                    'A new pairing code will be needed to put this TV back. Codes come from '
                                    'the console and last fifteen minutes.',
                              ),
                            ),
                            Row(
                              spacing: rem,
                              children: [
                                _HoldToUnpair(onComplete: device.unpair),
                                TvButton(
                                  label: 'Cancel',
                                  variant: TvButtonVariant.outline,
                                  onSelect: _cancel,
                                ),
                              ],
                            ),
                          ],
                        )
                      : TvButton(
                          label: 'Unpair this TV',
                          icon: LucideIcons.unplug,
                          variant: TvButtonVariant.danger,
                          size: TvButtonSize.md,
                          focusNode: _unpair,
                          onSelect: () => setState(() => _confirming = true),
                        ),
                ),
                const SizedBox(height: 2.5 * rem),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TvText.lg.copyWith(fontWeight: FontWeight.w600));
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.strong = false});

  final String label;
  final String value;

  /// An id, in the body colour so it reads apart from its label.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.75 * rem,
      children: [
        SizedBox(width: 7 * rem, child: Text(label)),
        Expanded(
          child: Text(
            value,
            style: strong ? const TextStyle(color: TvColors.foreground) : null,
          ),
        ),
      ],
    );
  }
}

/// The hold-to-confirm gate on the one destructive action a guest's TV offers. A sustained hold is the
/// cheapest gate a remote can express: no digit keys for a sum, and a keyboard would be a second screen.
class _HoldToUnpair extends StatefulWidget {
  const _HoldToUnpair({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_HoldToUnpair> createState() => _HoldToUnpairState();
}

class _HoldToUnpairState extends State<_HoldToUnpair>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(seconds: 3);
  static final _okKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };
  static const _pill = BorderRadius.all(Radius.circular(999));

  // The fill is the only progress shown: a countdown in numbers would be one more line to read.
  late final AnimationController _fill = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  late final FocusNode _node = FocusNode(onKeyEvent: _onKey);
  bool _held = false;

  @override
  void initState() {
    super.initState();
    // Takes the ring as the confirm opens; autofocus would lose to the control focused before it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    _node.dispose();
    super.dispose();
  }

  void _press(bool held) {
    if (held == _held) return;
    setState(() => _held = held);
    if (held) {
      _fill.animateTo(1, duration: _hold);
    } else {
      _fill.animateBack(0, duration: const Duration(milliseconds: 200));
    }
  }

  // OK is held, not pressed: its key down starts the fill and its key up stops it.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_okKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    // Chimes as the hold starts, once: the reference's repeats with every repeated key down.
    if (event is KeyDownEvent) {
      Chime.play();
      _press(true);
    }
    if (event is KeyUpEvent) _press(false);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: TvFocusable(
        focusNode: _node,
        borderRadius: _pill,
        semanticLabel: 'Hold OK for 3 seconds to unpair this TV',
        builder: (context, focused) {
          final ink = focused ? Colors.white : TvColors.destructive;
          return Container(
            constraints: const BoxConstraints(minHeight: 64 * px),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: focused ? TvColors.destructive : Colors.white,
              borderRadius: _pill,
              border: Border.all(color: TvColors.destructive, width: 2 * px),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _fill.value,
                      child: ColoredBox(
                        color: TvColors.destructive.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.5 * rem,
                    vertical: rem,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 0.75 * rem,
                    children: [
                      Icon(LucideIcons.unplug, size: 1.25 * rem, color: ink),
                      Text(
                        _held ? 'Keep holding…' : 'Hold OK for 3 seconds',
                        style: TvText.base.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
