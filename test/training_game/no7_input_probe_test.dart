import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';
import 'tackle_test_driver.dart';

Future<void> start(WidgetTester t, {bool go = true}) async {
  await t.pumpWidget(MaterialApp(home: tackleTestScreen(approachMs: 1100)));
  await t.tap(find.text('スタート'));
  await t.pump();
  if (go) await t.pump(const Duration(milliseconds: 1100));
}

Offset lower(WidgetTester t) =>
    t.getCenter(find.byKey(const Key('tackle-tap-down')));
Future<void> dispose(WidgetTester t) => t.pumpWidget(const SizedBox());
void main() {
  for (final ms in [749, 750, 751]) {
    testWidgets('down at ${ms}ms boundary', (t) async {
      await start(t);
      await t.pump(Duration(milliseconds: ms));
      final g = await t.startGesture(lower(t));
      await t.pump();
      expect(
          find.byKey(Key(
              ms < 750 ? 'tackle-feedback-success' : 'tackle-feedback-miss')),
          findsOneWidget);
      await g.up();
      await dispose(t);
    });
  }
  testWidgets('730 down immediately succeeds before 760 up', (t) async {
    await start(t);
    await t.pump(const Duration(milliseconds: 730));
    final g = await t.startGesture(lower(t));
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 30));
    await g.up();
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
    await dispose(t);
  });
  testWidgets('pre GO down is immediately MISS and cannot become success', (
    t,
  ) async {
    await start(t, go: false);
    await t.pump(const Duration(milliseconds: 1090));
    final g = await t.startGesture(lower(t));
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 20));
    await g.up();
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-success')), findsNothing);
    expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
    await dispose(t);
  });
  for (final hold in [10, 100, 600, 1200, 3000]) {
    testWidgets('hold ${hold}ms cannot advance set on old up', (t) async {
      await start(t);
      final g = await t.startGesture(lower(t));
      await t.pump();
      expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
      await t.pump(Duration(milliseconds: hold));
      await g.up();
      await t.pump();
      expect(find.text('SET 1 / 3'), findsOneWidget);
      if (hold >= 650) expect(find.text('>> タップして次へ <<'), findsOneWidget);
      await dispose(t);
    });
  }
  testWidgets('repeated taps cannot settle or advance during resolution', (
    t,
  ) async {
    await start(t);
    for (var i = 0; i < 5; i++) {
      await t.tapAt(lower(t));
      await t.pump();
    }
    expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
    expect(find.text('SET 1 / 3'), findsOneWidget);
    await dispose(t);
  });
  testWidgets('fresh result tap advances one set after long held input', (
    t,
  ) async {
    await start(t);
    final g = await t.startGesture(lower(t));
    await t.pump(const Duration(milliseconds: 1200));
    await g.up();
    await t.pump();
    expect(find.text('SET 1 / 3'), findsOneWidget);
    await t.tapAt(lower(t));
    await t.pump();
    expect(find.text('SET 2 / 3'), findsOneWidget);
    expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
    await dispose(t);
  });
  for (final cancelAfter in [20, 800, 1200]) {
    testWidgets(
      'cancel after ${cancelAfter}ms does not undo or duplicate result',
      (t) async {
        await start(t);
        final g = await t.startGesture(lower(t));
        await t.pump();
        expect(
            find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
        await t.pump(Duration(milliseconds: cancelAfter));
        await g.cancel();
        await t.pump();
        expect(find.text('SET 1 / 3'), findsOneWidget);
        expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
        await dispose(t);
      },
    );
  }
  testWidgets('drag after down retains single committed result', (t) async {
    await start(t);
    final g = await t.startGesture(lower(t));
    await g.moveBy(const Offset(40, 0));
    await t.pump(const Duration(milliseconds: 1200));
    await g.up();
    await t.pump();
    expect(find.text('SET 1 / 3'), findsOneWidget);
    expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
    await dispose(t);
  });
  testWidgets('two fingers cannot settle or advance twice across result', (
    t,
  ) async {
    await start(t);
    final a = await t.startGesture(lower(t), pointer: 1);
    final b = await t.startGesture(
      t.getCenter(find.byKey(const Key('tackle-tap-up'))),
      pointer: 2,
    );
    await t.pump(const Duration(milliseconds: 1200));
    await b.up();
    await t.pump();
    await a.up();
    await t.pump();
    expect(find.text('SET 1 / 3'), findsOneWidget);
    expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
    await dispose(t);
  });
  testWidgets('wrong direction immediately misses once', (t) async {
    await start(t);
    final g = await t
        .startGesture(t.getCenter(find.byKey(const Key('tackle-tap-up'))));
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1200));
    await g.up();
    await t.pump();
    expect(find.text('SET 1 / 3'), findsOneWidget);
    await dispose(t);
  });
  testWidgets('GO panel remains outside input', (t) async {
    await start(t);
    await t.tap(find.byKey(const Key('tackle-input-cue')));
    await t.pump();
    expect(find.byKey(const Key('tackle-input-cue')), findsOneWidget);
    await dispose(t);
  });
  for (final key in ['tackle-opponent', 'tackle-player']) {
    testWidgets('$key passes pointer down', (t) async {
      await start(t);
      await t.pump(const Duration(milliseconds: 100));
      final g = await t.startGesture(
        t.getCenter(find.byKey(Key(key))) + const Offset(0, 10),
      );
      await t.pump();
      expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
      await g.up();
      await dispose(t);
    });
  }
  testWidgets('paused field pointer never commits after resume', (t) async {
    await start(t);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final g = await t.startGesture(lower(t));
    await t.pump();
    await t.tap(find.text('再開'));
    await t.pump();
    await g.up();
    await t.pump();
    expect(find.byKey(const Key('tackle-feedback-success')), findsNothing);
    expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
    await dispose(t);
  });
  testWidgets(
    'second finger during result cannot advance while input finger held',
    (t) async {
      await start(t);
      final a = await t.startGesture(lower(t), pointer: 1);
      await t.pump(const Duration(milliseconds: 1200));
      final b = await t.startGesture(lower(t), pointer: 2);
      await b.up();
      await t.pump();
      expect(find.text('SET 1 / 3'), findsOneWidget);
      await a.up();
      await t.pump();
      expect(find.text('SET 1 / 3'), findsOneWidget);
      await t.tapAt(lower(t));
      await t.pump();
      expect(find.text('SET 2 / 3'), findsOneWidget);
      await dispose(t);
    },
  );
  testWidgets('cancelled input still allows a fresh result tap', (t) async {
    await start(t);
    final g = await t.startGesture(lower(t));
    await t.pump(const Duration(milliseconds: 1200));
    await g.cancel();
    await t.pump();
    await t.tapAt(lower(t));
    await t.pump();
    expect(find.text('SET 2 / 3'), findsOneWidget);
    await dispose(t);
  });
  for (final target in ['outside', 'header', 'resultPanel']) {
    for (final releaseInputFirst in [false, true]) {
      testWidgets(
        '$target blocked while held; input up first=$releaseInputFirst',
        (t) async {
          await start(t);
          final input = await t.startGesture(lower(t), pointer: 1);
          await t.pump(const Duration(milliseconds: 1200));
          Offset point() => switch (target) {
                'header' => t.getCenter(find.text('SET 1 / 3')),
                'resultPanel' => t.getCenter(find.text('>> タップして次へ <<')),
                _ => const Offset(4, 300),
              };
          final second = await t.startGesture(point(), pointer: 2);
          if (releaseInputFirst) await input.up();
          await second.up();
          await t.pump();
          expect(find.text('SET 1 / 3'), findsOneWidget);
          if (!releaseInputFirst) await input.up();
          await t.pump();
          expect(find.text('SET 1 / 3'), findsOneWidget);
          await t.tapAt(point());
          await t.pump();
          expect(find.text('SET 2 / 3'), findsOneWidget);
          expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
          await dispose(t);
        },
      );
    }
  }
  test('750ms inclusive numeric boundary unchanged', () {
    for (final us in [749999, 750000, 750001]) {
      expect(
        TackleAttempt(
          isCorrect: true,
          reaction: Duration(microseconds: us),
        ).isSuccess,
        us <= 750000,
      );
    }
  });
}
