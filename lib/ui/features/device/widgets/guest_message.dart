import 'package:flutter/material.dart';

import '../../../../core/theme/tv_colors.dart';
import '../../../../core/theme/tv_scale.dart';
import '../../../../core/theme/tv_typography.dart';
import '../../../../core/widgets/tv_button.dart';
import 'guest_page.dart';

/// A story or series that could not be opened, centred in the pane, with the way back focused.
class GuestMessage extends StatelessWidget {
  const GuestMessage({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
  });

  final String title;
  final String body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final style = TvText.base.copyWith(color: TvColors.mutedForeground);
    return GuestPage.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TvText.lg.copyWith(
                fontFamily: TvText.fredoka,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 0.25 * rem),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 54 * TvText.ch(style)),
              child: Text(body, textAlign: TextAlign.center, style: style),
            ),
            const SizedBox(height: 1.75 * rem),
            TvButton(
              label: 'Back to the catalogue',
              autofocus: true,
              onSelect: onBack,
            ),
          ],
        ),
      ),
    );
  }
}
