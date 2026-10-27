import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_opponent_visual.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF B frames retain transparent margins, feet and distinct ball poses',
      () async {
    final ballCenters = <double>[];
    for (final path in [
      TackleOpponentVisual.assetPathA,
      TackleOpponentVisual.assetPathB,
    ]) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 112);
      expect(image.height, 112);
      final rgba =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var top = 112;
      var bottom = 0;
      var redCount = 0;
      var redY = 0;
      var whiteCount = 0;
      for (var y = 0; y < 112; y++) {
        for (var x = 0; x < 112; x++) {
          final i = (y * 112 + x) * 4;
          final r = rgba.getUint8(i);
          final g = rgba.getUint8(i + 1);
          final b = rgba.getUint8(i + 2);
          final a = rgba.getUint8(i + 3);
          if (x == 0 || x == 111 || y == 0 || y == 111) {
            expect(a, 0, reason: 'No clipped edge in $path');
          }
          if (a < 128) continue;
          if (y < top) top = y;
          if (y + 1 > bottom) bottom = y + 1;
          if (r > 150 && g < 90 && b < 100) {
            redCount++;
            redY += y;
          }
          if (r > 235 && g > 235 && b > 235) whiteCount++;
        }
      }
      expect(top, inInclusiveRange(8, 10));
      expect(bottom, 104);
      expect(whiteCount, greaterThan(10), reason: 'White eyes and teeth');
      expect(redCount, greaterThan(10), reason: 'Original red ball markings');
      ballCenters.add(redY / redCount);
      image.dispose();
      codec.dispose();
    }
    // In the source B pair, the left frame carries the ball below the right.
    // This rejects the previous pair, where both balls were near the chest.
    expect(ballCenters[0] - ballCenters[1], greaterThan(4));
  });
}
