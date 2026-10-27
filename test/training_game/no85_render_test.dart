import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_player_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  for (final down in [false, true]) {
    testWidgets('attack paint grows and calibrated contact stays $down', (
      t,
    ) async {
      Size? baseline;
      Offset? contact;
      for (final scale in [1.0, 1.15]) {
        await t.pumpWidget(
          MaterialApp(
            home: Center(
              child: TacklePlayerVisual(
                key: const Key('player'),
                attacking: true,
                downward: down,
                visualScale: scale,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final box = t.renderObject<RenderBox>(
          find.byKey(const Key('tackle-player-attack')),
        );
        final point = box.localToGlobal(
          Offset(box.size.width * 607 / 615, box.size.height * 455 / 1251),
        );
        final height =
            (box.localToGlobal(Offset(0, box.size.height)) -
                    box.localToGlobal(Offset.zero))
                .distance;
        expect(height, closeTo(72 * scale, .001));
        if (scale == 1) {
          baseline = t.getSize(find.byKey(const Key('player')));
          contact = point;
        } else {
          expect(t.getSize(find.byKey(const Key('player'))), baseline);
          expect((point - contact!).distance, lessThan(.001));
        }
      }
    });
  }
  testWidgets(
    'P&R paint grows while box and held-ball coordinates stay fixed',
    (t) async {
      Rect? ball;
      Size? size;
      for (final scale in [1.0, 1.15]) {
        await t.pumpWidget(
          MaterialApp(
            home: Center(
              child: PassAndRunCharacterVisual(
                key: const Key('player'),
                character: PassRunCharacter.normal,
                holding: true,
                frame: 0,
                facing: PassRunFacing.front,
                size: 84,
                visualScale: scale,
                ballKey: const Key('ball'),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final image = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.contains("_free_"),
        );
        final b = t.renderObject<RenderBox>(image);
        expect(
          (b.localToGlobal(Offset(0, 84)) - b.localToGlobal(Offset.zero))
              .distance,
          closeTo(84 * scale, .001),
        );
        if (scale == 1) {
          ball = t.getRect(find.byKey(const Key('ball')));
          size = t.getSize(find.byKey(const Key('player')));
        } else {
          expect(t.getRect(find.byKey(const Key('ball'))), ball);
          expect(t.getSize(find.byKey(const Key('player'))), size);
        }
      }
    },
  );
}
