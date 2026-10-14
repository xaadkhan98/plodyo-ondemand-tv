import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_colors.dart';
import 'package:plodyo_ondemand_tv/core/theme/tv_scale.dart';

void main() {
  // Physical size and density of real panels: this MiTV, a 1080p xhdpi box, a 4K box, and a 16:10 monitor.
  const screens = {
    'MiTV 1280x720 @213dpi': (Size(1280, 720), 1.33125, Size(960, 540)),
    '1080p @xhdpi': (Size(1920, 1080), 2.0, Size(960, 540)),
    '4K @xxhdpi': (Size(3840, 2160), 3.0, Size(960, 540)),
    '16:10 desktop': (Size(1920, 1200), 1.0, Size(960, 600)),
  };

  for (final MapEntry(key: name, value: (physical, dpr, expected))
      in screens.entries) {
    testWidgets('TvCanvas lays out on the design canvas on $name', (
      tester,
    ) async {
      tester.view.physicalSize = physical;
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      late Size canvas;
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: TvCanvas(
            child: Builder(
              builder: (context) {
                canvas = MediaQuery.sizeOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(canvas.width, closeTo(expected.width, 0.01));
      expect(canvas.height, closeTo(expected.height, 0.01));
    });
  }

  test('CssGradientAngle(135) starts and ends where CSS does on a wide box', () {
    const bounds = Rect.fromLTWH(0, 0, 200, 100);
    final matrix = const CssGradientAngle(135).transform(bounds);
    // CSS: the line runs through the centre at 45°, sized so the corners hit 0% and 100%.
    final start = MatrixUtils.transformPoint(matrix, const Offset(0, 50));
    final end = MatrixUtils.transformPoint(matrix, const Offset(200, 50));
    expect(start.dx, closeTo(25, 0.01));
    expect(start.dy, closeTo(-25, 0.01));
    expect(end.dx, closeTo(175, 0.01));
    expect(end.dy, closeTo(125, 0.01));
  });
}
