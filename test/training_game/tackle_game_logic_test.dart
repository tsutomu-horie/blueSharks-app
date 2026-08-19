import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';

void main() {
  group('TackleRules', () {
    test('3回成功時は平均反応時間から総合ランクを返す', () {
      const attempts = [
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 180)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 220)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 250)),
      ];

      expect(TackleRules.overallRank(attempts), 'A');
      expect(TackleRules.averageReaction(attempts)?.inMilliseconds, 216);
    });

    test('MISSを1回でも含む場合は暫定仕様どおり総合Dになる', () {
      const attempts = [
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 120)),
        TackleAttempt(isCorrect: false, reaction: Duration(milliseconds: 200)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 140)),
      ];

      expect(TackleRules.overallRank(attempts), 'D');
    });

    test('入力猶予を超えた正解タップもMISSとして総合Dになる', () {
      const attempts = [
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 120)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 501)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 140)),
      ];

      expect(TackleRules.overallRank(attempts), 'D');
    });

    test('平均反応時間は成功したセットだけで算出する', () {
      const attempts = [
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 200)),
        TackleAttempt(isCorrect: false, reaction: Duration(milliseconds: 50)),
        TackleAttempt(isCorrect: true, reaction: Duration(milliseconds: 400)),
      ];

      expect(TackleRules.averageReaction(attempts)?.inMilliseconds, 300);
    });
  });
}
