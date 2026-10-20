import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_contact_geometry.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_player_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_opponent_visual.dart';

void main() {
  for (final size in [
    const Size(343, 544),
    const Size(370, 544),
    const Size(780, 141),
  ]) {
    for (final down in [false, true]) {
      test('contact candidate $size down=$down', () {
        const p = Size(72.25, 103), b = Size(58.25, 83);
        final t = tackleContactTargets(
          field: size,
          player: p,
          opponent: b,
          downward: down,
        )!;
        Offset center(Alignment a, Size s) => Offset(
              size.width / 2 + a.x * (size.width - s.width) / 2,
              size.height / 2 + a.y * (size.height - s.height) / 2,
            );
        final pc = center(t.playerAlignment, p);
        final base = center(Alignment(-.82, down ? .36 : -.36), p);
        expect(pc.dx, closeTo(base.dx, .000001));
        // Independent source measurement: visible arm-root Y355, gap3 logical.
        const expectedLift = (72 * (206 / 216) / 867) * (650 - 355) - 3;
        expect(tackleDownShoulderSourceY, 355);
        expect(tackleDownShoulderGap, 3);
        expect(tackleDownPlayerLift, closeTo(expectedLift, .000001));
        expect(pc.dy, closeTo(base.dy - (down ? expectedLift : 0), .000001));
        const ns = 72 / 1251, nw = 72 * TacklePlayerVisual.attackAspectRatio;
        const nx = (.5 - TacklePlayerVisual.attackFootAnchorX) * nw;
        final originalArm = base +
            Offset(
              nx - nw / 2 + 607 * ns,
              -36 + (down ? 1251 - 455 : 455) * ns,
            );
        const bs = TackleOpponentVisual.imageHeight / 891;
        final bc = center(t.opponentAlignment, b);
        final waist = bc +
            const Offset(
              TackleOpponentVisual.imageOffsetX -
                  TackleOpponentVisual.imageWidth / 2 +
                  178 * bs,
              TackleOpponentVisual.imageOffsetY -
                  TackleOpponentVisual.imageHeight / 2 +
                  650 * bs,
            );
        expect(waist.dx, closeTo(originalArm.dx, .000001));
        expect(waist.dy, closeTo(originalArm.dy, .000001));
        if (down) {
          final shoulderY = waist.dy - (650 - 355) * bs;
          final shiftedArmY = originalArm.dy + pc.dy - base.dy;
          expect(shiftedArmY - shoulderY, closeTo(3, .000001));
        } else {
          expect(t.playerAlignment.x, closeTo(-.82, .000001));
          expect(t.playerAlignment.y, closeTo(-.36, .000001));
        }
      });
    }
  }
  test(
    'tiny field safe fallback',
    () => expect(
      tackleContactTargets(
        field: const Size(50, 50),
        player: const Size(72, 103),
        opponent: const Size(58, 83),
        downward: false,
      ),
      isNull,
    ),
  );
}
