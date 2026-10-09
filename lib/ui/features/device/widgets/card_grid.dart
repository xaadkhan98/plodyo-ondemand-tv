import 'package:flutter/widgets.dart';

import '../../../../core/theme/tv_scale.dart';

/// The reference's `grid grid-cols-4`: equal columns, cards top-aligned, and a short last row keeping its
/// cells' width. Rows of [Expanded] rather than a sliver grid, so a card's height is its own content's.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.gap = 2 * rem,
  });

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        for (var start = 0; start < children.length; start += columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: gap,
            children: [
              for (var i = start; i < start + columns; i++)
                Expanded(
                  child: i < children.length ? children[i] : const SizedBox(),
                ),
            ],
          ),
      ],
    );
  }
}
