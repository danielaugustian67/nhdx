import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihondx/core/theme/app_colors.dart';

/// Draws the launcher icon sources (1024 px) from the sign-in screen's mark:
/// a vermilion hanko with 日本 on the plum night sky (ui-design §1.2). Run
/// it by hand, then `dart run flutter_launcher_icons`:
///
///   flutter test tool/app_icon/render_icon_test.dart
///
/// - app_icon.png: full icon (iOS, Android before adaptive icons), opaque
/// - app_icon_background.png: adaptive background, the sky alone
/// - app_icon_foreground.png: adaptive foreground, stamp inside the 66/108
///   safe zone, on transparent
/// - app_icon_monochrome.png: Android 13 themed icon, white on transparent
void main() {
  const size = 1024.0;
  const out = 'tool/app_icon';
  final c = AppColors.dark;

  setUpAll(() async {
    final loader = FontLoader(
      'ZenKakuGothicNew',
    )..addFont(Future.value(ByteData.sublistView(File('assets/fonts/ZenKakuGothicNew-Regular.ttf').readAsBytesSync())));
    await loader.load();
  });

  void sky(Canvas canvas) {
    const rect = Rect.fromLTWH(0, 0, size, size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1A30), Color(0xFF141019)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 0.75,
          colors: [c.primary.withValues(alpha: 0.38), c.primary.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  /// The stamp, [side] px wide, centered and tilted like a hand-pressed seal.
  void stamp(Canvas canvas, double side, {bool mono = false}) {
    final ink = mono ? Colors.white : c.seal;
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.rotate(-4 * math.pi / 180);
    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      Radius.circular(side * 0.22),
    );
    if (!mono) {
      canvas.drawRRect(
        box,
        Paint()
          ..color = c.seal.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, side * 0.08),
      );
      canvas.drawRRect(box, Paint()..color = c.seal.withValues(alpha: 0.14));
    }
    final border = side * 0.065;
    canvas.drawRRect(
      box.deflate(border / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border
        ..color = ink,
    );

    // 日 over 本, like the name on a real seal; a stroke thickens the
    // regular-weight glyphs so they read at launcher size.
    final fontSize = side * 0.36;
    for (final (i, ch) in ['日', '本'].indexed) {
      for (final fill in [false, true]) {
        final painter = TextPainter(
          text: TextSpan(
            text: ch,
            locale: const Locale('ja'),
            style: TextStyle(
              fontFamily: 'ZenKakuGothicNew',
              fontSize: fontSize,
              height: 1,
              foreground: fill
                  ? (Paint()..color = ink)
                  : (Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = fontSize * 0.045
                      ..strokeJoin = StrokeJoin.round
                      ..color = ink),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final y = (i == 0 ? -1.0 : 0.0) * fontSize * 1.02 + (i == 0 ? -fontSize * 0.01 : fontSize * 0.03);
        painter.paint(canvas, Offset(-painter.width / 2, y));
      }
    }
    canvas.restore();
  }

  Future<void> save(String name, void Function(Canvas) draw) async {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$out/$name').writeAsBytesSync(png!.buffer.asUint8List());
  }

  testWidgets('renders the launcher icon sources', (tester) async {
    await tester.runAsync(() async {
      await save('app_icon.png', (canvas) {
        sky(canvas);
        stamp(canvas, size * 0.56);
      });
      // Adaptive icons crop to a 66/108 circle (radius 312 px here); the
      // rounded stamp reaches 0.616 × its side from the center, so 0.48 fits.
      await save('app_icon_background.png', sky);
      await save('app_icon_foreground.png', (canvas) => stamp(canvas, size * 0.48));
      await save('app_icon_monochrome.png', (canvas) => stamp(canvas, size * 0.48, mono: true));
    });
  });
}
