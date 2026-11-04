import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_ocean_decoration.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('深海の装飾は指定した範囲からはみ出さず描画状態を戻す dark=$dark', (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const rect = Rect.fromLTWH(20, 20, 160, 80);
        paintTrainingOceanSurface(canvas, rect, dark: dark);
        // helperのclip/translateが後続の描画へ残らないことも確認します。
        canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 2),
            Paint()..color = const Color(0xffff0000));
        final picture = recorder.endRecording();
        final image = await picture.toImage(200, 120);
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        expect(bytes.getUint8(0), 255);
        expect(bytes.getUint8(3), 255);
        for (var y = 2; y < image.height; y++) {
          for (var x = 2; x < image.width; x++) {
            final alpha = bytes.getUint8((y * image.width + x) * 4 + 3);
            expect(alpha, rect.contains(Offset(x + .5, y + .5)) ? 255 : 0,
                reason: '描画境界 ($x, $y)');
          }
        }
        image.dispose();
        picture.dispose();
      });
    });
  }
}
