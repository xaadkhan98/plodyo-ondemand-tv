import 'package:flutter/material.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_motion.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'page_layout.dart';
import 'tv_button.dart';

/// One action under a [NoticeScreen]; the first defaults to primary, the rest to outline.
class NoticeAction {
  const NoticeAction({
    required this.label,
    required this.onSelect,
    this.variant,
    this.busy = false,
  });

  final String label;
  final VoidCallback onSelect;
  final TvButtonVariant? variant;
  final bool busy;
}

/// Full-screen outcome: an icon, what happened, and what to do next. Every terminal state —
/// link sent, invite expired, network unreachable — shares this one layout.
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.footnote,
    this.actions = const [],
  });

  final Widget icon;
  final String title;
  final String? body;
  final String? footnote;
  final List<NoticeAction> actions;

  static final _spring = SpringCurve(
    stiffness: 260,
    damping: 15,
    duration: const Duration(milliseconds: 700),
  );

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TvText.base.copyWith(color: TvColors.mutedForeground);
    final footnoteStyle = TvText.sm.copyWith(color: TvColors.mutedForeground);

    // Scrolls rather than clips: a long body can outgrow a short panel.
    return CenteredScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: _spring.duration,
            curve: _spring,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 14 * px * (1 - t)),
                child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
              ),
            ),
            child: icon,
          ),
          const SizedBox(height: 1.5 * rem),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TvText.x2l.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 0.75 * rem),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 54 * TvText.ch(bodyStyle)),
              child: Text(body!, textAlign: TextAlign.center, style: bodyStyle),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 0.5 * rem),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 54 * TvText.ch(footnoteStyle),
              ),
              child: Text(
                footnote!,
                textAlign: TextAlign.center,
                style: footnoteStyle,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 2 * rem),
            // Wraps rather than overflowing if a label runs long.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: rem,
              runSpacing: rem,
              children: [
                for (final (index, action) in actions.indexed)
                  TvButton(
                    label: action.label,
                    onSelect: action.onSelect,
                    busy: action.busy,
                    // The first action is the one a remote should land on.
                    autofocus: index == 0,
                    variant:
                        action.variant ??
                        (index == 0
                            ? TvButtonVariant.primary
                            : TvButtonVariant.outline),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
