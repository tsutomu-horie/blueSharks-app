import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_character_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_player_visual.dart';

void main() {
  final player = find.byKey(const Key('tackle-player'));
  final attack = find.byKey(const Key('tackle-player-attack'));

  Rect paintedBounds(WidgetTester tester) {
    final box = tester.renderObject<RenderBox>(attack);
    final points = [
      Offset.zero,
      Offset(box.size.width, 0),
      Offset(0, box.size.height),
      Offset(box.size.width, box.size.height)
    ].map(box.localToGlobal).toList();
    return Rect.fromLTRB(
        points.map((p) => p.dx).reduce(math.min),
        points.map((p) => p.dy).reduce(math.min),
        points.map((p) => p.dx).reduce(math.max),
        points.map((p) => p.dy).reduce(math.max));
  }

  Future<void> start(WidgetTester tester) async {
    // Dispose even after a failed assertion, cancelling each screen's timers.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(const MaterialApp(home: TackleGameScreen()));
    expect(attack, findsNothing);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    expect(attack, findsNothing);
  }

  for (final up in [true, false]) {
    for (final early in [true, false]) {
      testWidgets(
        '${up ? 'up' : 'down'} ${early ? 'early MISS' : 'input'} switches pose and preserves box',
        (tester) async {
          await start(tester);
          final size = tester.getSize(player);
          final before = tester.getCenter(player);
          if (!early) {
            await tester.pump(const Duration(milliseconds: 1350));
          }
          await tester.tap(find.text(up ? '上をタップ ▲' : '下をタップ ▼'));
          await tester.pump();
          expect(attack, findsOneWidget);
          expect(tester.widget<TacklePlayerVisual>(player).attacking, isTrue);
          expect(tester.widget<TacklePlayerVisual>(player).downward, !up);
          final rotation = tester
              .widget<Transform>(find
                  .ancestor(of: attack, matching: find.byType(Transform))
                  .first)
              .transform;
          // The reference preserves left/right and reverses only the Y axis.
          expect(rotation.entry(0, 0), 1);
          expect(rotation.entry(1, 0), 0);
          expect(rotation.entry(0, 1), 0);
          expect(rotation.entry(1, 1), up ? 1 : -1);
          expect(tester.getSize(attack).height, 72);
          expect(
              tester.getSize(attack).width, closeTo(72 * 615 / 1251, .000001));
          if (early) expect(find.text('突破された！'), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 160));
          expect(tester.getSize(player), size);
          debugPrint('TACKLE_METRIC direction=${up ? "up" : "down"} '
              'early=$early legacyBox=$size before=$before '
              'after=${tester.getCenter(player)}');
          expect(tester.getCenter(player).dx, before.dx);
          expect(
            tester.getCenter(player).dy,
            up ? lessThan(before.dy) : greaterThan(before.dy),
          );
          final image = tester.widget<Image>(attack);
          expect(
            (image.image as AssetImage).assetName,
            TacklePlayerVisual.attackAssetPath,
          );
          await tester.pump(const Duration(milliseconds: 490));
          expect(attack, findsOneWidget);
          await tester.tap(find.text('SET 1 / 3'));
          await tester.pump();
          expect(find.text('SET 2 / 3'), findsOneWidget);
          expect(attack, findsNothing);
          expect(tester.getSize(player), size);
          expect(tester.getCenter(player), before);
          // SET 2 has started approach timers; dispose before this test ends.
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final correct in [true, false]) {
    testWidgets('input ${correct ? 'success' : 'failure'} retains attack pose',
        (
      tester,
    ) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(const Duration(milliseconds: 110));
      // Read the opponent's actual target after the feint, independent of RNG.
      final opponent = tester.widget<AnimatedAlign>(
        find.ancestor(
          of: find.text('🏃'),
          matching: find.byType(AnimatedAlign),
        ),
      );
      final actualUp = opponent.alignment.resolve(TextDirection.ltr).y < 0;
      final tapUp = correct ? actualUp : !actualUp;
      await tester.tap(find.text(tapUp ? '上をタップ ▲' : '下をタップ ▼'));
      await tester.pump();
      expect(find.text(correct ? 'TACKLE!' : '突破された！'), findsOneWidget);
      expect(attack, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 650));
      expect(attack, findsOneWidget);
      expect(tester.widget<TacklePlayerVisual>(player).attacking, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('attack image keeps native ratio, height and foot anchor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: TacklePlayerVisual(key: Key('visual'), attacking: true),
        ),
      ),
    );
    // Independent approved extraction metadata, not self-referential constants.
    expect(TacklePlayerVisual.attackAspectRatio, 615 / 1251);
    expect(TacklePlayerVisual.attackFootAnchorX, 0.6231101832797189);
    await tester.runAsync(() async {
      final data = await rootBundle.load(TacklePlayerVisual.attackAssetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ));
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 615);
      expect(frame.image.height, 1251);
      frame.image.dispose();
      codec.dispose();
    });
    final imageRect = tester.getRect(attack);
    final visualRect = tester.getRect(find.byKey(const Key('visual')));
    debugPrint('TACKLE_METRIC image=$imageRect legacyBox=$visualRect '
        'native=615x1251 anchor=0.6231101832797189');
    expect(imageRect.height, 72);
    expect(
      imageRect.width / imageRect.height,
      closeTo(615 / 1251, .000001),
    );
    // The native foot anchor shares the legacy player's horizontal center.
    expect(
      imageRect.left + imageRect.width * 0.6231101832797189,
      closeTo(visualRect.center.dx, .000001),
    );
    expect(imageRect.center.dy, closeTo(visualRect.center.dy, .000001));
    final transform = tester
        .widget<Transform>(
          find.ancestor(of: attack, matching: find.byType(Transform)).first,
        )
        .transform;
    // Keep the cleared pose's orientation: translation only, no rotation/mirror.
    expect(transform.entry(0, 0), 1);
    expect(transform.entry(1, 1), 1);
    expect(transform.entry(0, 1), 0);
    expect(transform.entry(1, 0), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final up in [true, false]) {
    testWidgets(
      '${up ? 'up' : 'down'} attack paints inside clipped field and passes result tap through',
      (tester) async {
        await start(tester);
        await tester.tap(find.text(up ? '上をタップ ▲' : '下をタップ ▼'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        final field =
            find.ancestor(of: player, matching: find.byType(ClipRRect));
        expect(field, findsOneWidget);
        expect(tester.widget<ClipRRect>(field).clipBehavior, isNot(Clip.none));
        final fieldRect = tester.getRect(field);
        final imageRect = paintedBounds(tester);
        // Full sprite visibility is checked against the actual field geometry.
        expect(imageRect.left, greaterThanOrEqualTo(fieldRect.left));
        expect(imageRect.right, lessThanOrEqualTo(fieldRect.right));
        expect(imageRect.top, greaterThanOrEqualTo(fieldRect.top));
        expect(imageRect.bottom, lessThanOrEqualTo(fieldRect.bottom));
        await tester.tapAt(imageRect.center);
        await tester.pump();
        expect(find.text('SET 2 / 3'), findsOneWidget);
        expect(attack, findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('timeout retains rest and position', (tester) async {
    await start(tester);
    final before = tester.getCenter(player);
    await tester.pump(const Duration(milliseconds: 1350));
    await tester.pump(TackleRules.inputLimit);
    await tester.pump(const Duration(milliseconds: 650));
    expect(attack, findsNothing);
    expect(tester.getCenter(player), before);
    expect(tester.widget<TacklePlayerVisual>(player).attacking, isFalse);
  });

  testWidgets('visual preserves legacy box and does not intercept taps', (
    tester,
  ) async {
    var taps = 0;
    Future<void> show(bool attacking) => tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: TacklePlayerVisual(
                  key: const Key('visual'),
                  attacking: attacking,
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: MiniGameCharacterAsset(
            key: Key('legacy'),
            pose: MiniGameCharacterPose.rightRest,
            fontSize: 72,
          ),
        ),
      ),
    );
    final legacySize = tester.getSize(find.byKey(const Key('legacy')));
    for (final attacking in [false, true]) {
      await show(attacking);
      expect(tester.getSize(find.byKey(const Key('visual'))), legacySize);
      await tester.tapAt(tester.getCenter(find.byKey(const Key('visual'))));
      expect(taps, attacking ? 2 : 1);
    }
  });
}
