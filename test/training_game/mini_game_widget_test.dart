import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_character_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/mini_game_selection_thumbnail.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';

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

  testWidgets('タックルは成否に応じた決着演出を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await advance(tester, const Duration(milliseconds: 1400));
    await tester.tap(find.text('上をタップ ▲'));
    await tester.pump();

    final settled = find.text('TACKLE!').evaluate().isNotEmpty ||
        find.text('突破された！').evaluate().isNotEmpty;
    expect(settled, isTrue);
  });

  testWidgets('タックルは判定開始前のタップをお手つきMISSにする', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.tap(find.text('上をタップ ▲'));
    await tester.pump();

    expect(find.text('突破された！'), findsOneWidget);
  });

  testWidgets('タックルは成否に関係なくタップ方向へ鮫太朗を移動する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final beforeTap =
        tester.getCenter(find.byKey(const Key('tackle-player'))).dy;
    await tester.tap(find.text('上をタップ ▲'));
    await tester.pump();
    await advance(tester, const Duration(milliseconds: 160));

    expect(tester.getCenter(find.byKey(const Key('tackle-player'))).dy,
        lessThan(beforeTap));
  });

  testWidgets('タックルの判定表示は画面上部のタップでも次セットへ進む', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TackleGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.tap(find.text('上をタップ ▲'));
    await advance(tester, const Duration(milliseconds: 650));

    await tester.tap(find.text('SET 1 / 3'));
    await tester.pump();

    expect(find.text('SET 2 / 3'), findsOneWidget);
  });

  testWidgets('パス＆ランでは両キャラクターが連続して上下移動する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );
    await tester.tap(find.text('スタート'));
    await tester.pump();

    final playerStart =
        tester.getCenter(find.byKey(const Key('pass-player'))).dy;
    final mateStart = tester.getCenter(find.text('🏃')).dy;
    await advance(tester, const Duration(milliseconds: 500));
    final playerAfter =
        tester.getCenter(find.byKey(const Key('pass-player'))).dy;
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
    final player = tester.getCenter(find.byKey(const Key('pass-player')));
    final mate = tester.getCenter(find.text('🏃'));
    await tester.flingFrom(player, mate - player, 1200);
    await advance(tester, const Duration(milliseconds: 20));

    expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget);
  });

  testWidgets('パス＆ランはドラッグ中にフリック始点と方向を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PassAndRunGameScreen()),
    );
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
      const MaterialApp(home: PassAndRunGameScreen()),
    );
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
    expect(find.text('MISS　2秒間パス不可'), findsOneWidget);
    // 失敗パスは画面外へ抜けた後、ペナルティ終了時にプレイヤーへ戻ります。
    await advance(tester, const Duration(milliseconds: 2100));
    expect(find.byKey(const Key('pass-ball')), findsOneWidget);
  });

  testWidgets('送球ポーズと位置は一時停止中に保持され、再開できる', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassAndRunGameScreen()));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    final player = find.byKey(const Key('pass-player'));
    await tester.flingFrom(
        tester.getCenter(player), const Offset(-100, 0), 1200);
    await advance(tester, const Duration(milliseconds: 20));
    expect(tester.widget<MiniGameCharacterAsset>(player).pose,
        MiniGameCharacterPose.rightReach);
    await tester.tap(find.byTooltip('一時停止'));
    await tester.pump();
    final pausedPosition = tester.getCenter(player);
    await advance(tester, const Duration(milliseconds: 500));
    expect(tester.getCenter(player), pausedPosition);
    expect(tester.widget<MiniGameCharacterAsset>(player).pose,
        MiniGameCharacterPose.rightReach);
    await tester.tap(find.text('再開'));
    await tester.pump();
    expect(find.text('一時停止中'), findsNothing);
    expect(tester.widget<MiniGameCharacterAsset>(player).pose,
        MiniGameCharacterPose.rightReach);
  });

  testWidgets('復路と結果は提供済み左向き姿勢を表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PassAndRunGameScreen()));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    // Cross the deadline rather than landing within the real Stopwatch's
    // sub-millisecond offset from the synchronized test clock.
    await advance(tester, const Duration(milliseconds: 15100));
    expect(find.text('復路'), findsOneWidget);
    final player = find.byKey(const Key('pass-player'));
    expect(tester.widget<MiniGameCharacterAsset>(player).pose,
        MiniGameCharacterPose.leftRest);
    await advance(tester, const Duration(milliseconds: 15100));
    expect(find.text('メインへ戻る'), findsOneWidget);
    expect(tester.widget<MiniGameCharacterAsset>(player).pose,
        MiniGameCharacterPose.leftRest);
  });
}
