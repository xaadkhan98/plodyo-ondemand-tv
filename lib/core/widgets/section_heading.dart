import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';

/// A section's `h2` and its supporting line, as the reference sets every section heading.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = TvText.sm.copyWith(
      color: TvColors.mutedForeground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 0.25 * rem,
      children: [
        Text(
          title,
          style: TvText.lg.copyWith(
            fontFamily: TvText.fredoka,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 60 * TvText.ch(descriptionStyle),
            ),
            child: Text(description!, style: descriptionStyle),
          ),
      ],
    );
  }
}
