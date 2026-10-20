import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_opponent_visual.dart';

void main() {
  for (final alignment in [
    const Alignment(1.25, 0),
    const Alignment(.45, 0),
    const Alignment(-.18, -.48),
    const Alignment(-.36, .58),
    const Alignment(-1.35, -.58),
  ]) {
    testWidgets('opponent preserves legacy box and center at $alignment', (
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
      expect(tester.getSize(find.byKey(const Key('opponent'))), expectedSize);
      expect(
        tester.getCenter(find.byKey(const Key('opponent'))),
        expectedCenter,
      );
      final image = find.descendant(
        of: find.byKey(const Key('opponent')),
        matching: find.byType(Image),
      );
      expect(
        tester.getSize(image).height,
        closeTo(72 * (206 / 216) * (891 / 867), .000001),
      );
      expect(
        tester.getSize(image).width,
        closeTo(72 * (206 / 216) * (562 / 867), .000001),
      );
      expect(tester.getRect(image).right,
          closeTo(expectedCenter.dx + (58 * 562 / 891) / 2, .000001));
      expect(
        tester.getCenter(image).dy,
        closeTo(expectedCenter.dy - 1 / 3, .000001),
      );
      expect(
        (tester.widget<Image>(image).image as AssetImage).assetName,
        TackleOpponentVisual.assetPath,
      );
    });
  }

  testWidgets(
    'B alpha head and feet match Normal body height at same baseline',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: TackleOpponentVisual(key: Key('opponent'))),
        ),
      );
      final opponent = find.byKey(const Key('opponent'));
      final center = tester.getCenter(opponent);
      final image = find.descendant(of: opponent, matching: find.byType(Image));
      final box = tester.renderObject<RenderBox>(image);
      // Independent measured alpha128 bounds: B[12,12,550,879]/562x891;
      // Normal rest3x[8,4,107,210]/114x216 displayed at height72.
      final bTop = box.localToGlobal(Offset(0, box.size.height * 12 / 891)).dy;
      final bBottom =
          box.localToGlobal(Offset(0, box.size.height * 879 / 891)).dy;
      final normalTop = center.dy - 36 + 72 * 4 / 216;
      final normalBottom = center.dy - 36 + 72 * 210 / 216;
      expect(bTop, closeTo(normalTop, .000001));
      expect(bBottom, closeTo(normalBottom, .000001));
      expect(bBottom - bTop, closeTo(72 * 206 / 216, .000001));
    },
  );

  for (final fieldWidth in [288.0, 328.0, 343.0, 370.0]) {
    testWidgets('enlarged exit does not regress at field width $fieldWidth',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: SizedBox(
        key: const Key('field'),
        width: fieldWidth,
        height: 400,
        child: const Align(
            alignment: Alignment(-1.35, -.58),
            child: TackleOpponentVisual(key: Key('opponent'))),
      ))));
      final field = tester.getRect(find.byKey(const Key('field')));
      final opponent = find.byKey(const Key('opponent'));
      final image = find.descendant(of: opponent, matching: find.byType(Image));
      final box = tester.renderObject<RenderBox>(image);
      final alphaRight =
          box.localToGlobal(Offset(box.size.width * 550 / 562, 0)).dx;
      // Independent source alpha edge and the previous58px image at this center.
      final oldAlphaRight =
          tester.getCenter(opponent).dx + 58 * (550 - 281) / 891;
      expect(alphaRight, lessThanOrEqualTo(oldAlphaRight + .000001));
      if (fieldWidth >= 328) expect(alphaRight, lessThanOrEqualTo(field.left));
      debugPrint(
          'OPPONENT_SIZE_EXIT field=$fieldWidth old=${oldAlphaRight - field.left} new=${alphaRight - field.left}');
    });
  }

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
  });
}
