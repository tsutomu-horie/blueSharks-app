import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';

void main() {
  testWidgets('タックルの上下入力領域を同じ高さで表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );

    final upperDetector = find.ancestor(
      of: find.text('上をタップ ▲'),
      matching: find.byType(GestureDetector),
    );
    final lowerDetector = find.ancestor(
      of: find.text('下をタップ ▼'),
      matching: find.byType(GestureDetector),
    );

    expect(tester.getSize(upperDetector.first).height,
        tester.getSize(lowerDetector.first).height);
  });

  testWidgets('パス＆ランでは両キャラクターが連続して上下移動する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final playerStart = tester.getCenter(find.text('🦈')).dy;
    final mateStart = tester.getCenter(find.text('🏃')).dy;
    await tester.pump(const Duration(milliseconds: 500));
    final playerAfter = tester.getCenter(find.text('🦈')).dy;
    final mateAfter = tester.getCenter(find.text('🏃')).dy;

    expect(playerAfter, isNot(playerStart));
    expect(mateAfter, isNot(mateStart));
  });

  testWidgets('パス＆ランでボールと成功パスの軌跡を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );

    expect(find.byKey(const Key('pass-ball')), findsOneWidget);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    final player = tester.getCenter(find.text('🦈'));
    final mate = tester.getCenter(find.text('🏃'));
    await tester.flingFrom(player, mate - player, 1200);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget);
  });

  testWidgets('パス＆ランはドラッグ中にフリック始点と方向を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('🦈')),
    );
    await gesture.moveBy(const Offset(80, 20));
    await tester.pump();

    expect(find.byKey(const Key('pass-flick-guide')), findsOneWidget);
    await gesture.up();
  });

  testWidgets('パス＆ランは方向ミスでもボールを発射する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final player = tester.getCenter(find.text('🦈'));
    // 仲間と反対へ十分な速度でフリックし、方向ミスを発生させます。
    await tester.flingFrom(player, const Offset(-100, 0), 1200);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget);
    expect(find.text('MISS　2秒間パス不可'), findsOneWidget);
    // 失敗パスは返球されず、画面外へ抜けた後はペナルティ中に表示しません。
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('pass-ball')), findsNothing);
  });
}
