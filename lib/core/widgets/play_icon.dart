import 'package:flutter/widgets.dart';

/// Lucide's Play drawn filled, as `fill-current` renders it on the web; the icon font only strokes.
class PlayIcon extends StatelessWidget {
  const PlayIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _PlayPainter(color));
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Lucide's 24-unit polygon 6,3 20,12 6,21, filled and stroked at 2 with round joins.
    final unit = size.width / 24;
    final triangle = Path()
      ..moveTo(6 * unit, 3 * unit)
      ..lineTo(20 * unit, 12 * unit)
      ..lineTo(6 * unit, 21 * unit)
      ..close();
    canvas
      ..drawPath(triangle, Paint()..color = color)
      ..drawPath(
        triangle,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * unit
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_PlayPainter old) => old.color != color;
}
