import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_evolution_reveal.dart';

void main() {
  for (final externalClock in [false, true]) {
    testWidgets('切替時は画像端まで白光で隠し、終了後は原色で表示 clock=$externalClock',
        (tester) async {
      final clock = AnimationController(vsync: tester);
      const boundaryKey = ValueKey('pixels');
      const afterKey = ValueKey('after');
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                      width: 300,
                      height: 390,
                      child: TrainingEvolutionReveal(
                        beforeFrame: SametarohAssets.newbornFrame,
                        afterFrame: SametarohAssets.newbornFrame,
                        beforeSize: const Size(128, 184),
                        afterSize: const Size(128, 184),
                        afterVisual: const SizedBox(
                            key: afterKey,
                            width: 128,
                            height: 184,
                            child: ColoredBox(color: Color(0xffff0000))),
                        animation: externalClock ? clock : null,
                        sceneDuration: externalClock
                            ? TrainingEvolutionReveal.pageDuration(false)
                            : null,
                      ))))));
      await tester.pump();
      var elapsed = 0;
      Future<void> at(int milliseconds) async {
        if (externalClock) {
          clock.value = milliseconds /
              TrainingEvolutionReveal.pageDuration(false).inMilliseconds;
          await tester.pump();
        } else {
          await tester.pump(Duration(milliseconds: milliseconds - elapsed));
        }
        elapsed = milliseconds;
      }

      Future<void> checkPixels(bool covered) async {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data =
              await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          for (final point in [
            const Offset(100, 120),
            const Offset(200, 270)
          ]) {
            final index =
                (point.dy.toInt() * image.width + point.dx.toInt()) * 4;
            if (covered) {
              expect(data!.getUint8(index), greaterThan(220));
              expect(data.getUint8(index + 1), greaterThan(240));
              expect(data.getUint8(index + 2), greaterThan(240));
            } else {
              expect(data!.getUint8(index), 255);
              expect(data.getUint8(index + 1), 0);
              expect(data.getUint8(index + 2), 0);
            }
          }
          image.dispose();
        });
      }

      await at(3999);
      await checkPixels(true);
      final beforeSwap = tester.getRect(find.byKey(afterKey));
      await at(4001);
      await checkPixels(true);
      expect(tester.getRect(find.byKey(afterKey)), beforeSwap);
      await at(5800);
      await at(6999);
      final last = tester.getRect(find.byKey(afterKey));
      await at(7020);
      await checkPixels(false);
      expect(tester.getRect(find.byKey(afterKey)), last);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      clock.dispose();
    });
  }
}
