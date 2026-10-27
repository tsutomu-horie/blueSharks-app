import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_thumbnail.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'recording_training_game_sound.dart';

void main() {
  var serverTime = DateTime.utc(2026, 10, 8);
  setUp(() {
    serverTime = DateTime.utc(2026, 10, 8);
    ServerTimeClock.instance.synchronize(serverTime);
  });

  Future<void> advance(WidgetTester tester, Duration elapsed) async {
    // The game uses a synchronized server clock, not the test wall clock.
    // Advance that clock together with Flutter's fake frame/timer clock.
    serverTime = serverTime.add(elapsed);
    ServerTimeClock.instance.synchronize(serverTime);
    await tester.pump(elapsed);
  }

  Future<void> readyPass(WidgetTester tester) async {
    if (find.byType(PassAndRunGameScreen).evaluate().isEmpty) return;
    final context = tester.element(find.byType(PassAndRunGameScreen));
    await tester.runAsync(() async {
      for (final path in PassAndRunCharacterVisual.assets) {
        await precacheImage(AssetImage(path), context);
      }
    });
    await tester.pump();
  }

  testWidgets('ミニゲーム選択用サムネイルを2種類表示できる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            MiniGameSelectionThumbnail(
              type: MiniGameSelectionThumbnailType.tackle,
            ),
            MiniGameSelectionThumbnail(
              type: MiniGameSelectionThumbnailType.passAndRun,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MiniGameSelectionThumbnail), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(MiniGameSelectionThumbnail),
        matching: find.byType(CustomPaint),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('タックルの上下入力領域を同じ高さで表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );

    final upperDetector = find.byKey(const Key('tackle-tap-up'));
    final lowerDetector = find.byKey(const Key('tackle-tap-down'));

    expect(tester.getSize(upperDetector.first).height,
        tester.getSize(lowerDetector.first).height);
  });

  testWidgets('タックルは成否に応じた決着演出を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await advance(tester, const Duration(milliseconds: 1400));
    await tester.tap(find.byKey(const Key('tackle-tap-up')));
    await tester.pump();

    final settled = find
            .byKey(const Key('tackle-feedback-success'))
            .evaluate()
            .isNotEmpty ||
        find.byKey(const Key('tackle-feedback-miss')).evaluate().isNotEmpty;
    expect(settled, isTrue);
  });

  testWidgets('タックルは判定開始前のタップをお手つきMISSにする', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tackle-tap-up')));
    await tester.pump();

    expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
  });

  testWidgets('タックルは成否に関係なくタップ方向へ鮫太朗を移動する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final beforeTap =
        tester.getCenter(find.byKey(const Key('tackle-player'))).dy;
    await tester.tap(find.byKey(const Key('tackle-tap-up')));
    await tester.pump();
    await advance(tester, const Duration(milliseconds: 160));

    expect(tester.getCenter(find.byKey(const Key('tackle-player'))).dy,
        lessThan(beforeTap));
  });

  testWidgets('タックルの判定表示は画面上部のタップでも次セットへ進む', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tackle-tap-up')));
    await advance(tester, const Duration(milliseconds: 650));

    await tester.tap(find.text('SET 1 / 3'));
    await tester.pump();

    expect(find.text('SET 2 / 3'), findsOneWidget);
  });

  testWidgets('パス＆ランでは両キャラクターが連続して上下移動する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => serverTime)),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final playerStart =
        tester.getCenter(find.byKey(const Key('pass-player'))).dy;
    final mateStart = tester.getCenter(find.byKey(const Key('pass-mate'))).dy;
    await advance(tester, const Duration(milliseconds: 500));
    final playerAfter =
        tester.getCenter(find.byKey(const Key('pass-player'))).dy;
    final mateAfter = tester.getCenter(find.byKey(const Key('pass-mate'))).dy;

    expect(playerAfter, isNot(playerStart));
    expect(mateAfter, isNot(mateStart));
  });

  testWidgets('パス＆ランでボールと成功パスの軌跡を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          home: PassAndRunGameScreen(motionSeed: 54, now: () => serverTime)),
    );

    expect(find.byKey(const Key('pass-ball')), findsOneWidget);
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    // 独立移動では開始時の相手が前方の場合がある。元の相手狙い入力を
    // 保持し、表示テストの前提となる実際の後方位置を待つ。
    for (var i = 0; i < 140; i++) {
      final p = tester.getCenter(find.byKey(const Key('pass-player')));
      final m = tester.getCenter(find.byKey(const Key('pass-mate')));
      if (m.dy > p.dy + 20) break;
      await advance(tester, const Duration(milliseconds: 100));
    }
    final player = tester.getCenter(find.byKey(const Key('pass-player')));
    final mate = tester.getCenter(find.byKey(const Key('pass-mate')));
    expect(mate.dy, greaterThan(player.dy + 20));
    await tester.flingFrom(player, mate - player, 1200);
    await advance(tester, const Duration(milliseconds: 20));

    expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget);
  });

  testWidgets('パス＆ランはドラッグ中にフリック始点と方向を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => serverTime)),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('pass-player'))),
    );
    await gesture.moveBy(const Offset(80, 20));
    await tester.pump();

    expect(find.byKey(const Key('pass-flick-guide')), findsOneWidget);
    await gesture.up();
  });

  testWidgets('パス＆ランは仲間に当たらない場合もボールを発射する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => serverTime)),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final player = tester.getCenter(find.byKey(const Key('pass-player')));
    // 仲間と反対へ十分な速度でフリックし、衝突しないパスを発生させます。
    await tester.flingFrom(player, const Offset(-100, 0), 1200);
    await advance(tester, const Duration(milliseconds: 20));

    expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget);
    // 成否は発射時の方向ではなく、ボールが仲間に当たるかで判定されます。
    expect(find.text('ボール移動中…'), findsOneWidget);
    await advance(tester, const Duration(milliseconds: 400));
    expect(find.text('MISS　1秒間パス不可'), findsOneWidget);
    // 失敗パスは画面外へ抜けた後、ペナルティ終了時にプレイヤーへ戻ります。
    await advance(tester, const Duration(milliseconds: 2100));
    expect(find.byKey(const Key('pass-ball')), findsOneWidget);
  });

  testWidgets('非保持姿と位置は一時停止中に保持され、再開できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => serverTime)),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    final player = find.byKey(const Key('pass-player'));
    await tester.flingFrom(
        tester.getCenter(player), const Offset(-100, 0), 1200);
    await advance(tester, const Duration(milliseconds: 20));
    expect(tester.widget<PassAndRunCharacterVisual>(player).holding, isFalse);
    await tester.tap(find.byTooltip('一時停止'));
    await tester.pump();
    final pausedPosition = tester.getCenter(player);
    await advance(tester, const Duration(milliseconds: 500));
    expect(tester.getCenter(player), pausedPosition);
    expect(tester.widget<PassAndRunCharacterVisual>(player).holding, isFalse);
    await tester.tap(find.text('再開'));
    await tester.pump();
    expect(find.text('一時停止中'), findsNothing);
    expect(tester.widget<PassAndRunCharacterVisual>(player).holding, isFalse);
  });

  testWidgets('復路と結果は承認済み正面姿で表示し交換1秒を確保する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => serverTime)),
    );
    await readyPass(tester);
    await tester.tap(find.text('スタート'));
    await tester.pump();
    // Cross the deadline rather than landing within the real Stopwatch's
    // sub-millisecond offset from the synchronized test clock.
    await advance(tester, const Duration(milliseconds: 15100));
    expect(find.text('復路'), findsOneWidget);
    await advance(tester, const Duration(milliseconds: 1000));
    final player = find.byKey(const Key('pass-player'));
    expect(
      tester.widget<PassAndRunCharacterVisual>(player).facing,
      PassRunFacing.front,
    );
    await advance(tester, const Duration(milliseconds: 15100));
    expect(find.text('メインへ戻る'), findsOneWidget);
    expect(
      tester.widget<PassAndRunCharacterVisual>(player).facing,
      PassRunFacing.front,
    );
  });

  testWidgets('No.40タックル結果フックはsceneswitch1を再生する', (tester) async {
    final sounds = RecordingTrainingGameSound();
    addTearDown(sounds.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: TackleGameScreen(
          random: Random(5),
          settings: const TackleSettings(setCount: 1),
          soundService: sounds.service,
        ),
      ),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await advance(tester, const Duration(milliseconds: 1400));
    await tester.tap(find.byKey(const Key('tackle-tap-up')));
    await tester.pump();
    await advance(tester, const Duration(milliseconds: 650));

    expect(find.text('SET 1 / 1'), findsOneWidget);
    expect(sounds.playedAssetPaths, isEmpty);
    await tester.tap(find.text('SET 1 / 1'));
    await tester.pump();

    expect(find.text('総合ランク'), findsOneWidget);
    expect(sounds.createdAssetPaths, [
      'assets/audio/training_game/sceneswitch1.mp3',
    ]);
    expect(sounds.playedAssetPaths, [
      'assets/audio/training_game/sceneswitch1.mp3',
    ]);
  });
}
