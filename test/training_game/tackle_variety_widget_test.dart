import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'tackle_test_driver.dart';

void main() {
  final cue = find.byKey(const Key('tackle-input-cue'));
  final feint = find.byKey(const Key('tackle-running-feint'));
  for (final hasFeint in [false, true]) {
    for (final delay in [1100, 1600]) {
      testWidgets(
          'real screen wait=$delay pattern=$hasFeint; GO starts full window',
          (tester) async {
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        await tester.pumpWidget(MaterialApp(
            home: tackleTestScreen(hasFeint: hasFeint, approachMs: delay)));
        await tester.tap(find.text('スタート'));
        await tester.pump();
        await tester.pump(Duration(milliseconds: delay - 1));
        expect(cue, findsNothing);
        expect(feint, findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        if (hasFeint) {
          expect(feint, findsOneWidget);
          expect(cue, findsNothing);
          await tester.pump(const Duration(milliseconds: 164));
          expect(cue, findsNothing);
          await tester.pump(const Duration(milliseconds: 1));
        }
        expect(cue, findsOneWidget);
        expect(find.textContaining('反対をタップ'), findsNothing);
        await tester.pump(const Duration(milliseconds: 749));
        expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
      });
    }
  }

  testWidgets('real Stopwatch excludes all wall time spent before GO',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester
        .pumpWidget(MaterialApp(home: tackleTestScreen(hasFeint: true)));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
    expect(feint, findsOneWidget);
    expect(cue, findsNothing);
    // Stopwatch uses real time, whereas widget timers use fake time. Waiting
    // longer than750ms here detects any stopwatch incorrectly started in feint.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pump(const Duration(milliseconds: 165));
    expect(cue, findsOneWidget);
    await tester.tap(find.byKey(const Key('tackle-tap-down')));
    await tester.pump();
    expect(find.byKey(const Key('tackle-feedback-success')), findsOneWidget);
  });

  for (final duringFeint in [false, true]) {
    testWidgets(
        'pause ${duringFeint ? 'feint' : 'input'} cancels timers and restarts same set',
        (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester
          .pumpWidget(MaterialApp(home: tackleTestScreen(hasFeint: true)));
      await tester.tap(find.text('スタート'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(Duration(milliseconds: duringFeint ? 80 : 245));
      await tester.tap(find.byTooltip('一時停止'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
      expect(find.text('SET 1 / 3'), findsOneWidget);
      await tester.tap(find.text('再開'));
      await tester.pump();
      expect(cue, findsNothing);
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(const Duration(milliseconds: 165));
      expect(cue, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 749));
      expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 650));
      await tester.tap(find.text('SET 1 / 3'));
      await tester.pump();
      expect(find.text('SET 2 / 3'), findsOneWidget);
    });
  }
}
