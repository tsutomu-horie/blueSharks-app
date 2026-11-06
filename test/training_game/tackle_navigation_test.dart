import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';

import 'recording_training_game_sound.dart';
import 'tackle_test_driver.dart';

void main() {
  for (final afterFeedback in [false, true]) {
    testWidgets('1セット目のMISS${afterFeedback ? '表示後' : '演出中'}に戻る矢印1回で育成ホームへ戻る',
        (tester) async {
      final sounds = RecordingTrainingGameSound();
      addTearDown(sounds.dispose);
      var returned = false;
      MiniGameResult? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<MiniGameResult>(
                  MaterialPageRoute(
                    builder: (_) => TackleGameScreen(
                      soundService: sounds.service,
                      feedbackSoundFactory: silentTrainingGameSound,
                      random: FixedTackleRandom(
                          hasFeint: false, downward: true, approachMs: 1350),
                    ),
                  ),
                );
                returned = true;
              },
              child: const Text('育成ホーム：練習 / MG'),
            );
          }),
        ),
      ));
      await tester.tap(find.text('育成ホーム：練習 / MG'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('スタート'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1350));
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump();
      await tester.pump(Duration(milliseconds: afterFeedback ? 650 : 100));
      expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
      expect(find.text('SET 1 / 3'), findsOneWidget);
      expect(find.byType(BackButton).hitTestable(), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('育成ホーム：練習 / MG'), findsOneWidget);
      expect(find.byType(TackleGameScreen), findsNothing);
      expect(returned, isTrue);
      expect(result, isNull, reason: '中断は完了結果を返さない');
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }
}
