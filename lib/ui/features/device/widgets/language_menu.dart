import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/language_flag.dart';
import '../../../../core/widgets/language_picker.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../device_controller.dart';

/// The language pill in every guest screen's top bar, reached by pressing up from the top row.
/// Opens the console's own picker, fed this room's options; hidden where the room offers none.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  static const _pill = BorderRadius.all(Radius.circular(999));

  @override
  Widget build(BuildContext context) {
    final device = DeviceScope.of(context);
    final config = switch (device.phase) {
      DeviceReady(:final config) => config,
      _ => null,
    };
    if (config == null || config.languages.isEmpty) {
      return const SizedBox.shrink();
    }

    String? nameOf(String? code) =>
        config.languages.where((l) => l.code == code).firstOrNull?.name;
    final roomDefault = nameOf(config.defaultLanguage);

    return TvFocusable(
      ring: false,
      borderRadius: _pill,
      semanticLabel: 'Language',
      onSelect: () => _open(context, device, roomDefault),
      builder: (context, focused) {
        final ink = focused ? Colors.white : TvColors.foreground;
        return AnimatedScale(
          scale: focused ? 1.05 : 1,
          duration: const Duration(milliseconds: 150),
          curve: TvMotion.focus,
          child: AnimatedContainer(
            duration: TvMotion.focusDuration,
            // A floor in px: the only control in the top bar of every kid screen must stay easy to hit.
            constraints: const BoxConstraints(minHeight: 56 * px),
            padding: const EdgeInsets.symmetric(
              horizontal: 1.25 * rem,
              vertical: 0.5 * rem,
            ),
            decoration: BoxDecoration(
              color: focused ? null : Colors.white.withValues(alpha: 0.8),
              gradient: focused ? TvColors.brand : null,
              borderRadius: _pill,
              border: Border.all(
                color: focused ? Colors.transparent : TvColors.border,
                width: 2 * px,
              ),
              boxShadow: focused
                  ? TvShadows.lg(TvColors.primary.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 0.625 * rem,
              children: [
                // What the catalogue is actually read in, chosen or inherited.
                LanguageFlag(
                  code: device.language ?? config.defaultLanguage,
                  width: 2.1 * rem,
                  height: 1.4 * rem,
                  fallback: Icon(
                    LucideIcons.languages,
                    size: 1.5 * rem,
                    color: ink,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 12 * rem),
                  child: Text(
                    nameOf(device.language) ?? roomDefault ?? 'Every language',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvText.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 1.25 * rem,
                  color: ink.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // On the root navigator, so the dialog covers the side rail too; Back pops it, and focus returns to the pill.
  // No backdrop blur: the hero animates underneath, which would re-blur the whole screen every frame.
  void _open(
    BuildContext context,
    DeviceController device,
    String? roomDefault,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: TvColors.foreground.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, _, child) {
        final t = TvMotion.focus.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * px * (1 - t)),
            child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
          ),
        );
      },
      pageBuilder: (context, _, _) =>
          _LanguageDialog(device: device, roomDefault: roomDefault),
    );
  }
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog({required this.device, required this.roomDefault});

  final DeviceController device;
  final String? roomDefault;

  static const _radius = BorderRadius.all(Radius.circular(2 * rem));

  @override
  Widget build(BuildContext context) {
    final config = (device.phase as DeviceReady).config;
    final note = TvText.sm.copyWith(color: TvColors.mutedForeground);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TvInsets.safeX),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 78 * rem,
            maxHeight: 0.84 * MediaQuery.sizeOf(context).height,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              boxShadow: TvShadows.x2l(),
            ),
            child: Material(
              color: Colors.white,
              borderRadius: _radius,
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(2.25 * rem),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pick a language',
                      style: TvText.xl.copyWith(
                        fontFamily: TvText.fredoka,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 0.25 * rem),
                    Text(
                      'Stories are shown in the language you choose, until this TV is switched off.',
                      style: note,
                    ),
                    const SizedBox(height: 1.5 * rem),
                    LanguagePicker(
                      label: null,
                      options: config.languages,
                      value: device.language,
                      autofocus: true,
                      noneLabel: roomDefault != null
                          ? 'As set for this room ($roomDefault)'
                          : 'Everything this room has',
                      onChanged: (code) {
                        device.chooseLanguage(code);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 1.5 * rem),
                    Center(child: Text('Press Back to close', style: note)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
