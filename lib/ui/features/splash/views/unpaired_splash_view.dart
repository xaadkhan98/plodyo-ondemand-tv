import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_motion.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_shadows.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/outset_shadow.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/setup_scene.dart';
import '../../../../core/widgets/tv_button.dart';

/// What a set out of its box shows until someone pairs it: the guest surface's front door,
/// and the only screen an installer sees before the catalogue.
class UnpairedSplashView extends StatelessWidget {
  const UnpairedSplashView({super.key, this.onSetupTv, this.onSignInConsole});

  final VoidCallback? onSetupTv;
  final VoidCallback? onSignInConsole;

  static const _cardRadius = BorderRadius.all(Radius.circular(2.5 * rem));
  static final _arrival = SpringCurve(
    stiffness: 240,
    damping: 16,
    duration: const Duration(milliseconds: 800),
  );

  @override
  Widget build(BuildContext context) {
    final body = TvText.base.copyWith(color: TvColors.mutedForeground);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: NightBackdrop()),
          CenteredScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 52 * rem),
              child: OutsetShadow(
                shadows: TvShadows.x2l(
                  TvColors.primary.withValues(alpha: 0.25),
                ),
                borderRadius: _cardRadius,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3 * rem,
                    vertical: 2.5 * rem,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: _cardRadius,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The one motion on this screen: the set arriving is the change it announces.
                      _arrivingArt(context),
                      const SizedBox(height: 1.75 * rem),
                      Text(
                        'This TV is not set up yet',
                        textAlign: TextAlign.center,
                        style: TvText.x2l.copyWith(
                          fontFamily: TvText.baloo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 0.75 * rem),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 46 * TvText.ch(body),
                        ),
                        child: Text(
                          'Pair it with a room to show the story library, or sign in to run the Plodyo console from this screen.',
                          textAlign: TextAlign.center,
                          style: body,
                        ),
                      ),
                      const SizedBox(height: 1.5 * rem),
                      const _CodeHint(),
                      const SizedBox(height: 2 * rem),
                      // Wraps rather than overflowing if a label runs long.
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: rem,
                        runSpacing: rem,
                        children: [
                          TvButton(
                            label: 'Set up this TV',
                            icon: LucideIcons.tv,
                            autofocus: true,
                            onSelect:
                                onSetupTv ?? () => context.push('/pair-tv'),
                          ),
                          TvButton(
                            label: 'Sign in to the console',
                            icon: LucideIcons.logIn,
                            variant: TvButtonVariant.outline,
                            onSelect:
                                onSignInConsole ??
                                () => context.push('/sign-in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrivingArt(BuildContext context) {
    const art = TvSetArt(height: 11 * rem);
    if (MediaQuery.disableAnimationsOf(context)) return art;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _arrival.duration,
      curve: _arrival,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 16 * px * (1 - t)),
          child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
        ),
      ),
      child: art,
    );
  }
}

/// The one thing to fetch before pressing anything, so it gets a filled pill rather than a third grey line.
class _CodeHint extends StatelessWidget {
  const _CodeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 1.5 * rem,
        vertical: 0.75 * rem,
      ),
      decoration: BoxDecoration(
        color: TvColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.75 * rem,
        children: [
          const Icon(
            LucideIcons.keyRound,
            size: 1.25 * rem,
            color: TvColors.primary,
          ),
          Flexible(
            child: Text(
              'Find the code on the room’s page in the console. It lasts fifteen minutes.',
              style: TvText.sm,
            ),
          ),
        ],
      ),
    );
  }
}
