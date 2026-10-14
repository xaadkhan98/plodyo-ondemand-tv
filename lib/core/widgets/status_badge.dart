import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

enum BadgeTone { neutral, positive, pending, negative }

/// Small pill for a lifecycle state: partner status, invite status, role. Tones come from the state hues,
/// so success reads mint and waiting reads sun everywhere in the app.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = switch (tone) {
      BadgeTone.neutral => (TvColors.muted, TvColors.mutedForeground),
      BadgeTone.positive => (
        TvColors.mint.withValues(alpha: 0.2),
        TvColors.mintInk,
      ),
      BadgeTone.pending => (
        TvColors.sun.withValues(alpha: 0.25),
        TvColors.sunInk,
      ),
      BadgeTone.negative => (
        TvColors.destructive.withValues(alpha: 0.1),
        TvColors.destructive,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 0.75 * rem,
        vertical: 0.25 * rem,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TvText.sm.copyWith(fontWeight: FontWeight.w600, color: ink),
      ),
    );
  }
}
