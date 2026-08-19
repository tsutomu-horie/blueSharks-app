import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';

void main() {
  group('MiniGameResult', () {
    test('タックルの総合ランクを暫定育成倍率へ変換する', () {
      final result = MiniGameResult.tackle(
        rank: 'B',
        averageSeconds: .35,
        successCount: 3,
      );

      expect(result.type, MiniGameType.tackle);
      expect(result.effectMultiplier, .75);
      expect(result.summary, contains('総合B'));
    });

    test('パス成功回数を暫定育成倍率へ変換する', () {
      final result = MiniGameResult.passAndRun(
        outboundScore: 6,
        inboundScore: 6,
      );

      expect(result.type, MiniGameType.passAndRun);
      expect(result.score, 12);
      expect(result.effectMultiplier, 1);
    });

    test('成功0回でも完走分の最小倍率を返す', () {
      final result = MiniGameResult.passAndRun(
        outboundScore: 0,
        inboundScore: 0,
      );

      expect(result.effectMultiplier, .25);
    });
  });
}
