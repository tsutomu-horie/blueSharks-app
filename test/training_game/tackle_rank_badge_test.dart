import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_rank_badge.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('LINESeedJP')
          ..addFont(
              rootBundle.load('assets/fonts/line_seed_jp/LINESeedJP-Bold.ttf')))
        .load();
  });

  for (final rank in ['S', 'A', 'B', 'C', 'D']) {
    testWidgets('評価 $rank の描画がバッジの上下左右中央になる', (tester) async {
      final capture = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: RepaintBoundary(
              key: capture,
              child: TackleRankBadge(rank: rank, color: Colors.white),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        final image = await (capture.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        var mass = 0.0;
        var xSum = 0.0;
        var top = image.height;
        var bottom = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            // 円周を除外し、背景との差から英字の描画量だけを測ります。
            if (Offset(x + .5 - 132, y + .5 - 132).distance > 110) continue;
            final alpha = bytes.getUint8((y * image.width + x) * 4 + 3);
            final ink = (alpha - 26).clamp(0, 229).toDouble();
            mass += ink;
            xSum += (x + .5) * ink;
            if (alpha > 50) {
              if (y < top) top = y;
              if (y > bottom) bottom = y;
            }
          }
        }
        const output = String.fromEnvironment('RANK_CAPTURE_DIR');
        if (output.isNotEmpty) {
          await Directory(output).create(recursive: true);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$output/rank-$rank.png')
              .writeAsBytes(png!.buffer.asUint8List());
        }
        image.dispose();
        expect(mass, greaterThan(0));
        expect(xSum / mass / 2, closeTo(66, .75));
        expect((top + bottom + 1) / 4, closeTo(66, .75));
      });
    });
  }
}
