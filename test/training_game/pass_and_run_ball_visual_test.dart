import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';

void main() {
  test('球柄の補間終点は180度反転せず、保持画と360度同値', () {
    for (final right in [true, false]) {
      final a = PassAndRunCharacterVisual.heldBallGeometry(
          character: PassRunCharacter.normal,
          frame: 0,
          facing: right ? PassRunFacing.front : PassRunFacing.back,
          size: 84);
      final b = PassAndRunCharacterVisual.heldBallGeometry(
          character: PassRunCharacter.companion,
          frame: 0,
          facing: right ? PassRunFacing.back : PassRunFacing.front,
          size: 84);
      for (final pair in [(a, b), (b, a)]) {
        final end = PassRunBallGeometry.lerp(pair.$1, pair.$2, 1);
        expect(math.cos(end.angle - pair.$2.angle), closeTo(1, .000001));
        expect(math.sin(end.angle - pair.$2.angle), closeTo(0, .000001));
      }
    }
  });
  testWidgets('縮小後の保持球と独立球の実画素寸法・中心がつながる', (t) async {
    final key = GlobalKey();
    Future<Rect> measure(Widget child) async {
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox.square(
                dimension: 112,
                child: ColoredBox(color: const Color(0xffff00ff), child: child),
              ),
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        final context = t.element(find.byKey(key));
        for (final asset in [
          'pass_run_ball',
          for (final kind in ['normal', 'mate'])
            for (final facing in ['front', 'back'])
              for (final phase in ['a', 'b'])
                'pass_run_${kind}_${facing}_hold_$phase',
        ]) {
          await precacheImage(
            AssetImage('assets/images/training_game/minigames/$asset.png'),
            context,
          );
        }
      });
      await t.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = data!.buffer.asUint8List();
        var minX = image.width, minY = image.height, maxX = -1, maxY = -1;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final i = (y * image.width + x) * 4;
            final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
            if (bytes[i + 3] > 200 && r > 120 && r > g * 1.5 && r > b * 1.35) {
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
        image.dispose();
        expect(maxX, greaterThan(minX));
        return Rect.fromLTRB(
            minX / 3, minY / 3, (maxX + 1) / 3, (maxY + 1) / 3);
      }))!;
    }

    for (final kind in PassRunCharacter.values) {
      for (final frame in [0, 1]) {
        for (final right in [true, false]) {
          final geometry = PassAndRunCharacterVisual.heldBallGeometry(
            character: kind,
            frame: frame,
            facing: right ? PassRunFacing.front : PassRunFacing.back,
            size: 84,
          );
          final held = await measure(
            Center(
              child: PassAndRunCharacterVisual(
                character: kind,
                holding: true,
                frame: frame,
                facing: right ? PassRunFacing.front : PassRunFacing.back,
                size: 84,
              ),
            ),
          );
          final flight = await measure(
            Stack(
              children: [
                Positioned(
                  left: 56 + geometry.offset.dx - geometry.extent / 2,
                  top: 56 + geometry.offset.dy - geometry.extent / 2,
                  child: PassAndRunBallVisual(geometry: geometry),
                ),
              ],
            ),
          );
          if (!right) {
            // Rear ball is deliberately occluded by the torso, not a full ellipse.
            expect(held.width, lessThan(flight.width));
            expect(held.height, lessThanOrEqualTo(flight.height + 1.5));
            expect(held.left, closeTo(flight.left, 2));
            continue;
          }
          // Compare rendered pixels, not merely the same metadata twice.
          expect(
            flight.width,
            closeTo(held.width, 1.5),
            reason: '$kind/$frame/$right width',
          );
          expect(
            flight.height,
            closeTo(held.height, 1.5),
            reason: '$kind/$frame/$right height',
          );
          expect(
            (flight.center - held.center).distance,
            lessThan(1.5),
            reason: '$kind/$frame/$right center',
          );
        }
      }
    }
    expect(t.takeException(), isNull);
  });
}
