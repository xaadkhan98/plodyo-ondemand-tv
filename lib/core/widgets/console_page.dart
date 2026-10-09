import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tv_colors.dart';
import '../theme/tv_scale.dart';
import '../theme/tv_typography.dart';
import 'page_layout.dart';
import 'side_nav.dart';

/// The Plodyo wordmark bar. In the scroll flow rather than pinned: on a D-pad panel scrolling is a side
/// effect of focus moving, and a retracting bar hid and reappeared on unrelated presses.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.actions});

  /// Reached by moving up, e.g. the language pill over the catalogue.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SideNav.collapsedWidth + TvInsets.safeX,
        1.25 * rem,
        TvInsets.safeX,
        1.25 * rem,
      ),
      child: Row(
        spacing: 0.75 * rem,
        children: [
          SvgPicture.asset('assets/images/logo.svg', height: 2.5 * rem),
          Text(
            'Plodyo',
            style: TvText.xl.copyWith(
              fontFamily: TvText.fredoka,
              fontWeight: FontWeight.w600,
              letterSpacing: TvText.trackingTight * TvText.xl.fontSize!,
              color: TvColors.wordmark,
            ),
          ),
          if (actions != null) ...[const Spacer(), actions!],
        ],
      ),
    );
  }
}

/// A console screen's frame: the [TopBar] and the screen scroll together as one, offset past the
/// collapsed [SideNav], inside the overscan gutters and centred up to [maxWidth].
class ConsolePage extends StatelessWidget {
  const ConsolePage({
    super.key,
    required this.child,
    this.maxWidth = 75 * rem,
    this.actions,
  }) : _fill = false;

  /// A full-pane state — a spinner or a notice — that takes the height under the bar instead of scrolling.
  const ConsolePage.fill({super.key, required this.child, this.actions})
    : maxWidth = double.infinity,
      _fill = true;

  final Widget child;
  final double maxWidth;
  final Widget? actions;
  final bool _fill;

  @override
  Widget build(BuildContext context) {
    final bar = TopBar(actions: actions);
    return Scaffold(
      body: _fill
          ? Column(
              children: [
                bar,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: SideNav.collapsedWidth,
                    ),
                    child: child,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  bar,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SideNav.collapsedWidth + TvInsets.safeX,
                      0,
                      TvInsets.safeX,
                      TvInsets.safeY,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Entrance(child: child),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
