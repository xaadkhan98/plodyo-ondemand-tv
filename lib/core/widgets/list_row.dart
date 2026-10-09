import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_shadows.dart';
import '../theme/tv_typography.dart';
import 'tv_focusable.dart';

/// The bordered row every console list is made of: icon, title with badges, a line of detail, and a chevron
/// when it opens something. Without [onSelect] it is a plain card, e.g. an invite with its own buttons.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.badges = const [],
    this.meta = const [],
    this.body,
    this.trailing,
    this.onSelect,
    this.autofocus = false,
    this.dimmed = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> badges;

  /// Short facts on one line under the title, e.g. [MetaItem]s.
  final List<Widget> meta;

  /// A sentence under the title instead of [meta]; the row then top-aligns.
  final String? body;

  /// Replaces the chevron, e.g. a row's own action buttons.
  final Widget? trailing;
  final VoidCallback? onSelect;
  final bool autofocus;

  /// Faded while an action on this row is in flight.
  final bool dimmed;

  static const _radius = BorderRadius.all(Radius.circular(rem));

  @override
  Widget build(BuildContext context) {
    if (onSelect == null) {
      return Opacity(opacity: dimmed ? 0.6 : 1, child: _card(focused: false));
    }
    return TvFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      borderRadius: _radius,
      semanticLabel: title,
      builder: (context, focused) => _card(focused: focused),
    );
  }

  Widget _card({required bool focused}) {
    final topAligned = body != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 1.5 * rem,
        vertical: 1.25 * rem,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(
          color: focused ? TvColors.primary : TvColors.border,
          width: 2 * px,
        ),
        boxShadow: focused ? TvShadows.lg() : null,
      ),
      child: Row(
        crossAxisAlignment: topAligned
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        spacing: 1.25 * rem,
        children: [
          Padding(
            padding: EdgeInsets.only(top: topAligned ? 0.125 * rem : 0),
            child: Icon(
              icon,
              size: 1.75 * rem,
              color: TvColors.mutedForeground,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 0.25 * rem,
              children: [
                Row(
                  spacing: 0.75 * rem,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TvText.base.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...badges,
                  ],
                ),
                if (body != null)
                  Text(
                    body!,
                    style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                  ),
                if (meta.isNotEmpty)
                  DefaultTextStyle(
                    style: TvText.sm.copyWith(color: TvColors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: Row(spacing: 1.25 * rem, children: meta),
                  ),
              ],
            ),
          ),
          trailing ??
              Padding(
                padding: EdgeInsets.only(top: topAligned ? 0.125 * rem : 0),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 1.5 * rem,
                  color: focused ? TvColors.primary : TvColors.mutedForeground,
                ),
              ),
        ],
      ),
    );
  }
}

/// One fact in a [ListRow]'s detail line: a small icon and its text.
class MetaItem extends StatelessWidget {
  const MetaItem(this.text, {super.key, this.icon, this.leading});

  final String text;
  final IconData? icon;

  /// In place of [icon], e.g. a flag.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 0.375 * rem,
        children: [
          leading ??
              (icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, size: rem, color: TvColors.mutedForeground)),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
