import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_direction_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
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
    await t.pump();
    await t.tap(find.text('スタート'));
    await t.pump();
    // Rendering a cached frame must not advance the authoritative test clock.
  }

  Offset aimAtMate(WidgetTester t, double seconds) {
    final field = t.getRect(find.byKey(const Key('pass-field')));
    final origin = t.getCenter(ball);
    final speed = field.width *
        .5 /
        (PassAndRunRules.standardPassDuration.inMicroseconds / 1000000);
    var travel = .44;
    var target = Offset.zero;
    for (var i = 0; i < 24; i++) {
      target = Offset(
          t.getCenter(mate).dx,
          field.top +
              field.height *
                  PassRunMotion.yAt(seconds + travel, PassRunRunner.companion,
                      outbound: find.text('攻撃方向 ↑').evaluate().isNotEmpty));
      travel = (target - origin).distance / speed;
    }
    return target - origin;
  }

  Future<void> throwToMate(WidgetTester t, double seconds) async {
    await t.flingFrom(t.getCenter(player), aimAtMate(t, seconds), 2000);
    await t.pump();
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
    await start(t);
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
      await start(t);
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
      await step(t, 120);
      check();
      expect(visual(t, mate).frame, isNot(initial));
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await start(t);
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      await throwToMate(t, 0);
      await catchAtMate(t);
      check();
      final held = visual(t, mate).frame;
      await step(t, 120);
      check();
      expect(visual(t, mate).holding, isTrue);
      expect(visual(t, mate).frame, isNot(held));
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
    await step(t, 120);
    expect(visual(t, player).assetPath, contains('normal_back_hold_b'));
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
    await start(t);
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
      await t.flingFrom(t.getCenter(player), const Offset(100, -1), 2000);
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
    expect(find.text('攻撃方向 ↓'), findsOneWidget);
    await step(t, 80);
    expect(visual(t, player).facing, PassRunFacing.front);
    expect(visual(t, mate).facing, PassRunFacing.front);
    await t.flingFrom(t.getCenter(player), const Offset(-100, 1), 2000);
    await t.pump();
    expect(find.text('前方パス　1秒間パス不可'), findsOneWidget);
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
    await step(t, 2800);
    await throwToMate(t, 2.8);
    await catchAtMate(t);
    await step(t, 160);
    expect(visual(t, mate).holding, isTrue);
    expect(trail, findsNothing);
    await step(t, 15100);
    await step(t, 1000);
    expect(find.text('攻撃方向 ↓'), findsOneWidget);
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
    await start(t);
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
    testWidgets('実フリックと衝突で3回連続パスでき、返球後に再入力できる $up', (t) async {
      await start(t);
      if (!up) {
        await step(t, 15000);
        await step(t, 1000);
      }
      final begin = clock;
      for (var n = 1; n <= 3; n++) {
        var attempts = 0;
        while (true) {
          final seconds = clock.difference(begin).inMicroseconds / 1000000;
          final delta = aimAtMate(t, seconds);
          if (!PassAndRunRules.isForwardDirection(
              deltaX: delta.dx, deltaY: delta.dy, outbound: up)) break;
          expect(attempts++, lessThan(300));
          await step(t, 10);
        }
        final before = clock;
        await throwToMate(t, clock.difference(begin).inMicroseconds / 1000000);
        for (var i = 0; i < 250 && !visual(t, mate).holding; i++) {
          await step(t, 4);
          expect(ball, findsOneWidget);
        }
        expect(visual(t, mate).holding, isTrue);
        expect(find.textContaining('PASS $n'), findsOneWidget);
        for (var i = 0; i < 1000 && !visual(t, player).holding; i++) {
          await step(t, 4);
          expect(ball, findsOneWidget);
        }
        expect(visual(t, player).holding, isTrue);
        expect(clock.difference(before), lessThan(const Duration(seconds: 4)));
      }
      expect(clock.difference(begin), lessThan(const Duration(seconds: 15)));
    });
  }

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
