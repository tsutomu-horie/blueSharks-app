import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';

void main() {
  TackleAttempt success(int us) =>
      TackleAttempt(isCorrect: true, reaction: Duration(microseconds: us));
  const miss = TackleAttempt(isCorrect: false);
  List<TackleAttempt> successesWithTotal(int total) => [
        success(total ~/ 3),
        success(total ~/ 3),
        success(total - 2 * (total ~/ 3)),
      ];

  test('受付は片側0〜750msで、負数と1µs超過はMISS', () {
    expect(TackleRules.inputLimit, const Duration(milliseconds: 750));
    for (final us in [-1, 0, 749999, 750000, 750001]) {
      expect(success(us).isSuccess, us >= 0 && us <= 750000, reason: '$us µs');
    }
    expect(const TackleAttempt(isCorrect: true).rank, 'MISS');
    expect(
      const TackleAttempt(isCorrect: false, reaction: Duration.zero).rank,
      'MISS',
    );
  });

  test('MISSを750msとして全3回平均に含める', () {
    final attempts = [success(120000), miss, success(140000)];
    expect(TackleRules.overallRank(attempts), 'A');
    expect(TackleRules.averageReaction(attempts)?.inMicroseconds, 336666);
    expect(TackleRules.successCount(attempts), 2);
    expect(TackleRules.successfulReactionTotalUs(attempts), 260000);
    // 成功数によるランク上限は設けない。
    expect(TackleRules.overallRank([success(0), success(0), miss]), 'S');
    expect(TackleRules.overallRank([success(0), miss, miss]), 'B');
  });

  test('全MISSだけD、3回750ms成功は同じ平均でもC', () {
    final allMiss = [miss, miss, miss];
    final allLateSuccess = List.generate(3, (_) => success(750000));
    expect(TackleRules.overallRank(allMiss), 'D');
    expect(TackleRules.overallRank(allLateSuccess), 'C');
    expect(TackleRules.averageReaction(allMiss),
        const Duration(milliseconds: 750));
    expect(TackleRules.averageReaction(allLateSuccess),
        const Duration(milliseconds: 750));
  });

  for (final boundary in [
    (900000, 'S', 'A'),
    (1350000, 'A', 'B'),
    (1800000, 'B', 'C'),
  ]) {
    test('合計${boundary.$1}µsの境界±1µsを丸めず判定', () {
      for (final delta in [-1, 0, 1]) {
        expect(
          TackleRules.overallRank(successesWithTotal(boundary.$1 + delta)),
          delta <= 0 ? boundary.$2 : boundary.$3,
        );
      }
    });
  }

  test('不正な成功フラグもMISSペナルティに含める', () {
    for (final invalid in [
      success(-1),
      success(750001),
      const TackleAttempt(isCorrect: true)
    ]) {
      final attempts = [success(120000), invalid, success(140000)];
      expect(TackleRules.overallRank(attempts), 'A');
      expect(TackleRules.successCount(attempts), 2);
      expect(TackleRules.successfulReactionTotalUs(attempts), 260000);
    }
  });

  test('未完了や余分な結果を完成した3セットとして集計しない', () {
    for (final attempts in <List<TackleAttempt>>[
      [],
      [success(0)],
      [success(0), success(0)],
      List.generate(4, (_) => success(0)),
    ]) {
      expect(TackleRules.averageReaction(attempts), isNull);
      expect(TackleRules.overallRank(attempts), 'D');
    }
  });
}
