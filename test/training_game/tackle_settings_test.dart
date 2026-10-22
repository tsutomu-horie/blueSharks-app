import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';

void main() {
  const settings = TackleSettings(
    setCount: 2,
    inputLimitMs: 1000,
    perfectMaxMs: 100,
    greatMaxMs: 200,
    goodMaxMs: 300,
    overallSMaxMs: 200,
    overallAMaxMs: 400,
    overallBMaxMs: 600,
    snapshotToken: 'test-snapshot',
  );
  TackleAttempt success(int us) => TackleAttempt(
        isCorrect: true,
        reaction: Duration(microseconds: us),
        settings: settings,
      );

  test('custom input limit and millisecond rank boundaries are consumed', () {
    expect(success(1000999).isSuccess, isFalse);
    expect(success(1000000).isSuccess, isTrue);
    expect(success(100999).rank, 'PERFECT');
    expect(success(101000).rank, 'GREAT');
    expect(success(200999).rank, 'GREAT');
    expect(success(201000).rank, 'GOOD');
    expect(success(300999).rank, 'GOOD');
    expect(success(301000).rank, 'OK');
  });

  test('custom aggregate compares microseconds before average truncation', () {
    expect(
        TackleRules.overallRank([success(200000), success(200000)],
            settings: settings),
        'S');
    expect(
        TackleRules.overallRank([success(200000), success(200001)],
            settings: settings),
        'A');
    expect(
        TackleRules.averageReaction([success(200000), success(200001)],
                settings: settings)
            ?.inMicroseconds,
        200000);
  });

  test('custom miss penalty, set count and all miss rank are consumed', () {
    const miss = TackleAttempt(isCorrect: false, settings: settings);
    final attempts = [success(0), miss];
    expect(TackleRules.successCount(attempts, settings: settings), 1);
    expect(TackleRules.averageReaction(attempts, settings: settings),
        const Duration(milliseconds: 500));
    expect(TackleRules.overallRank(attempts, settings: settings), 'B');
    expect(TackleRules.overallRank([miss, miss], settings: settings), 'D');
    expect(TackleRules.averageReaction([miss], settings: settings), isNull);
  });
}
