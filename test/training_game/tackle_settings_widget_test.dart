import 'recording_training_game_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';

import 'tackle_test_driver.dart';

void main() {
  for (final limitMs in [400, 2000]) {
    testWidgets('input limit $limitMs is shown in seconds', (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(MaterialApp(
        home: TackleGameScreen(
          feedbackSoundFactory: silentTrainingGameSound,
          settings: TackleSettings(inputLimitMs: limitMs),
        ),
      ));
      expect(find.text('判定猶予 ${limitMs / 1000}秒'), findsOneWidget);
      expect(find.text('判定猶予 0.75秒'), findsNothing);
    });
  }

  testWidgets('widget replacement keeps initial settings and timeout',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final random = FixedTackleRandom(
      hasFeint: false,
      downward: true,
      approachMs: 1100,
    );
    Widget screen(TackleSettings settings) => MaterialApp(
          home: TackleGameScreen(
            feedbackSoundFactory: silentTrainingGameSound,
            key: const Key('settings-session'),
            random: random,
            settings: settings,
          ),
        );
    await tester.pumpWidget(screen(const TackleSettings(
      setCount: 2,
      inputLimitMs: 400,
    )));
    await tester.tap(find.text('スタート'));
    await tester.pump();
    await tester.pumpWidget(screen(const TackleSettings(
      setCount: 5,
      inputLimitMs: 2000,
    )));
    expect(find.text('SET 1 / 2'), findsOneWidget);
    expect(find.text('判定猶予 0.4秒'), findsOneWidget);
    expect(find.text('SET 1 / 5'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byKey(const Key('tackle-input-cue')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 399));
    expect(find.byKey(const Key('tackle-feedback-miss')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('tackle-feedback-miss')), findsOneWidget);
  });
}
