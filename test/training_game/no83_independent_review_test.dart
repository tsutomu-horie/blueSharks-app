import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_character_visual.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';

void main() {
  for (final pass in [false, true]) {
    testWidgets(
        '${pass ? 'pass' : 'tackle'} retained callback and resume guard',
        (t) async {
      var now = DateTime.utc(2026, 10, 26);
      final nav = GlobalKey<NavigatorState>();
      var completions = 0;
      MiniGameResult? result;
      await t.pumpWidget(MaterialApp(
          navigatorKey: nav, home: const Scaffold(body: Text('root'))));
      final game = pass
          ? PassAndRunGameScreen(now: () => now)
          : const TackleGameScreen(
              settings: TackleSettings(
                  setCount: 1, snapshotToken: 'mock-review-token'));
      final future = nav.currentState!
          .push<MiniGameResult>(MaterialPageRoute(builder: (_) => game));
      future.then((value) {
        completions++;
        result = value;
      });
      await t.pumpAndSettle();
      if (pass) {
        final context = t.element(find.byType(PassAndRunGameScreen));
        await t.runAsync(() async {
          for (final path in PassAndRunCharacterVisual.assets) {
            await precacheImage(AssetImage(path), context);
          }
        });
        await t.pump();
      }
      await t.tap(find.text('スタート'));
      await t.pump();
      if (pass) {
        now = now.add(const Duration(milliseconds: 15100));
        await t.pump(const Duration(milliseconds: 15100));
        now = now.add(const Duration(milliseconds: 16100));
        await t.pump(const Duration(milliseconds: 16100));
      } else {
        await t.tap(find.text('上をタップ ▲'));
        await t.pump(const Duration(milliseconds: 650));
        await t.tap(find.text('SET 1 / 1'));
        await t.pump();
      }
      final button = find.widgetWithText(ElevatedButton, 'メインへ戻る');
      expect(button, findsOneWidget);
      final confirm = t.widget<ElevatedButton>(button).onPressed!;
      final cover = MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('cover')));
      nav.currentState!.push(cover);
      await t.pumpAndSettle();
      confirm();
      await t.pump();
      expect(find.text('cover'), findsOneWidget);
      expect(completions, 0);
      nav.currentState!.pop();
      await t.pumpAndSettle();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      t.element(find.byWidget(game)).markNeedsBuild();
      await t.pump();
      final fades = find.descendant(
          of: find.byKey(const Key('mini-game-result-transition-switcher')),
          matching: find.byType(FadeTransition));
      expect(t.widgetList<FadeTransition>(fades).last.opacity.value, 1);
      // Existing transition unit test covers first-frame hit testing.

      await t.tap(button);
      confirm();
      confirm();
      await t.pump();
      expect(completions, 1);
      expect(result, isNotNull);
      await t.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
      expect(nav.currentState!.canPop(), isFalse);
      expect(t.takeException(), isNull);
    });
  }
}
