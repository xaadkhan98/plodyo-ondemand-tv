import 'package:flutter/widgets.dart';

/// Box shadows painted only outside the box, as CSS draws them. Flutter's BoxShadow also paints under
/// the box, which shows through a translucent fill as a tinted panel.
class OutsetShadow extends StatelessWidget {
  const OutsetShadow({
    super.key,
    required this.shadows,
    required this.borderRadius,
    required this.child,
  });

  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _OutsetShadowPainter(shadows, borderRadius),
    child: child,
  );
}

class _OutsetShadowPainter extends CustomPainter {
  const _OutsetShadowPainter(this.shadows, this.borderRadius);

  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final box = borderRadius.toRRect(bounds);
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(bounds.inflate(size.longestSide))
          ..addRRect(box),
      );
    for (final shadow in shadows) {
      canvas.drawRRect(
        box.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutsetShadowPainter oldDelegate) =>
      oldDelegate.shadows != shadows ||
      oldDelegate.borderRadius != borderRadius;
}
