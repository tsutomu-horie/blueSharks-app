import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_direction_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';

void main() {
  var clock = DateTime.utc(2026, 10, 20);
  var currentMotionSeed = 54;
  var currentSettings = const PassRunSettings();
  PassRunMotion? fixtureMotion;
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

  Future<void> start(WidgetTester t,
      {int seed = 54,
      PassRunSettings settings = const PassRunSettings()}) async {
    currentMotionSeed = seed;
    currentSettings = settings;
    await t.pumpWidget(
      MaterialApp(
          home: PassAndRunGameScreen(
              motionSeed: seed, settings: settings, now: () => clock)),
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
    await t.pump();
    await t.tap(find.text('スタート'));
    await t.pump();
    final field = t.getRect(find.byKey(const Key('pass-field')));
    fixtureMotion = PassRunMotion(
      seed: seed,
      roundSeconds: settings.roundDurationMs / 1000,
      speedScale: settings.runSpeedScale,
    )..updateFieldGeometry(field.size);
    // Rendering a cached frame must not advance the authoritative test clock.
  }

  Offset aimAtMate(WidgetTester t, double seconds) {
    final field = t.getRect(find.byKey(const Key('pass-field')));
    final origin = t.getCenter(ball);
    final speed =
        field.width * .5 / (currentSettings.ballHalfFieldTravelMs / 1000);
    final motion = fixtureMotion ??
        (PassRunMotion(
          seed: currentMotionSeed,
          roundSeconds: currentSettings.roundDurationMs / 1000,
          speedScale: currentSettings.runSpeedScale,
        )..updateFieldGeometry(field.size));
    var travel = .44;
    var target = Offset.zero;
    for (var i = 0; i < 24; i++) {
      target = Offset(
          t.getCenter(mate).dx,
          field.top +
              field.height *
                  motion.yAt(seconds + travel, PassRunRunner.companion,
                      outbound: find.text('往路').evaluate().isNotEmpty));
      travel = (target - origin).distance / speed;
    }
    return target - origin;
  }

  Future<Offset> throwToMate(WidgetTester t, double seconds) async {
    var elapsed = seconds;
    var aim = aimAtMate(t, elapsed);
    final outbound = find.text('往路').evaluate().isNotEmpty;
    bool isIllegalUserAim(Offset offset) {
      final direction = PassAndRunRules.userPassDirection(
        PassFlick(
          deltaX: offset.dx,
          deltaY: offset.dy,
          velocityX: offset.dx * 10,
          velocityY: offset.dy * 10,
        ),
        outbound: outbound,
      );
      return PassAndRunRules.isForwardDirection(
        deltaX: direction.deltaX,
        deltaY: direction.deltaY,
        outbound: outbound,
      );
    }

    bool catchesOnActualCorrectedPath(Offset offset, double atSeconds) {
      final field = t.getRect(find.byKey(const Key('pass-field')));
      final origin = t.getCenter(ball);
      final flick = PassFlick(
        deltaX: offset.dx,
        deltaY: offset.dy,
        velocityX: offset.dx * 10,
        velocityY: offset.dy * 10,
      );
      final direction = PassAndRunRules.userPassDirection(
        flick,
        outbound: outbound,
      );
      final length = Offset(direction.deltaX, direction.deltaY).distance;
      if (length == 0) return false;
      final unit = Offset(direction.deltaX, direction.deltaY) / length;
      final speed =
          field.width * .5 / (currentSettings.ballHalfFieldTravelMs / 1000);
      final motion = fixtureMotion!;
      final mateX = t.getCenter(mate).dx;
      final crossingSeconds = (mateX - origin.dx) / (unit.dx * speed);
      if (!crossingSeconds.isFinite || crossingSeconds <= 0) return false;

      // Match the live sweep's blended receiving radius near the catch time.
      final scale = PassRunFieldGeometry(field.size).actorSize / 112;
      const playerRadius = 27.549925049569 / 2;
      const mateRadius = 30.956565121244 / 2;
      final blend = (crossingSeconds / .22).clamp(0.0, 1.0);
      final radius =
          (playerRadius + (mateRadius - playerRadius) * blend + 24) * scale;
      final halfWindow = radius / (unit.dx.abs() * speed);
      final from = math.max(0.0, crossingSeconds - halfWindow);
      final to = crossingSeconds + halfWindow;
      Offset relative(double flightSeconds) {
        final time = atSeconds + flightSeconds;
        final ballAt = origin + unit * speed * flightSeconds;
        final mateAt = Offset(
          mateX,
          field.top +
              field.height *
                  motion.yAt(time, PassRunRunner.companion, outbound: outbound),
        );
        return ballAt - mateAt;
      }

      // The actual path uses the corrected direction; sweep only the segment
      // where the ball is within one receiving radius horizontally.
      final start = relative(from), end = relative(to);
      return PassAndRunRules.sweptCollision(
            startX: start.dx,
            startY: start.dy,
            endX: end.dx,
            endY: end.dy,
            startRadius: radius,
            endRadius: radius,
          ) !=
          null;
    }

    // Wait through the current 15-second run for an actual legal opportunity;
    // there is intentionally no seven-second product guarantee.
    for (var i = 0;
        i < 1874 &&
            (isIllegalUserAim(aim) ||
                !catchesOnActualCorrectedPath(aim, elapsed));
        i++) {
      await step(t, 8);
      elapsed += .008;
      aim = aimAtMate(t, elapsed);
    }
    expect(
      isIllegalUserAim(aim),
      isFalse,
      reason: '1ラウンド内で入力補正後の合法角度を見つける',
    );
    expect(
      catchesOnActualCorrectedPath(aim, elapsed),
      isTrue,
      reason: '補正後の実投球経路が受球判定に届く',
    );
    final release = t.getCenter(ball);
    await t.flingFrom(t.getCenter(player), aim, 2000);
    await t.pump();
    return release;
  }

  Future<void> catchAtMate(WidgetTester t) async {
    for (var i = 0; i < 140 && !visual(t, mate).holding; i++) {
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

  test('ガイド全体は3.2秒の滑らかな透明往復を共有する', () {
    double opacity(double seconds) => PassRunDirectionGuidePainter(
            center: Offset.zero, attackUp: true, seconds: seconds)
        .opacity;
    expect(opacity(0), 0);
    expect(opacity(.8), closeTo(.5, 1e-9));
    expect(opacity(1.6), 1);
    expect(opacity(2.4), closeTo(.5, 1e-9));
    expect(opacity(3.2), 0);
  });

  for (final up in [true, false]) {
    testWidgets('方向ガイドは本人中心を保ち、所持と投球に追従する $up', (t) async {
      await start(t);
      final guide = find.byKey(const Key('pass-direction-guide'));
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      for (var i = 0; i < 8; i++) {
        await step(t, 100);
        if (visual(t, player).holding) {
          expect(guide, findsOneWidget);
          final paint = t.widget<CustomPaint>(guide).painter!
              as PassRunDirectionGuidePainter;
          final field = t.getTopLeft(find.byKey(const Key('pass-field')));
          expect((paint.center - (t.getCenter(player) - field)).distance,
              lessThan(1e-6));
          expect(paint.attackUp, up);
          expect(
              find.ancestor(
                  of: guide,
                  matching: find.byWidgetPredicate(
                      (w) => w is IgnorePointer && w.ignoring)),
              findsOneWidget);
        } else {
          expect(guide, findsNothing);
        }
        expect(ball, findsOneWidget);
      }
      await t.flingFrom(
          t.getCenter(player), Offset(up ? 100 : -100, up ? 40 : -40), 2000);
      await t.pump();
      expect(visual(t, player).holding, isFalse);
      expect(guide, findsNothing);
      expect(ball, findsOneWidget);
    });
  }

  testWidgets('交換の正背面補間でも方向ガイドと球は本人に追従する', (t) async {
    await start(t);
    await step(t, 15000);
    await step(t, 20);
    expect(visual(t, player).holding, isFalse);
    expect(find.byKey(const Key('pass-direction-guide')), findsOneWidget);
    expect(ball, findsOneWidget);
    await step(t, 80);
    expect(visual(t, player).holding, isTrue);
    expect(ball, findsOneWidget);
  });

  testWidgets('鮫太郎だけの小さなラベルが操作を遮らず本人に追従する', (t) async {
    await start(t);
    final label = find.byKey(const Key('pass-player-label'));
    expect(find.text('鮫太郎'), findsOneWidget);
    expect(t.widget<Text>(label).style!.fontSize, 10);
    expect(
        t
            .widget<IgnorePointer>(find
                .ancestor(
                    of: label,
                    matching: find.byWidgetPredicate(
                        (w) => w is IgnorePointer && w.ignoring))
                .first)
            .ignoring,
        isTrue);
    final relative = t.getCenter(label) - t.getCenter(player);
    expect(t.getRect(label).bottom, lessThan(t.getRect(player).top));
    expect(t.widget<Text>(label).style!.color, Colors.white);
    expect(t.widget<Text>(label).style!.fontWeight, FontWeight.w700);
    await step(t, 640);
    expect((t.getCenter(label) - t.getCenter(player) - relative).distance,
        lessThan(.001));
    await t.flingFrom(t.getCenter(label), const Offset(120, 0), 2000);
    await t.pump();
    expect(ball, findsOneWidget);
    expect(trail, findsOneWidget);
  });

  testWidgets('球速半減後も距離・角度によらず同じ速度で飛ぶ', (t) async {
    for (final delta in [const Offset(-100, 0), const Offset(-100, 60)]) {
      await start(t);
      final width = t.getSize(find.byKey(const Key('pass-field'))).width;
      await t.flingFrom(t.getCenter(player), delta, 2000);
      await t.pump();
      final origin = t.getCenter(ball);
      await step(t, 40);
      final first = t.getCenter(ball);
      await step(t, 40);
      final second = t.getCenter(ball);
      final expected = width * .5 / .44 * .04;
      expect((first - origin).distance, closeTo(expected, .001));
      expect((second - first).distance, closeTo(expected, .001));
      expect(PassAndRunRules.roundDuration, const Duration(seconds: 15));
      expect(PassAndRunRules.mateCollisionRadius, 24);
      expect(ball, findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    }
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
    final pausedFrame = visual(t, mate).frame;
    final pausedPlayer = t.getCenter(player);
    final pausedBall = t.getCenter(ball);
    await step(t, 3000);
    expect(t.getCenter(player), pausedPlayer);
    expect(visual(t, mate).frame, pausedFrame);
    expect(t.getCenter(ball), pausedBall);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(player), pausedPlayer);
    await step(t, 880);
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
    expect(find.byKey(const Key('pass-attack-direction')), findsNothing);
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
    await step(t, 1000);
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
    expect(ball, findsOneWidget);
    for (var i = 0; i < 25; i++) {
      await step(t, 40);
      expect(ball, findsOneWidget);
    }
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    expect(ball, findsOneWidget);
  });

  testWidgets('往復反転の球の位置と向きを80msで接続し、停止中も固定', (t) async {
    await start(t);
    await step(t, 15000);
    var before = t.getCenter(ball);
    for (var i = 0; i < 5; i++) {
      await step(t, 8);
      expect((t.getCenter(ball) - before).distance, lessThan(5));
      before = t.getCenter(ball);
      expect(ball, findsOneWidget);
    }
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    final paused = t.getCenter(ball);
    await step(t, 3000);
    expect(t.getCenter(ball), paused);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(ball), paused);
    await step(t, 40);
    expect(visual(t, player).facing, PassRunFacing.front);
    expect(visual(t, player).holding, isTrue);
  });

  testWidgets('前後差が入れ替わっても両者が同じ攻撃方向へ走る', (t) async {
    await start(t);
    for (var i = 0; i < 150; i++) {
      await step(t, 100);
      if (i < 149) {
        expect(visual(t, player).facing, PassRunFacing.back);
        expect(visual(t, mate).facing, PassRunFacing.back);
      }
      expect(ball, findsOneWidget);
    }
    await step(t, 1000);
    for (var i = 0; i < 149; i++) {
      await step(t, 100);
      expect(visual(t, player).facing, PassRunFacing.front);
      expect(visual(t, mate).facing, PassRunFacing.front);
      expect(ball, findsOneWidget);
    }
  });

  testWidgets('並走中の仲間の保持を停止復帰でも保ち、後方返球を待つ', (t) async {
    await start(t, seed: 1);
    await step(t, 200);
    await throwToMate(t, .2);
    await catchAtMate(t);
    expect(find.text('仲間からの返球待ち…'), findsOneWidget);
    final before = t.getCenter(ball);
    await t.tap(find.byTooltip('一時停止'));
    await t.pump();
    await step(t, 2000);
    expect(t.getCenter(ball), before);
    expect(visual(t, mate).holding, isTrue);
    await t.tap(find.text('再開'));
    await t.pump();
    expect(t.getCenter(ball), before);
    expect(ball, findsOneWidget);
  });

  testWidgets('通常の同期済みサーバー時計でも仲間走行フレームが更新する', (t) async {
    ServerTimeClock.instance.synchronize(DateTime.utc(2026, 10, 21));
    await t.pumpWidget(const MaterialApp(home: PassAndRunGameScreen()));
    await t.runAsync(() async {
      for (final path in PassAndRunCharacterVisual.assets) {
        await precacheImage(
            AssetImage(path), t.element(find.byType(PassAndRunGameScreen)));
      }
    });
    await t.pump();
    await t.tap(find.text('スタート'));
    await t.pump();
    final initial = visual(t, mate).frame;
    for (var attempt = 0;
        attempt < 12 && visual(t, mate).frame == initial;
        attempt++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(visual(t, mate).frame, isNot(initial));
    expect(visual(t, mate).assetPath, contains('pass_run_mate_'));
  });

  testWidgets('往復の仲間の保持/非保持4状態で実Image走行A/Bが更新する', (t) async {
    for (final up in [true, false]) {
      await start(t, seed: 1);
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      void check() {
        final v = visual(t, mate);
        final image = t.widget<Image>(
            find.descendant(of: mate, matching: find.byType(Image)));
        expect((image.image as AssetImage).assetName, v.assetPath);
        expect(v.facing, up ? PassRunFacing.back : PassRunFacing.front);
        expect(v.size, 84);
      }

      check();
      final initial = visual(t, mate).frame;
      for (var i = 0; i < 30 && visual(t, mate).frame == initial; i++) {
        await step(t, 8);
      }
      check();
      expect(visual(t, mate).frame, isNot(initial));
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await start(t, seed: 1);
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      await throwToMate(t, 0);
      await catchAtMate(t);
      check();
      expect(
        visual(t, mate).holding,
        isTrue,
        reason: 'up=$up',
      );
      expect(visual(t, mate).assetPath, contains('_hold_'));
      expect(ball, findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    }
  });

  testWidgets('承認済み保持・非保持と2脚位相を表示し、球は常に1個', (t) async {
    await start(t);
    expect(visual(t, player).holding, isTrue);
    expect(visual(t, mate).holding, isFalse);
    expect(find.text('🏃'), findsNothing);
    expect(visual(t, player).assetPath, contains('normal_back_hold_a'));
    expect(visual(t, mate).assetPath, contains('mate_back_free_a'));
    expect(ball, findsOneWidget);
    final playerFrame = visual(t, player).frame;
    for (var i = 0; i < 30 && visual(t, player).frame == playerFrame; i++) {
      await step(t, 40);
    }
    expect(visual(t, player).frame, isNot(playerFrame));
    expect(
      visual(t, player).assetPath,
      contains('normal_back_hold_${visual(t, player).frame == 0 ? 'a' : 'b'}'),
    );
    final mateFrame = visual(t, mate).frame;
    for (var i = 0; i < 30 && visual(t, mate).frame == mateFrame; i++) {
      await step(t, 40);
    }
    expect(visual(t, mate).frame, isNot(mateFrame));
    expect(
      visual(t, mate).assetPath,
      contains('mate_back_free_${visual(t, mate).frame == 0 ? 'a' : 'b'}'),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('0.75倍の両者と、保持球→飛翔球→捕球補間を切れ目なく描く', (t) async {
    await start(t, seed: 1);
    expect(visual(t, player).size, 84);
    expect(visual(t, mate).size, 84);
    final held = await throwToMate(t, 0);
    expect((t.getCenter(ball) - held).distance, lessThan(.000001));
    final release = t
        .widget<PassAndRunBallVisual>(find.byType(PassAndRunBallVisual))
        .geometry;
    final heldGeometry = PassAndRunCharacterVisual.heldBallGeometry(
      character: PassRunCharacter.normal,
      frame: visual(t, player).frame,
      facing: PassRunFacing.back,
      size: 84,
    );
    expect(release.longAxis, heldGeometry.longAxis);
    expect(release.shortAxis, heldGeometry.shortAxis);
    var settling = false;
    for (var i = 0; i < 160 && !visual(t, mate).holding; i++) {
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
    await start(t, seed: 0);
    await throwToMate(t, 0);
    for (var i = 0;
        i < 160 && find.textContaining('PASS 1').evaluate().isEmpty;
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

  testWidgets('上下移動の向きに関係なく攻撃方向への投球は無得点・1秒制限', (t) async {
    await start(t);
    for (final wait in [0, 3500]) {
      if (wait > 0) await step(t, wait);
      await t.flingFrom(t.getCenter(player), const Offset(100, -10), 2000);
      await t.pump();
      expect(find.text('前方パス　1秒間パス不可'), findsOneWidget);
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

  testWidgets('前方ミスの入力禁止は999msまで、1000msで解除する', (t) async {
    await start(t);
    await t.flingFrom(t.getCenter(player), const Offset(100, -10), 2000);
    await t.pump();
    expect(find.text('前方パス　1秒間パス不可'), findsOneWidget);
    await step(t, 999);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsNothing);
    expect(find.text('前方パス　1秒間パス不可'), findsOneWidget);
    await step(t, 1);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 0), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
    expect(find.text('前方パス　1秒間パス不可'), findsNothing);
  });

  testWidgets('復路で攻撃を反転し、正背面表示や移動方向と分離する', (t) async {
    await start(t);
    await step(t, 15100);
    await step(t, 1000);
    expect(find.byKey(const Key('pass-attack-direction')), findsNothing);
    await step(t, 80);
    expect(visual(t, player).facing, PassRunFacing.front);
    expect(visual(t, mate).facing, PassRunFacing.front);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 10), 2000);
    await t.pump();
    expect(find.text('前方パス　1秒間パス不可'), findsOneWidget);
    expect(trail, findsNothing);
    await step(t, 2100);
    await t.flingFrom(t.getCenter(player), const Offset(100, -20), 2000);
    await t.pump();
    expect(trail, findsOneWidget);
  });

  for (final seed in [27, 120]) {
    testWidgets('投げずに待つ間の速度補助は元軌道を保って不可時間を計測する seed$seed', (t) async {
      await start(t, seed: seed);
      final field = t.getRect(find.byKey(const Key('pass-field')));
      var blocked = 0, legal = 0;
      var run = 0.0,
          maximum = 0.0,
          baselineRun = 0.0,
          baselineMaximum = 0.0,
          maxDifference = 0.0;
      for (var tick = 1; tick <= 370; tick++) {
        await step(t, 40);
        final seconds = tick * .04;
        final p = t.getCenter(player).dy, m = t.getCenter(mate).dy;
        if (m < p) {
          blocked++;
          run += .04;
          maximum = math.max(maximum, run);
        } else {
          legal++;
          run = 0;
        }
        final basePlayer = fixtureMotion!.yAt(seconds, PassRunRunner.player);
        final baseMate = fixtureMotion!.yAt(seconds, PassRunRunner.companion);
        if (baseMate < basePlayer) {
          baselineRun += .04;
          baselineMaximum = math.max(baselineMaximum, baselineRun);
        } else {
          baselineRun = 0;
        }
        maxDifference = math.max(
            maxDifference, (p - (field.top + field.height * basePlayer)).abs());
        expect(ball, findsOneWidget);
      }
      expect(blocked, greaterThan(0));
      expect(legal, greaterThan(0));
      expect(maximum, lessThan(15));
      expect(maxDifference, greaterThan(.1), reason: '長い不可区間に速度補助が実際に働く');
      // ignore: avoid_print
      print(
          'Widget no-input seed=$seed legal=$legal blocked=$blocked longestBlocked baseline=${baselineMaximum.toStringAsFixed(2)}s assisted=${maximum.toStringAsFixed(2)}s maxPaceDifference=${maxDifference.toStringAsFixed(2)}px');
    });
  }

  for (final seed in [3, 27]) {
    testWidgets('通常軌道の速度補助でも横連投だけは常時成功せず不可区間が残る seed$seed', (t) async {
      await start(t, seed: seed);
      var attempts = 0, blocked = 0, legal = 0;
      var currentBlocked = 0.0, longestBlocked = 0.0;
      var previousPlayer = t.getCenter(player),
          previousMate = t.getCenter(mate);
      var maxStep = 0.0;
      for (var tick = 0; tick < 370; tick++) {
        if (visual(t, player).holding) {
          if (t.getCenter(mate).dy < t.getCenter(player).dy) {
            blocked++;
            currentBlocked += .04;
            longestBlocked = math.max(longestBlocked, currentBlocked);
          } else {
            legal++;
            currentBlocked = 0;
          }
          if (tick % 7 == 0) {
            await t.flingFrom(t.getCenter(player), const Offset(100, 0), 2000);
            await t.pump();
            attempts++;
          }
        } else {
          currentBlocked = 0;
        }
        await step(t, 40);
        final p = t.getCenter(player), m = t.getCenter(mate);
        maxStep = math.max(
            maxStep,
            math.max(
                (p - previousPlayer).distance, (m - previousMate).distance));
        previousPlayer = p;
        previousMate = m;
        expect(ball.evaluate().length, lessThanOrEqualTo(1));
        // Footer text refreshes on the 50ms clock; field visuals use the
        // authoritative frame clock. Check actual possession/flight here.
        if (visual(t, player).holding ||
            visual(t, mate).holding ||
            trail.evaluate().isNotEmpty ||
            find.byType(PassAndRunBallVisual).evaluate().isNotEmpty) {
          expect(ball, findsOneWidget);
        }
      }
      final label = t.widget<Text>(find.textContaining('PASS ')).data!;
      final score =
          int.parse(RegExp(r'PASS (\d+)').firstMatch(label)!.group(1)!);
      expect(attempts, greaterThan(1));
      expect(score, lessThan(attempts));
      expect(blocked, greaterThan(0));
      expect(legal, greaterThan(0));
      expect(longestBlocked, lessThan(15));
      expect(maxStep, lessThan(30)); // 40ms frame, comparable to <=12px at60Hz.
      // ignore: avoid_print
      print(
          'Widget horizontal seed=$seed score=$score/attempts=$attempts; legal=$legal blocked=$blocked longestHeldBlocked=${longestBlocked.toStringAsFixed(2)}s max40msMove=${maxStep.toStringAsFixed(2)}px');
    });
  }

  for (final outbound in [true, false]) {
    testWidgets('受球後だけ加速し合法返球を速やかに完了する $outbound', (t) async {
      await start(t, seed: 3);
      if (!outbound) {
        await step(t, 15000);
        await step(t, 1000);
      }
      await throwToMate(t, 0);
      for (var i = 0;
          i < 300 && find.textContaining('PASS 1').evaluate().isEmpty;
          i++) {
        await step(t, 4);
      }
      expect(find.textContaining('PASS 1'), findsOneWidget);
      final caughtAt = clock;
      Offset? release;
      var lastMateHolding = false;
      for (var i = 0; i < 225 && !visual(t, player).holding; i++) {
        lastMateHolding |= visual(t, mate).holding;
        await step(t, 8);
        if (lastMateHolding &&
            !visual(t, mate).holding &&
            trail.evaluate().isNotEmpty) {
          release ??= t.getCenter(ball);
        }
        if (release != null && trail.evaluate().isNotEmpty) {
          final dy = t.getCenter(ball).dy - release.dy;
          expect(outbound ? dy : -dy, greaterThanOrEqualTo(-.000001));
        }
        expect(ball, findsOneWidget);
      }
      expect(lastMateHolding, isTrue);
      expect(release, isNotNull);
      expect(visual(t, player).holding, isTrue);
      expect(visual(t, mate).holding, isFalse);
      expect(trail, findsNothing);
      // ignore: avoid_print
      print(
          'live Widget catch-to-return outbound=$outbound seed3: ${clock.difference(caughtAt).inMilliseconds}ms');
    });
  }

  testWidgets('受球→B保持→合法な返球→Normal保持。停止中は球・脚位相を固定', (t) async {
    await start(t, seed: 3);
    await step(t, 800);
    await throwToMate(t, .8);
    await catchAtMate(t);
    // This fixture tests holding/pause transitions, not a 2.4s return SLA.
    // Keep seed3 and the original 300x8ms assertion budget. Start input at
    // 0.8s, where a legal return can finish within that budget.
    final field = t.getRect(find.byKey(const Key('pass-field')));
    final caughtSeconds =
        clock.difference(DateTime.utc(2026, 10, 20)).inMicroseconds / 1000000;
    final speed =
        field.width * .5 / (currentSettings.ballHalfFieldTravelMs / 1000);
    var hasReturnWindow = false;
    // Match the live planner's constant-speed interception equation. Both
    // held-ball sprites share their offset on this outbound/back-facing run,
    // so the offsets cancel in the relative position.
    for (var tick = 12; tick <= 300; tick++) {
      final wait = tick * .008;
      final originY = fixtureMotion!.yAt(
              caughtSeconds + wait, PassRunRunner.companion,
              outbound: true) *
          field.height;
      Offset relativeTarget(double flight) => Offset(
          t.getCenter(player).dx - t.getCenter(mate).dx,
          fixtureMotion!.yAt(
                      caughtSeconds + wait + flight, PassRunRunner.player,
                      outbound: true) *
                  field.height -
              originY);
      var low = 0.0;
      var high = (field.width + field.height + 224) / speed;
      for (var i = 0; i < 32; i++) {
        final mid = (low + high) / 2;
        if (relativeTarget(mid).distance > speed * mid) {
          low = mid;
        } else {
          high = mid;
        }
      }
      if (wait + high <= 2.4 && relativeTarget(high).dy >= 0) {
        hasReturnWindow = true;
        break;
      }
    }
    expect(hasReturnWindow, isTrue, reason: '保持/停止検証用の入力時刻には2.4秒内の合法返球窓が必要');
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

  testWidgets('保持中の球はラウンド終了で持ち越さない', (t) async {
    await start(t, seed: 1);
    await throwToMate(t, 0);
    await catchAtMate(t);
    expect(visual(t, mate).holding, isTrue);
    expect(trail, findsNothing);
    await step(t, 15100);
    await step(t, 1000);
    expect(find.byKey(const Key('pass-attack-direction')), findsNothing);
    expect(visual(t, player).holding, isTrue);
    expect(visual(t, mate).holding, isFalse);
    expect(ball, findsOneWidget);
    await step(t, 15100);
    await step(t, 1000);
    expect(find.text('メインへ戻る'), findsOneWidget);
    expect(ball, findsNothing);
    expect(trail, findsNothing);
  });

  testWidgets('復路もBの合法受球・保持待機・後方返球で同じ攻撃方向を使う', (t) async {
    await start(t, seed: 4);
    await step(t, 15000);
    await step(t, 1000);
    await step(t, 200);
    await throwToMate(t, .2);
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

  for (final up in [true, false]) {
    testWidgets('合法な角度が見える場面で実フリックが捕球される $up', (t) async {
      await start(t, seed: 0);
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      await throwToMate(t, 0);
      await catchAtMate(t);
      expect(find.textContaining('PASS 1'), findsOneWidget);
      expect(ball, findsOneWidget);
    });
  }

  for (final ballMs in [350, 650]) {
    for (final field in [const Size(240, 568), const Size(402, 874)]) {
      for (final frames in [
        [8],
        [100],
        [17, 83, 41, 129]
      ]) {
        for (final outbound in [true, false]) {
          testWidgets(
              'sweep受球は球速端・狭幅・可変frameで一致 $ballMs $field $frames $outbound',
              (t) async {
            await t.binding.setSurfaceSize(field);
            await start(t,
                seed: 0,
                settings: PassRunSettings(ballHalfFieldTravelMs: ballMs));
            if (!outbound) {
              await step(t, 15000);
              await step(t, 1000);
            }
            await throwToMate(t, 0);
            var elapsed = 0;
            for (var i = 0;
                elapsed < 5000 &&
                    !(visual(t, player).holding || visual(t, mate).holding);
                i++) {
              final frame = frames[i % frames.length];
              elapsed += frame;
              await step(t, frame);
              expect(ball, findsOneWidget);
            }
            expect(find.textContaining('PASS 1'), findsOneWidget);
            // A successful catch may already have auto-returned; either
            // runner owns the single ball, never neither or both.
            expect(
              visual(t, player).holding != visual(t, mate).holding,
              isTrue,
            );

            // Test the deliberately-away horizontal flick in a fresh round;
            // the successful pass above may have consumed most of its timer.
            await t.pumpWidget(const SizedBox());
            await t.pump();
            await start(t,
                seed: 0,
                settings: PassRunSettings(ballHalfFieldTravelMs: ballMs));
            if (!outbound) {
              await step(t, 15000);
              await step(t, 1000);
            }
            expect(find.textContaining('PASS 0'), findsOneWidget);
            await t.flingFrom(
                t.getCenter(player), Offset(outbound ? -120 : 120, 0), 2000);
            await t.pump();
            for (var i = 0;
                i < 200 && find.textContaining('MISS').evaluate().isEmpty;
                i++) {
              await step(t, frames[i % frames.length]);
            }
            // 遠ざかる球はsweepでも誤って捕球しない。
            expect(find.textContaining('PASS 0'), findsOneWidget);
            expect(find.textContaining('MISS'), findsOneWidget);
            await t.pumpWidget(const SizedBox());
            await t.binding.setSurfaceSize(null);
          });
        }
      }
    }
  }

  for (final deadlineMs in [300, 700]) {
    testWidgets('期限越えtickは期限内のsweepだけ得点する $deadlineMs', (t) async {
      await start(t,
          seed: 2, settings: PassRunSettings(roundDurationMs: deadlineMs));
      await t.flingFrom(t.getCenter(player), aimAtMate(t, 0), 2000);
      await t.pump();
      await step(t, 800);
      expect(find.textContaining(deadlineMs == 700 ? 'PASS 1' : 'PASS 0'),
          findsOneWidget);
      expect(ball, findsOneWidget);
    });
  }

  for (final frameMs in [33, 50, 100]) {
    testWidgets('捕球後は低fpsでも球1個で返球し再入力できる $frameMs', (t) async {
      await start(t, seed: 3);
      await throwToMate(t, 0);
      for (var i = 0;
          i < 250 && find.textContaining('PASS 1').evaluate().isEmpty;
          i++) {
        await step(t, 4);
      }
      expect(find.textContaining('PASS 1'), findsOneWidget);
      for (var i = 0; i < 5000 ~/ frameMs; i++) {
        await step(t, frameMs);
        expect(ball, findsOneWidget);
        if (find.textContaining('PASS 1').evaluate().isNotEmpty &&
            visual(t, player).holding) {
          break;
        }
      }
      expect(find.textContaining('PASS 1'), findsOneWidget);
      expect(visual(t, player).holding, isTrue);
    });
  }

  testWidgets('返球期限後ticker前の停止でも再開後に次のパスが可能', (t) async {
    await start(t, seed: 3);
    await step(t, 200);
    await throwToMate(t, .2);
    await catchAtMate(t);
    for (var i = 0; i < 300 && trail.evaluate().isEmpty; i++) {
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
    const Size(402, 874),
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
      for (var i = 0; i < 619; i++) {
        await step(t, 50);
        final labelRect = t.getRect(find.byKey(const Key('pass-player-label')));
        expect(t.getRect(player).overlaps(t.getRect(mate)), isFalse,
            reason: 'body overlap at $i on $size');
        expect(labelRect.overlaps(t.getRect(mate)), isFalse,
            reason: 'name overlap at $i on $size');
        expect(labelRect.top, greaterThanOrEqualTo(field.top - .000001));
        expect(labelRect.bottom, lessThan(t.getRect(player).top));
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
