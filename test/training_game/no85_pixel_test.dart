import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  testWidgets(
    'rendered red ball bounds: hold release catch, front/back and compact canvas',
    (t) async {
      final key = GlobalKey();
      Future<Rect> pixels(Widget child) async {
        await t.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: ColoredBox(color: Colors.green, child: child),
                ),
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          final c = key.currentContext!;
          for (final a in PassAndRunCharacterVisual.assets) {
            await precacheImage(AssetImage(a), c);
          }
        });
        await t.pumpAndSettle();
        final image = await t.runAsync(
          () =>
              (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
                  .toImage(pixelRatio: 3),
        );
        final data = await t.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        final b = data!.buffer.asUint8List();
        int x0 = image!.width, y0 = image!.height, x1 = -1, y1 = -1;
        for (int y = 0; y < image!.height; y++) {
          for (int x = 0; x < image!.width; x++) {
            final i = (y * image!.width + x) * 4;
            if (b[i] > 120 && b[i] > b[i + 1] * 1.5 && b[i] > b[i + 2] * 1.35) {
              if (x < x0) x0 = x;
              if (x > x1) x1 = x;
              if (y < y0) y0 = y;
              if (y > y1) y1 = y;
            }
          }
        }
        image!.dispose();
        expect(x1, greaterThan(x0));
        return Rect.fromLTRB(x0 / 3, y0 / 3, (x1 + 1) / 3, (y1 + 1) / 3);
      }

      for (final size in [60.0, 78.0, 84.0]) {
        for (final facing in PassRunFacing.values) {
          for (final frame in [0, 1]) {
            final g = PassAndRunCharacterVisual.heldBallGeometry(
              character: PassRunCharacter.normal,
              frame: frame,
              facing: facing,
              size: size * PassAndRunCharacterVisual.candidateVisualScale,
            );
            final flight = await pixels(
              Stack(
                children: [
                  Positioned(
                    left: 70 + g.offset.dx - g.extent / 2,
                    top: 70 + g.offset.dy - g.extent / 2,
                    child: PassAndRunBallVisual(geometry: g),
                  ),
                ],
              ),
            );
            for (final progress in [0.0, .25, .5, .75, 1.0]) {
              final target = Offset(
                70 + g.offset.dx + progress * 12,
                70 + g.offset.dy - progress * 8,
              );
              final moving = await pixels(
                Stack(
                  children: [
                    Positioned(
                      left: target.dx - g.extent / 2,
                      top: target.dy - g.extent / 2,
                      child: PassAndRunBallVisual(geometry: g),
                    ),
                  ],
                ),
              );
              expect(
                (moving.center -
                        (flight.center + Offset(progress * 12, -progress * 8)))
                    .distance,
                lessThan(1),
              );
              expect(moving.width, closeTo(flight.width, 1));
              expect(moving.height, closeTo(flight.height, 1));
            }
            for (final kind in PassRunCharacter.values) {
              final held = await pixels(
                Center(
                  child: PassAndRunCharacterVisual(
                    character: kind,
                    holding: true,
                    frame: frame,
                    facing: facing,
                    size: size,
                    visualScale: 1.15,
                  ),
                ),
              );
              if (facing == PassRunFacing.front) {
                expect((held.center - flight.center).distance, lessThan(1));
                expect(held.width, closeTo(flight.width, 1));
                expect(held.height, closeTo(flight.height, 1));
              } else {
                expect(held.left, greaterThanOrEqualTo(flight.left - 1));
                expect(held.right, lessThanOrEqualTo(flight.right + 1));
                expect(held.top, greaterThanOrEqualTo(flight.top - 1));
                expect(held.bottom, lessThanOrEqualTo(flight.bottom + 1));
              }
              expect(held.left, greaterThan(0));
              expect(held.bottom, lessThan(140));
            }
          }
        }
      }
    },
  );
}
