import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';

/// The heading a console screen opens with: a sticker icon chip, the title in the brand gradient,
/// a line of context, and the screen's primary action opposite.
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.icon,
    this.badge,
    this.subtitle,
    this.action,
  });

  final String title;
  final IconData? icon;

  /// Sits after the title, e.g. the signed-in role.
  final Widget? badge;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TvText.base.copyWith(color: TvColors.mutedForeground);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1.25 * rem,
      children: [
        if (icon != null) _StickerChip(icon: icon!),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: rem,
                children: [_GradientTitle(title), ?badge],
              ),
              if (subtitle != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 60 * TvText.ch(subtitleStyle),
                  ),
                  child: Text(subtitle!, style: subtitleStyle),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Room for descenders, which a gradient clip would otherwise shear off.
      padding: const EdgeInsets.only(bottom: 0.25 * rem),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: TvColors.brand.createShader,
        child: Text(
          text,
          style: TvText.x2l.copyWith(
            fontFamily: TvText.baloo,
            fontWeight: FontWeight.w800,
            height: TvText.tight,
            letterSpacing: TvText.trackingTight * TvText.x2l.fontSize!,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// A tilted gradient tile with a white edge, so it reads as a sticker rather than a flat icon box.
class _StickerChip extends StatefulWidget {
  const _StickerChip({required this.icon});

  final IconData icon;

  @override
  State<_StickerChip> createState() => _StickerChipState();
}

class _StickerChipState extends State<_StickerChip>
    with SingleTickerProviderStateMixin {
  static const _radius = BorderRadius.all(Radius.circular(1.35 * rem));
  static final _arrive = SpringCurve(
    stiffness: 300,
    damping: 13,
    duration: const Duration(milliseconds: 900),
  );

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: 3.75 * rem,
      height: 3.75 * rem,
      decoration: BoxDecoration(
        gradient: TvColors.brand,
        borderRadius: _radius,
        boxShadow: [
          TvShadows.css(const Color(0xA6AD46FF), 12, 28, -8),
          // Tailwind's `ring-4 ring-white`, painted over the shadow as in CSS.
          const BoxShadow(color: Colors.white, spreadRadius: 4 * px),
        ],
      ),
      child: Icon(widget.icon, size: 2 * rem, color: Colors.white),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _arrive.duration,
      curve: _arrive,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.rotate(
          // Settles at −6°, arriving from −22°.
          angle: (-22 + 16 * t) * math.pi / 180,
          child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
        ),
      ),
      child: AnimatedBuilder(
        animation: _float,
        // y [0, −5, 0] over 3.4s, easeInOut each way.
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            -5 *
                px *
                Curves.easeInOut.transform(1 - (2 * _float.value - 1).abs()),
          ),
          child: child,
        ),
        child: chip,
      ),
    );
  }
}
