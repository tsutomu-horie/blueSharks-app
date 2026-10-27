import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_opponent_visual.dart';

import 'tackle_test_driver.dart';

void main() {
  String visibleAsset(WidgetTester tester, Finder owner) {
    final image = find.descendant(of: owner, matching: find.byType(Image));
    return (tester.widget<Image>(image).image as AssetImage).assetName;
  }

  for (final alignment in [
    const Alignment(1.25, 0),
    const Alignment(.45, 0),
    const Alignment(-.18, -.48),
    const Alignment(-.36, .58),
    const Alignment(-1.35, -.58),
  ]) {
    testWidgets('running mate preserves legacy box and center at $alignment', (
      tester,
    ) async {
      Widget host(Widget child) => MaterialApp(
            home: Center(
              child: SizedBox(
                width: 343,
                height: 400,
                child: Align(alignment: alignment, child: child),
              ),
            ),
          );
      await tester.pumpWidget(
        host(
          const Text('🏃', key: Key('legacy'), style: TextStyle(fontSize: 58)),
        ),
      );
      final expectedSize = tester.getSize(find.byKey(const Key('legacy')));
      final expectedCenter = tester.getCenter(find.byKey(const Key('legacy')));
      await tester.pumpWidget(
        host(const TackleOpponentVisual(key: Key('opponent'))),
      );
      final opponent = find.byKey(const Key('opponent'));
      expect(tester.getSize(opponent), expectedSize);
      expect(tester.getCenter(opponent), expectedCenter);
      expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathA);
      final image = find.descendant(of: opponent, matching: find.byType(Image));
      expect(
        tester.getSize(image),
        const Size(
          TackleOpponentVisual.spriteSize,
          TackleOpponentVisual.spriteSize,
        ),
      );
      final imageRect = tester.getRect(image);
      expect(
        imageRect.center.dx,
        closeTo(
          expectedCenter.dx + TackleOpponentVisual.spriteOffsetX,
          .000001,
        ),
      );
      expect(
        imageRect.center.dy,
        closeTo(
          expectedCenter.dy + TackleOpponentVisual.spriteOffsetY,
          .000001,
        ),
      );
      // The character art faces left in both approved frames; translation does
      // not mirror or rotate its approved orientation.
      final transform = tester.widget<Transform>(
        find.ancestor(of: image, matching: find.byType(Transform)).first,
      );
      expect(
        transform.transform.entry(0, 0),
        TackleOpponentVisual.spriteScaleX,
      );
      expect(transform.transform.entry(1, 1), 1);
      expect(transform.transform.entry(0, 1), 0);
      expect(transform.transform.entry(1, 0), 0);
    });
  }

  test('approved sprite scale keeps the previous visible runner height', () {
    expect(
      TackleOpponentVisual.spriteSize * 96 / 112,
      closeTo(TackleOpponentVisual.imageHeight * 867 / 891, .000001),
    );
    expect(TackleOpponentVisual.assetPathA, contains('tackle_run_b_a'));
    expect(TackleOpponentVisual.assetPathB, contains('tackle_run_b_b'));
    expect(TackleOpponentVisual.spriteScaleX, 1);
  });

  for (final fieldWidth in [288.0, 328.0, 343.0, 370.0]) {
    testWidgets(
      'running frames preserve the legacy exit edge at $fieldWidth px',
      (tester) async {
        const alignment = Alignment(-1.35, -.58);
        final field = find.byKey(const Key('field'));
        final opponent = find.byKey(const Key('opponent'));

        Widget host() => MaterialApp(
              home: Center(
                child: SizedBox(
                  key: const Key('field'),
                  width: fieldWidth,
                  height: 400,
                  child: const Align(
                    alignment: alignment,
                    child: TackleOpponentVisual(
                      key: Key('opponent'),
                      running: true,
                    ),
                  ),
                ),
              ),
            );

        Future<void> expectExitEdge(String asset, double alphaRight) async {
          expect(visibleAsset(tester, opponent), asset);
          final fieldRect = tester.getRect(field);
          final opponentCenter = tester.getCenter(opponent);
          final image = find.descendant(
            of: opponent,
            matching: find.byKey(const Key('tackle-opponent-running-frame')),
          );
          final box = tester.renderObject<RenderBox>(image);
          final right = box
              .localToGlobal(
                Offset(box.size.width * alphaRight / 112, box.size.height / 2),
              )
              .dx;
          // Independent alpha128 bounds of the ball-carrying 112px frames: A
          // right edge 86, B right edge 87. The former art used 550/562.
          final legacyRight = opponentCenter.dx + 58 * (550 - 281) / 891;
          expect(right, lessThanOrEqualTo(legacyRight + .000001));
          if (fieldWidth >= 328) {
            expect(right, lessThanOrEqualTo(fieldRect.left + .000001));
          }
        }

        await tester.pumpWidget(host());
        await expectExitEdge(TackleOpponentVisual.assetPathA, 86);
        await tester.pump(const Duration(milliseconds: 110));
        await expectExitEdge(TackleOpponentVisual.assetPathB, 87);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('running animation alternates approved frames and can pause', (
    tester,
  ) async {
    final opponent = find.byKey(const Key('opponent'));
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: TackleOpponentVisual(key: Key('opponent'), running: true),
        ),
      ),
    );
    expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathA);
    await tester.pump(const Duration(milliseconds: 110));
    expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathB);
    await tester.pump(const Duration(milliseconds: 108));
    expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathA);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: TackleOpponentVisual(key: Key('opponent'), running: false),
        ),
      ),
    );
    final pausedAsset = visibleAsset(tester, opponent);
    await tester.pump(const Duration(milliseconds: 500));
    expect(visibleAsset(tester, opponent), pausedAsset);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tackle approach animates the companion while it moves', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(MaterialApp(home: tackleTestScreen()));
    final opponent = find.byKey(const Key('tackle-opponent'));
    expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathA);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<TackleOpponentVisual>(opponent).running, isTrue);
    final before = tester.getCenter(opponent);
    await tester.pump(const Duration(milliseconds: 110));
    expect(visibleAsset(tester, opponent), TackleOpponentVisual.assetPathB);
    expect(tester.getCenter(opponent).dx, lessThan(before.dx));
  });

  testWidgets('opponent visual passes taps to parent', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const TackleOpponentVisual(key: Key('opponent')),
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byKey(const Key('opponent'))));
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
