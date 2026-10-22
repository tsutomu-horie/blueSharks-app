import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';

void main() {
  testWidgets('設定した片道時間と合計時間を表示し、画面存続中は設定を固定する', (tester) async {
    const key = ValueKey('configured-pass-run');
    await tester.pumpWidget(const MaterialApp(
      home: PassAndRunGameScreen(
        key: key,
        motionSeed: 54,
        settings: PassRunSettings(roundDurationMs: 12500),
      ),
    ));
    expect(find.textContaining('12.5秒 × 往復2セット'), findsNWidgets(2));
    expect(find.textContaining('合計25秒'), findsOneWidget);
    expect(find.textContaining('残り 12.5s'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: PassAndRunGameScreen(
        key: key,
        motionSeed: 54,
        settings: PassRunSettings(roundDurationMs: 30000),
      ),
    ));
    expect(find.textContaining('12.5秒 × 往復2セット'), findsNWidgets(2));
    expect(find.textContaining('合計25秒'), findsOneWidget);
    expect(find.textContaining('残り 12.5s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
