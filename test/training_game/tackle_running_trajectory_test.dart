import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_running_trajectory.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_contact_geometry.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_player_visual.dart';

void main() {
  for (final down in [false, true]) {
    final route = TackleRunningTrajectory(
      start: const Alignment(-.18, 0),
      downward: down,
    );
    test('route C1 down=$down', () {
      const eps = .1;
      for (final time in [110.0, 220.0]) {
        final l = route.sample(time - eps),
            m = route.sample(time),
            r = route.sample(time + eps);
        expect((m.x - l.x) / eps, closeTo((r.x - m.x) / eps, .0001));
        expect((m.y - l.y) / eps, closeTo((r.y - m.y) / eps, .0001));
      }
      expect(route.sample(220).x, -.36);
      expect(route.sample(220).y, down ? .58 : -.58);
      for (var t = 221; t < 800; t++) {
        expect(route.sample(t.toDouble()).x, lessThan(route.sample(t - 1.0).x));
        expect(route.sample(t.toDouble()).y, down ? .58 : -.58);
      }
    });
    for (final width in [288.0, 328.0, 370.0]) {
      for (final tap in [0.0, 60.0, 200.0, 690.0, 749.0, 750.0]) {
        test('intercept width=$width tap=$tap down=$down', () {
          final field = Size(width, 544);
          const p = Size(72.25, 103), b = Size(58.25, 83);
          final visualTap = TackleRunningTrajectory.visualMilliseconds(tap);
          final contact = TackleRunningTrajectory.contactTime(visualTap);
          expect(contact, math.max(visualTap + 160, 240));
          final future = route.sample(contact);
          final ref = tackleContactTargets(
            field: field,
            player: p,
            opponent: b,
            downward: down,
          )!;
          final target = tackleInterceptTargets(
            field: field,
            player: p,
            opponent: b,
            reference: ref,
            future: future,
          );
          Offset c(Alignment a, Size s) => Offset(
                field.width / 2 + a.x * (field.width - s.width) / 2,
                field.height / 2 + a.y * (field.height - s.height) / 2,
              );
          final delta = c(target.playerAlignment, p) - c(future, b);
          final original =
              c(ref.playerAlignment, p) - c(ref.opponentAlignment, b);
          expect(delta.dx, closeTo(original.dx, .000001));
          expect(delta.dy, closeTo(original.dy, .000001));
          const nw = 72 * TacklePlayerVisual.attackAspectRatio;
          const nx = (.5 - TacklePlayerVisual.attackFootAnchorX) * nw;
          final pc = c(target.playerAlignment, p);
          final canvas = Rect.fromLTWH(pc.dx + nx - nw / 2, pc.dy - 36, nw, 72);
          expect(canvas.left, greaterThanOrEqualTo(0));
          expect(canvas.right, lessThanOrEqualTo(width));
          expect(canvas.top, greaterThanOrEqualTo(0));
          expect(canvas.bottom, lessThanOrEqualTo(544));
          // Success has no influence on B samples before contact; only hold later.
          for (var time = visualTap; time <= contact; time += 8) {
            final held = route.sample(math.min(time, contact));
            expect(held, route.sample(time));
          }
          expect(route.sample(math.min(contact + 80, contact)), future);
        });
      }
    }
  }
  for (final down in [false, true]) {
    test(
        'direct GO starts at measured position, merges at220 without jump down=$down',
        () {
      const start = Alignment(-.172, .012);
      final direct = TackleRunningTrajectory(
          start: start, downward: down, hasFeint: false);
      final legacy = TackleRunningTrajectory(start: start, downward: down);
      expect(direct.sample(110), start);
      expect((direct.sample(110.001).x - start.x).abs(), lessThan(.000001));
      for (final t in [220.0, 300.0, 500.0, 660.0]) {
        expect(direct.sample(t), legacy.sample(t));
      }
      const e = .01;
      final l = direct.sample(220 - e),
          m = direct.sample(220),
          r = direct.sample(220 + e);
      expect((m.x - l.x) / e, closeTo((r.x - m.x) / e, .000001));
      expect((m.y - l.y) / e, closeTo((r.y - m.y) / e, .00001));
    });
  }
}
