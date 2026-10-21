import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';

void main() {
  var clock = DateTime.utc(2026, 10, 20);
  final player = find.byKey(const Key('pass-player'));
  final mate = find.byKey(const Key('pass-mate'));
  final ball = find.byKey(const Key('pass-ball'));
  final trail = find.byKey(const Key('pass-ball-trail'));
  PassAndRunCharacterVisual visual(WidgetTester t, Finder f) =>
      t.widget<PassAndRunCharacterVisual>(f);
  void sync(Duration d) {
    clock = clock.add(d);
  }

  Future<void> step(WidgetTester t, int ms) async {
    sync(Duration(milliseconds: ms));
    await t.pump(Duration(milliseconds: ms));
  }

  Future<void> start(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(home: PassAndRunGameScreen(now: () => clock)),
    );
    final context = t.element(find.byType(PassAndRunGameScreen));
    await t.runAsync(() async {
      for (final kind in ['normal', 'mate']) {
        for (final state in [
          'front_hold',
          'front_free',
          'back_hold',
          'back_free'
        ]) {
          for (final frame in ['a', 'b']) {
            await precacheImage(
              AssetImage(
                'assets/images/training_game/minigames/pass_run_${kind}_${state}_$frame.png',
              ),
              context,
            );
          }
        }
      }
      await precacheImage(
        const AssetImage(
          'assets/images/training_game/minigames/pass_run_ball.png',
        ),
        context,
      );
    });
    await t.tap(find.text('スタート'));
    await t.pump();
    // Rendering a cached frame must not advance the authoritative test clock.
  }

  Future<void> throwToMate(WidgetTester t, double seconds) async {
    final field = t.getRect(find.byKey(const Key('pass-field')));
    final origin = t.getCenter(ball);
    // Target the moving receiver about 200ms ahead, not its old location.
    final futureY = .5 +
        .28 * math.sin((seconds + .20) * math.pi * 2 / 2.05 + math.pi * .65);
    final target = Offset(
      t.getCenter(mate).dx,
      field.top + field.height * futureY,
    );
    await t.flingFrom(t.getCenter(player), target - origin, 2000);
    await t.pump();
  }

  Future<void> catchAtMate(WidgetTester t) async {
    for (var i = 0; i < 60 && !visual(t, mate).holding; i++) {
      await step(t, 8);
    }
    expect(visual(t, mate).holding, isTrue);
    expect(visual(t, player).holding, isFalse);
    expect(ball, findsOneWidget);
    expect(trail, findsNothing);
    expect(find.textContaining('PASS 1'), findsOneWidget);
  }

  setUp(() {
    clock = DateTime.utc(2026, 10, 20);
  });

  testWidgets('鮫太郎だけの小さなラベルが操作を遮らず本人に追従する', (t) async {
    await start(t);
    final label = find.byKey(const Key('pass-player-label'));
    expect(find.text('鮫太郎'), findsOneWidget);
    expect(t.widget<Text>(label).style!.fontSize, 10);
    expect(
        t
            .widget<IgnorePointer>(find
                .ancestor(of: label, matching: find.byType(IgnorePointer))
                .first)
            .ignoring,
        isTrue);
    final relative = t.getCenter(label) - t.getCenter(player);
    expect(t.getRect(label).top, greaterThan(t.getRect(player).bottom));
    await step(t, 640);
    expect((t.getCenter(label) - t.getCenter(player) - relative).distance,
        lessThan(.001));
    await t.flingFrom(t.getCenter(label), const Offset(120, 0), 2000);
    await t.pump();
    expect(ball, findsOneWidget);
    expect(trail, findsOneWidget);
  });

  testWidgets('折り返しを連続移動し、停止復帰でも球1個と復路15秒を守る', (t) async {
    await start(t);
    await step(t, 14999);
    final before = t.getCenter(player);
    final mateBefore = t.getCenter(mate);
    await step(t, 1);
    expect((t.getCenter(player) - before).distance, lessThan(1));
    expect((t.getCenter(mate) - mateBefore).distance, lessThan(1));
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    await step(t, 120);
    final middle = t.getCenter(player);
    expect(middle.dx, greaterThan(before.dx));
    final field = t.getRect(find.byKey(const Key('pass-field')));
    expect(middle.dx, lessThan(field.left + field.width * .75));
    await t.flingFrom(middle, const Offset(100, -100), 2000);
    await t.pump();
    expect(trail, findsNothing);
    expect(ball, findsOneWidget);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final pausedPlayer = t.getCenter(player);
    final pausedBall = t.getCenter(ball);
    await step(t, 3000);
    expect(t.getCenter(player), pausedPlayer);
    expect(t.getCenter(ball), pausedBall);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(player), pausedPlayer);
    await step(t, 360);
    expect(
        t.getCenter(player).dx, closeTo(field.left + field.width * .75, .001));
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    expect(ball, findsOneWidget);
    expect(visual(t, player).facing, PassRunFacing.front);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    await step(t, 15000);
    expect(find.text('メインへ戻る'), findsOneWidget);
    expect(ball, findsNothing);
    // The product retries by reopening from the training menu.
    await t.pumpWidget(const SizedBox());
    await start(t);
    expect(find.text('攻撃方向 ↑'), findsOneWidget);
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    expect(ball, findsOneWidget);
    expect(
        t.getCenter(player).dx, closeTo(field.left + field.width * .25, .001));
  });

  testWidgets('往路期限とOS停止が競合しても折り返しと復路時計を停止する', (t) async {
    await start(t);
    sync(const Duration(milliseconds: 15001));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(find.text('一時停止中'), findsOneWidget);
    final position = t.getCenter(player);
    await step(t, 20000);
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    expect(t.getCenter(player), position);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.tap(find.text('再開'));
    await t.pump();
    await step(t, 480);
    expect(find.textContaining('残り 15.0s'), findsOneWidget);
    expect(ball, findsOneWidget);
  });

  testWidgets('MISS後の停止中も消失球とペナルティを固定する', (t) async {
    await start(t);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    await step(t, 400);
    expect(ball, findsNothing);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    await step(t, 5000);
    expect(ball, findsNothing);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(ball, findsNothing);
    await step(t, 2100);
    expect(ball, findsOneWidget);
  });

  testWidgets('期限直前の飛翔球は折り返しで1個の保持球になり再開できる', (t) async {
    await start(t);
    await step(t, 14990);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    expect(ball, findsOneWidget);
    await step(t, 10);
    expect(trail, findsNothing);
    expect(ball, findsOneWidget);
    expect(visual(t, player).holding, isTrue);
    for (var i = 0; i < 12; i++) {
      await step(t, 40);
      expect(ball, findsOneWidget);
    }
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    expect(ball, findsOneWidget);
  });

  testWidgets('上下反転の保持球は位置を連続補間し、停止中も1個のまま', (t) async {
    await start(t);
    await step(t, 640);
    expect(visual(t, player).facing, PassRunFacing.front);
    var before = t.getCenter(ball);
    await step(t, 10);
    expect((t.getCenter(ball) - before).distance, lessThan(1));
    expect(visual(t, player).facing, PassRunFacing.front);
    before = t.getCenter(ball);
    await step(t, 1);
    expect((t.getCenter(ball) - before).distance, lessThan(1));
    expect(visual(t, player).facing, PassRunFacing.back);
    expect(visual(t, player).holding, isFalse);
    expect(ball, findsOneWidget);
    for (var i = 0; i < 4; i++) {
      before = t.getCenter(ball);
      await step(t, 8);
      expect((t.getCenter(ball) - before).distance, lessThan(3));
      expect(ball, findsOneWidget);
    }
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final paused = t.getCenter(ball);
    await step(t, 3000);
    expect(t.getCenter(ball), paused);
    expect(visual(t, player).facing, PassRunFacing.back);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(ball), paused);
    await step(t, 48);
    expect(visual(t, player).holding, isTrue);
    expect(ball, findsOneWidget);
    // Legal sideways input remains available immediately after the visual turn.
    await t.flingFrom(t.getCenter(player), const Offset(100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
  });

  testWidgets('鮫太郎と色違い仲間がそれぞれの実移動方向を向く', (t) async {
    await start(t);
    var elapsed = 0;
    for (final target in [0, 250, 400, 750, 1100, 1600, 2000, 2500]) {
      await step(t, target - elapsed);
      elapsed = target;
      for (final pair in [
        (player, PassRunRunner.player),
        (mate, PassRunRunner.companion)
      ]) {
        final velocity = PassRunMotion.velocityYAt(target / 1000, pair.$2);
        expect(visual(t, pair.$1).facing,
            velocity > 0 ? PassRunFacing.front : PassRunFacing.back);
      }
      expect(ball, findsOneWidget);
      expect(find.text('鮫太郎'), findsOneWidget);
    }
  });

  testWidgets('仲間の保持中も正面→背面反転と停止復帰で球を連続保持する', (t) async {
    await start(t);
    await step(t, 1400);
    await throwToMate(t, 1.4);
    await catchAtMate(t);
    final elapsed = clock.difference(DateTime.utc(2026, 10, 20)).inMilliseconds;
    await step(t, 1890 - elapsed);
    expect(visual(t, mate).holding, isTrue);
    expect(visual(t, mate).facing, PassRunFacing.front);
    var previous = t.getCenter(ball);
    await step(t, 14);
    expect((t.getCenter(ball) - previous).distance, lessThan(3));
    expect(visual(t, mate).facing, PassRunFacing.back);
    expect(ball, findsOneWidget);
    expect(trail, findsNothing);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final paused = t.getCenter(ball);
    await step(t, 2000);
    expect(t.getCenter(ball), paused);
    expect(ball, findsOneWidget);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(ball), paused);
    for (var i = 0; i < 10; i++) {
      previous = t.getCenter(ball);
      await step(t, 8);
      expect((t.getCenter(ball) - previous).distance, lessThan(3));
      expect(ball, findsOneWidget);
    }
    expect(visual(t, mate).holding, isTrue);
  });

  testWidgets('通常の同期済みサーバー時計でも仲間走行フレームが更新する', (t) async {
    ServerTimeClock.instance.synchronize(DateTime.utc(2026, 10, 21));
    await t.pumpWidget(const MaterialApp(home: PassAndRunGameScreen()));
    await t.tap(find.text('スタート'));
    await t.pump();
    final initial = visual(t, mate).frame;
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 270)));
    await t.pump(const Duration(milliseconds: 270));
    expect(visual(t, mate).frame, isNot(initial));
    expect(visual(t, mate).assetPath, contains('pass_run_mate_'));
  });

  testWidgets('仲間の正背面・保持非保持4状態すべてが実Imageの走行A/Bへ更新される', (t) async {
    await start(t);
    void expectFrame(String facing, String state, String frame) {
      final sprite = visual(t, mate);
      expect(sprite.character, PassRunCharacter.companion);
      expect(sprite.size, 84);
      final image = t.widget<Image>(
          find.descendant(of: mate, matching: find.byType(Image)));
      final expected = 'pass_run_mate_${facing}_${state}_$frame.png';
      expect(sprite.assetPath, endsWith(expected));
      expect((image.image as AssetImage).assetName, endsWith(expected));
      expect(find.text('🏃'), findsNothing);
    }

    // Back/free: elapsed gameplay rebuilds the mate Image at a gait boundary.
    expectFrame('back', 'free', 'a');
    await step(t, 240);
    expectFrame('back', 'free', 'b');
    // Front/free after the mate's independent direction reversal settles.
    await step(t, 720);
    expectFrame('front', 'free', 'a');
    await step(t, 240);
    expectFrame('front', 'free', 'b');
    await step(t, 100);
    await throwToMate(t, 1.3);
    await catchAtMate(t);
    Future<void> at(int target) async {
      final elapsed =
          clock.difference(DateTime.utc(2026, 10, 20)).inMilliseconds;
      expect(elapsed, lessThanOrEqualTo(target));
      await step(t, target - elapsed);
    }

    // The same held ball stays single while both direction-specific pairs run.
    await at(1650);
    expectFrame('front', 'hold', 'a');
    await at(1850);
    expectFrame('front', 'hold', 'b');
    await at(1990);
    expectFrame('back', 'hold', 'a');
    await at(2230);
    expectFrame('back', 'hold', 'b');
    expect(ball, findsOneWidget);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    await step(t, 1000);
    expectFrame('back', 'hold', 'b');
    await t.tap(find.text('再開'));
    await t.pump();
    await step(t, 170);
    expectFrame('back', 'hold', 'a');
    expect(ball, findsOneWidget);
  });

  testWidgets('承認済み保持・非保持と2脚位相を表示し、球は常に1個', (t) async {
    await start(t);
    expect(visual(t, player).holding, isTrue);
    expect(visual(t, mate).holding, isFalse);
    expect(find.text('🏃'), findsNothing);
    expect(visual(t, player).assetPath, contains('normal_front_hold_a'));
    expect(visual(t, mate).assetPath, contains('mate_back_free_a'));
    expect(ball, findsOneWidget);
    await step(t, 250);
    expect(visual(t, player).assetPath, contains('normal_front_hold_b'));
    expect(visual(t, mate).assetPath, contains('mate_back_free_b'));
    expect(t.takeException(), isNull);
  });

  testWidgets('0.75倍の両者と、保持球→飛翔球→捕球補間を切れ目なく描く', (t) async {
    await start(t);
    expect(visual(t, player).size, 84);
    expect(visual(t, mate).size, 84);
    final held = t.getCenter(ball);
    final heldGeometry = PassAndRunCharacterVisual.heldBallGeometry(
      character: PassRunCharacter.normal,
      frame: visual(t, player).frame,
      facing: PassRunFacing.front,
      size: 84,
    );
    await throwToMate(t, 0);
    expect((t.getCenter(ball) - held).distance, lessThan(.000001));
    final release = t
        .widget<PassAndRunBallVisual>(find.byType(PassAndRunBallVisual))
        .geometry;
    expect(release.longAxis, heldGeometry.longAxis);
    expect(release.shortAxis, heldGeometry.shortAxis);
    var settling = false;
    for (var i = 0; i < 80 && !visual(t, mate).holding; i++) {
      await step(t, 4);
      expect(ball, findsOneWidget);
      if (find.textContaining('PASS 1').evaluate().isNotEmpty &&
          !visual(t, mate).holding) {
        settling = true;
        expect(find.byType(PassAndRunBallVisual), findsOneWidget);
        expect(trail, findsNothing);
      }
    }
    expect(settling, isTrue);
    expect(visual(t, mate).holding, isTrue);
    expect(find.byType(PassAndRunBallVisual), findsNothing);
    expect(ball, findsOneWidget);
    expect(visual(t, player).size, 84);
    expect(visual(t, mate).size, 84);
  });

  testWidgets('捕球補間の途中で停止しても球位置・寸法と残り時間を保つ', (t) async {
    await start(t);
    await throwToMate(t, 0);
    for (var i = 0;
        i < 80 && find.textContaining('PASS 1').evaluate().isEmpty;
        i++) {
      await step(t, 4);
    }
    expect(find.textContaining('PASS 1'), findsOneWidget);
    await step(t, 40);
    expect(visual(t, mate).holding, isFalse);
    final center = t.getCenter(ball);
    final geometry = t
        .widget<PassAndRunBallVisual>(find.byType(PassAndRunBallVisual))
        .geometry;
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    await step(t, 500);
    expect(t.getCenter(ball), center);
    final paused = t
        .widget<PassAndRunBallVisual>(find.byType(PassAndRunBallVisual))
        .geometry;
    expect(paused.longAxis, geometry.longAxis);
    expect(paused.shortAxis, geometry.shortAxis);
    expect(paused.angle, geometry.angle);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(ball), center);
    await step(t, 32);
    expect(visual(t, mate).holding, isFalse);
    await step(t, 8);
    expect(visual(t, mate).holding, isTrue);
    expect(ball, findsOneWidget);
  });

  testWidgets('上下移動の向きに関係なく攻撃方向への投球は無得点・2秒制限', (t) async {
    await start(t);
    for (final wait in [0, 3500]) {
      if (wait > 0) await step(t, wait);
      await t.flingFrom(t.getCenter(player), const Offset(100, -1), 2000);
      await t.pump();
      expect(find.text('前方パス　2秒間パス不可'), findsOneWidget);
      expect(trail, findsNothing);
      expect(visual(t, player).holding, isTrue);
      expect(find.textContaining('PASS 0'), findsOneWidget);
      await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
      await t.pump();
      expect(trail, findsNothing);
    }
    await step(t, 2100);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    expect(visual(t, player).holding, isFalse);
  });

  testWidgets('復路で攻撃を反転し、正背面表示や移動方向と分離する', (t) async {
    await start(t);
    await step(t, 15100);
    await step(t, 480);
    expect(find.text('攻撃方向 ↓'), findsOneWidget);
    await step(t, 80);
    expect(visual(t, player).facing, PassRunFacing.front);
    expect(visual(t, mate).facing, PassRunFacing.back);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 1), 2000);
    await t.pump();
    expect(find.text('前方パス　2秒間パス不可'), findsOneWidget);
    expect(trail, findsNothing);
    await step(t, 2100);
    await t.flingFrom(t.getCenter(player), const Offset(100, -20), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
  });

  testWidgets('受球→B保持→合法な返球→Normal保持。停止中は球・脚位相を固定', (t) async {
    await start(t);
    await throwToMate(t, 0);
    await catchAtMate(t);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final heldPosition = t.getCenter(ball);
    final heldFrame = visual(t, mate).frame;
    await step(t, 503);
    expect(t.getCenter(ball), heldPosition);
    expect(visual(t, mate).frame, heldFrame);
    await t.tap(find.text('再開'));
    await t.pump();
    expect((t.getCenter(ball) - heldPosition).distance, lessThan(1));
    Offset? release;
    for (var i = 0; i < 300 && !visual(t, player).holding; i++) {
      final wasHolding = visual(t, mate).holding;
      await step(t, 8);
      if (wasHolding && !visual(t, mate).holding) release = t.getCenter(ball);
      if (release != null && trail.evaluate().isNotEmpty) {
        expect(
          t.getCenter(ball).dy,
          greaterThanOrEqualTo(release.dy - .000001),
        );
      }
      expect(ball, findsOneWidget);
    }
    expect(release, isNotNull);
    expect(visual(t, player).holding, isTrue);
    expect(visual(t, mate).holding, isFalse);
    expect(trail, findsNothing);
    expect(find.textContaining('PASS 1'), findsOneWidget);
  });

  testWidgets('前方へしか返せない間Bは保持し、ラウンド終了で持ち越さない', (t) async {
    await start(t);
    await step(t, 1400);
    await throwToMate(t, 1.4);
    await catchAtMate(t);
    await step(t, 160);
    expect(visual(t, mate).holding, isTrue);
    expect(trail, findsNothing);
    await step(t, 15100);
    await step(t, 480);
    expect(find.text('攻撃方向 ↓'), findsOneWidget);
    expect(visual(t, player).holding, isTrue);
    expect(visual(t, mate).holding, isFalse);
    expect(ball, findsOneWidget);
    await step(t, 15100);
    await step(t, 480);
    expect(find.text('メインへ戻る'), findsOneWidget);
    expect(ball, findsNothing);
    expect(trail, findsNothing);
  });

  testWidgets('復路もBの合法受球・保持待機・後方返球で同じ攻撃方向を使う', (t) async {
    await start(t);
    await step(t, 15100);
    await step(t, 480);
    await step(t, 500);
    await throwToMate(t, .5);
    await catchAtMate(t);
    Offset? release;
    for (var i = 0; i < 500 && !visual(t, player).holding; i++) {
      final wasHolding = visual(t, mate).holding;
      await step(t, 8);
      if (wasHolding && !visual(t, mate).holding) release = t.getCenter(ball);
      if (release != null && trail.evaluate().isNotEmpty) {
        expect(t.getCenter(ball).dy, lessThanOrEqualTo(release.dy + .000001));
      }
      expect(ball, findsOneWidget);
    }
    expect(release, isNotNull);
    expect(visual(t, player).holding, isTrue);
    expect(find.textContaining('PASS 1'), findsOneWidget);
  });

  testWidgets('返球期限後ticker前の停止でも再開後に次のパスが可能', (t) async {
    await start(t);
    await throwToMate(t, 0);
    await catchAtMate(t);
    for (var i = 0; i < 300 && visual(t, mate).holding; i++) {
      await step(t, 8);
    }
    expect(trail, findsOneWidget);
    // Advance only the authoritative clock: intentionally do not pump ticker.
    sync(const Duration(seconds: 2));
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    await t.tap(find.text('再開'));
    await t.pump();
    expect(visual(t, player).holding, isTrue);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
  });

  for (final size in [
    const Size(240, 568),
    const Size(320, 568),
    const Size(844, 390),
  ]) {
    testWidgets('小画面・横画面でも走行画像がフィールドから出ない $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await start(t);
      final field = t.getRect(find.byKey(const Key('pass-field')));
      for (var i = 0; i < 14; i++) {
        await step(t, 200);
        for (final actor in [player, mate]) {
          final rect = t.getRect(actor);
          expect(rect.left, greaterThanOrEqualTo(field.left - .000001));
          expect(rect.top, greaterThanOrEqualTo(field.top - .000001));
          expect(rect.right, lessThanOrEqualTo(field.right + .000001));
          expect(rect.bottom, lessThanOrEqualTo(field.bottom + .000001));
        }
      }
      expect(t.takeException(), isNull);
    });
  }
}
