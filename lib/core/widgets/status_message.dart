import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

enum StatusTone { error, success, warning, info }

/// Inline banner for anything a screen needs to say without navigating away. The app has no snackbars.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.icon,
  });

  final StatusTone tone;
  final String message;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Success is mint, never violet: a violet banner reads as another button.
    final (surface, titleColor, bodyColor) = switch (tone) {
      StatusTone.error => (
        TvColors.destructive.withValues(alpha: 0.1),
        TvColors.destructive,
        TvColors.destructive,
      ),
      StatusTone.success => (
        TvColors.mint.withValues(alpha: 0.15),
        TvColors.mintInk,
        TvColors.mintInk,
      ),
      StatusTone.warning => (
        TvColors.sun.withValues(alpha: 0.2),
        TvColors.sunInk,
        TvColors.sunInk,
      ),
      StatusTone.info => (
        TvColors.muted,
        TvColors.foreground,
        TvColors.mutedForeground,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -4 * px * (1 - t)),
            child: child,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 1.25 * rem,
            vertical: rem,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(rem),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 0.75 * rem,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(top: 0.125 * rem),
                  child: Icon(icon, color: titleColor, size: 1.25 * rem),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 0.25 * rem,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TvText.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    Text(
                      message,
                      style: TvText.sm.copyWith(
                        fontWeight: title == null
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
