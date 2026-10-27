import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'recording_training_game_sound.dart';

void main() {
  for (final c in [
    ('outside-move', 1, 80.0, 16, 1, false, false, false),
    ('field-outside-release', 1, 80.0, 16, 1, false, false, false),
    ('outside-release', 1, 80.0, 16, 1, false, false, false),
    ('outside-second', 1, 80.0, 16, 1, false, true, false),
    ('outside-second-first', 1, 80.0, 16, 1, false, true, false),
    ('waiting-overlay', 1, 80.0, 16, 1, false, false, false),
    ('paused-overlay', 1, 80.0, 16, 1, false, false, false),
    ('raw-two-sdk-gap', 2, 80.0, 98, 1, false, false, true),
    ('raw-three-sdk-gap', 3, 80.0, 99, 1, false, false, false),
    ('idle16', 1, 80.0, 16, 16, false, false, true),
    ('idle17', 1, 80.0, 16, 17, false, false, false),
    ('duration100', 1, 80.0, 99, 1, false, false, true),
    ('duration101', 1, 80.0, 100, 1, false, false, false),
    ('stationary', 2, 80.0, 80, 1, false, false, false),
    ('longpress', 1, 80.0, 516, 1, false, false, false),
    ('multi-three', 3, 80.0, 48, 1, false, true, false),
    ('small-screen', 1, 80.0, 16, 1, false, false, true),
    ('one-fast', 1, 80.0, 16, 1, false, false, true),
    ('two-fast', 2, 80.0, 32, 1, false, false, true),
    ('three-fast', 3, 80.0, 48, 1, false, false, true),
    ('one-slow', 1, 80.0, 400, 1, false, false, false),
    ('two-slow', 2, 80.0, 400, 1, false, false, false),
    ('three-slow', 3, 80.0, 400, 1, false, false, false),
    ('short20', 1, 20.0, 16, 1, false, false, false),
    ('stop50', 1, 80.0, 16, 50, false, false, false),
    ('hold500', 1, 80.0, 16, 500, false, false, false),
    ('cancel', 1, 80.0, 16, 1, true, false, false),
    ('multi', 1, 80.0, 16, 1, false, true, false),
  ]) {
    testWidgets(c.$1, (t) async {
      if (c.$1 == 'small-screen') {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
      }
      var clock = DateTime.utc(2026, 10, 26);
      final sound = RecordingTrainingGameSound();
      await t.pumpWidget(MaterialApp(
          home: PassAndRunGameScreen(
              now: () => clock, motionSeed: 54, soundService: sound.service)));
      final context = t.element(find.byType(PassAndRunGameScreen));
      await t.runAsync(() async {
        await Future.wait(PassAndRunCharacterVisual.assets
            .map((p) => precacheImage(AssetImage(p), context)));
      });
      await t.pump();
      if (c.$1 != 'waiting-overlay') {
        await t.tap(find.text('スタート'));
        await t.pump();
      }
      if (c.$1 == 'paused-overlay') {
        await t.tap(find.byTooltip('一時停止'));
        await t.pump();
      }
      final field = t.getRect(find.byKey(const Key('pass-field')));
      final start = c.$1 == 'outside-move'
          ? Offset(field.right - 40, field.center.dy)
          : field.center;
      final g = await t.createGesture(pointer: 1);
      final second = await t.createGesture(pointer: 2);
      final secondPosition = c.$1.startsWith('outside-second')
          ? Offset(field.center.dx, field.top - 10)
          : start + const Offset(0, 20);
      if (c.$1 == 'outside-second-first') {
        await second.down(secondPosition, timeStamp: Duration.zero);
      }
      await g.down(start, timeStamp: Duration.zero);
      if (c.$7 && c.$1 != 'outside-second-first') {
        await second.down(secondPosition,
            timeStamp: const Duration(milliseconds: 1));
      }
      for (var i = 1; i <= c.$2; i++) {
        await g.moveTo(
            start + Offset(c.$1 == 'stationary' ? c.$3 : c.$3 * i / c.$2, 0),
            timeStamp: Duration(
                microseconds: c.$1 == 'raw-three-sdk-gap'
                    ? [1000, 50000, 99000][i - 1]
                    : (c.$4 * 1000 * i / c.$2).round()));
      }
      if (c.$1.endsWith('release')) {
        await t.sendEventToBinding(PointerUpEvent(
            pointer: 1,
            position: Offset(
                c.$1 == 'outside-release'
                    ? t.view.physicalSize.width / t.view.devicePixelRatio + 1
                    : field.right + 1,
                field.center.dy),
            timeStamp: const Duration(milliseconds: 17)));
      } else if (c.$6) {
        await g.cancel(timeStamp: Duration(milliseconds: c.$4 + c.$5));
      } else {
        await g.up(timeStamp: Duration(milliseconds: c.$4 + c.$5));
      }
      if (c.$7) {
        await second.up(timeStamp: Duration(milliseconds: c.$4 + c.$5 + 1));
      }
      await t.pump();
      expect(find.byKey(const Key('pass-ball-trail')),
          c.$8 ? findsOneWidget : findsNothing,
          reason: c.$1);
      if (c.$1 == 'waiting-overlay') {
        await t.tap(find.text('スタート'));
        await t.pump();
      }
      if (c.$1 == 'paused-overlay') {
        await t.tap(find.text('再開'));
        await t.pump();
      }
      if (c.$6 || c.$7 || c.$1.endsWith('overlay')) {
        final next = await t.createGesture(pointer: 3);
        await next.down(start, timeStamp: const Duration(seconds: 1));
        await next.moveTo(start + const Offset(80, 0),
            timeStamp: const Duration(milliseconds: 1016));
        await next.up(timeStamp: const Duration(milliseconds: 1017));
        await t.pump();
        expect(find.byKey(const Key('pass-ball-trail')), findsOneWidget,
            reason: 'next gesture recovers');
      }
      await t.pumpWidget(const SizedBox.shrink());
      await sound.dispose();
    });
  }
}
