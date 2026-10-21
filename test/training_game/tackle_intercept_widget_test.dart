import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_running_trajectory.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_contact_geometry.dart';
import 'tackle_test_driver.dart';

void main() {
  final b = find.byKey(const Key('tackle-opponent'));
  final p = find.byKey(const Key('tackle-player'));
  final cue = find.byKey(const Key('tackle-input-cue'));
  void same(Offset a, Offset c) {
    expect(a.dx, closeTo(c.dx, .001));
    expect(a.dy, closeTo(c.dy, .001));
  }

  for (final feint in [false, true]) {
    for (final down in [false, true]) {
      for (final tapMs in [0, 200, 690, 749]) {
        testWidgets('shared-clock feint=$feint down=$down tap$tapMs',
            (tester) async {
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          await tester.pumpWidget(MaterialApp(
              home: tackleTestScreen(hasFeint: feint, downward: down)));
          await tester.tap(find.text('スタート'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1350));
          final field = tester
              .getRect(find.ancestor(of: b, matching: find.byType(ClipRRect)));
          final bs = tester.getSize(b), ps = tester.getSize(p);
          final start = tester.getCenter(b) - field.topLeft;
          final startAlignment = Alignment(
              (2 * start.dx - field.width) / (field.width - bs.width),
              (2 * start.dy - field.height) / (field.height - bs.height));
          if (feint) {
            expect(cue, findsNothing);
            await tester.pump(const Duration(milliseconds: 165));
          }
          expect(cue, findsOneWidget);
          expect(
              find.byKey(
                  Key(down ? 'tackle-running-down' : 'tackle-running-up')),
              findsOneWidget);
          final route = TackleRunningTrajectory(
              start: startAlignment, downward: down, hasFeint: feint);
          Offset center(Alignment a, Size size) =>
              field.topLeft +
              Offset(field.width / 2 + a.x * (field.width - size.width) / 2,
                  field.height / 2 + a.y * (field.height - size.height) / 2);
          same(tester.getCenter(b), center(route.sample(110), bs));
          await tester.pump(Duration(milliseconds: tapMs));
          final beforeB = tester.getCenter(b), beforeP = tester.getCenter(p);
          await tester.tap(find.text(down ? '下をタップ ▼' : '上をタップ ▲'));
          await tester.pump();
          expect(find.text('TACKLE!'), findsOneWidget);
          same(tester.getCenter(b), beforeB);
          same(tester.getCenter(p), beforeP);
          final contact = TackleRunningTrajectory.contactTime(
              TackleRunningTrajectory.visualMilliseconds(tapMs.toDouble()));
          final reference = tackleContactTargets(
              field: field.size, player: ps, opponent: bs, downward: down)!;
          final targets = tackleInterceptTargets(
              field: field.size,
              player: ps,
              opponent: bs,
              reference: reference,
              future: route.sample(contact));
          for (var elapsed = 16; elapsed <= 304; elapsed += 16) {
            await tester.pump(const Duration(milliseconds: 16));
            same(
                tester.getCenter(b),
                center(
                    route.sample(TackleRunningTrajectory.visualMilliseconds(
                        tapMs + elapsed.toDouble())),
                    bs));
            expect(
                (tester.getCenter(b) - center(targets.opponentAlignment, bs))
                    .distance,
                greaterThan(.00001));
          }
          await tester.pump(const Duration(microseconds: 3693));
          same(tester.getCenter(b), center(targets.opponentAlignment, bs));
          same(tester.getCenter(p), center(targets.playerAlignment, ps));
          final heldB = tester.getCenter(b), heldP = tester.getCenter(p);
          await tester.pump(const Duration(microseconds: 342307));
          same(tester.getCenter(b), heldB);
          same(tester.getCenter(p), heldP);
          expect(find.text('>> タップして次へ <<'), findsOneWidget);
        });
      }
    }
  }

  for (final feint in [false, true]) {
    testWidgets('full750ms after GO feint=$feint; raw exit520 and gate650',
        (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester
          .pumpWidget(MaterialApp(home: tackleTestScreen(hasFeint: feint)));
      await tester.tap(find.text('スタート'));
      await tester.pump();
      final resting = tester.getCenter(p);
      await tester.pump(const Duration(milliseconds: 1350));
      if (feint) {
        await tester.pump(const Duration(milliseconds: 164));
        expect(cue, findsNothing);
        expect(find.text('突破された！'), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(cue, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 749));
      expect(find.text('突破された！'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('突破された！'), findsOneWidget);
      same(tester.getCenter(p), resting);
      final before = tester.getCenter(b);
      await tester.pump(const Duration(milliseconds: 520));
      expect(tester.getCenter(b).dx, lessThan(before.dx));
      final parent = tester.widget<AnimatedAlign>(
          find.ancestor(of: b, matching: find.byType(AnimatedAlign)));
      expect(
          parent.alignment.resolve(TextDirection.ltr).x, closeTo(-1.35, .001));
      await tester.pump(const Duration(milliseconds: 129));
      expect(find.text('>> タップして次へ <<'), findsNothing);
      await tester.tap(find.text('SET 1 / 3'));
      await tester.pump();
      expect(find.text('SET 1 / 3'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('>> タップして次へ <<'), findsOneWidget);
      expect(find.textContaining('MISS'), findsOneWidget);
      expect(find.text('MISS　時間切れ'), findsOneWidget);
      expect(find.textContaining('早すぎた'), findsNothing);
    });
  }

  testWidgets('pre-GO feint tap is MISS and exits for520ms', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester
        .pumpWidget(MaterialApp(home: tackleTestScreen(hasFeint: true)));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
    await tester.pump(const Duration(milliseconds: 80));
    expect(cue, findsNothing);
    await tester.tap(find.text('上をタップ ▲'));
    await tester.pump();
    expect(find.text('突破された！'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 520));
    final parent = tester.widget<AnimatedAlign>(
        find.ancestor(of: b, matching: find.byType(AnimatedAlign)));
    expect(parent.alignment.resolve(TextDirection.ltr),
        const Alignment(-1.35, .58));
    await tester.pump(const Duration(milliseconds: 130));
    expect(find.text('MISS　早すぎた'), findsOneWidget);
    expect(find.textContaining('時間切れ'), findsNothing);
  });

  for (final down in [false, true]) {
    testWidgets('approach early tap and next-set timeout down=$down',
        (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(MaterialApp(home: tackleTestScreen()));
      await tester.tap(find.text('スタート'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(down ? '下をタップ ▼' : '上をタップ ▲'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('MISS　早すぎた'), findsOneWidget);
      expect(find.textContaining('時間切れ'), findsNothing);
      await tester.tap(find.text('>> タップして次へ <<'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('MISS　時間切れ'), findsOneWidget);
      expect(find.textContaining('早すぎた'), findsNothing);
    });
  }

  testWidgets('wrong GO direction exits without success freeze',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester
        .pumpWidget(MaterialApp(home: tackleTestScreen(downward: true)));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('上をタップ ▲'));
    await tester.pump();
    expect(find.text('突破された！'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 520));
    final parent = tester.widget<AnimatedAlign>(
        find.ancestor(of: b, matching: find.byType(AnimatedAlign)));
    expect(parent.alignment.resolve(TextDirection.ltr).x, closeTo(-1.35, .001));
  });

  testWidgets('resolution ignores rapid repeated inputs', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(MaterialApp(home: tackleTestScreen()));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1350));
    await tester.tap(find.text('下をタップ ▼'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('上をタップ ▲'));
      await tester.tap(find.text('下をタップ ▼'));
      await tester.pump();
    }
    expect(find.text('TACKLE!'), findsOneWidget);
    expect(find.text('SET 1 / 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 649));
    expect(find.text('>> タップして次へ <<'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('>> タップして次へ <<'), findsOneWidget);
    await tester.tap(find.text('SET 1 / 3'));
    await tester.pump();
    expect(find.text('SET 2 / 3'), findsOneWidget);
  });
}
