import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';

void main() {
  group('MiniGameResult', () {
    test('タックルの総合ランクを暫定育成倍率へ変換する', () {
      final result = MiniGameResult.tackle(
        successCount: 3,
        successfulReactionTotalUs: 1650000,
      );

      expect(result.type, MiniGameType.tackle);
      expect(result.effectMultiplier, .75);
      expect(result.resultCode, 'B');
      expect(result.summary, contains('総合B'));
    });

    test('v2 metadata keeps penalized mean and zero-success result', () {
      final result =
          MiniGameResult.tackle(successCount: 0, successfulReactionTotalUs: 0);
      expect(result.score, .75);
      expect(result.summary, contains('判定平均0.75秒'));
      expect(result.tackleResult!.toJson(), {
        'result_policy': 'tackle_v2_750_penalty_mean',
        'attempt_count': 3,
        'success_count': 0,
        'successful_reaction_total_us': 0,
      });
      final partialSuccess = MiniGameResult.tackle(
          successCount: 2, successfulReactionTotalUs: 400000);
      expect(partialSuccess.score, closeTo(1.15 / 3, .000000001));
      expect(
          TackleResultMetadata.fromJson(partialSuccess.tackleResult!.toJson())!
              .successfulReactionTotalUs,
          400000);
    });
    test('legacy constructors have no metadata and preserve their score', () {
      const result = MiniGameResult(
          type: MiniGameType.tackle,
          summary: 'legacy',
          score: .5,
          effectMultiplier: .25,
          resultCode: 'D');
      expect(result.tackleResult, isNull);
      expect(TackleResultMetadata.fromJson({'score': .5}), isNull);
    });
    test('partial or malformed metadata never becomes legacy', () {
      final valid = TackleResultMetadata(
              successCount: 2, successfulReactionTotalUs: 400000)
          .toJson();
      for (final key in valid.keys) {
        final partial = Map<String, dynamic>.of(valid)..remove(key);
        expect(() => TackleResultMetadata.fromJson(partial),
            throwsFormatException);
      }
      for (final invalid in [
        {...valid, 'result_policy': 'other'},
        {...valid, 'attempt_count': 2},
        {...valid, 'success_count': 2.5},
        {...valid, 'success_count': 4},
        {...valid, 'successful_reaction_total_us': 1500001},
        {...valid, 'success_count': 0, 'successful_reaction_total_us': 1},
      ]) {
        expect(() => TackleResultMetadata.fromJson(invalid),
            throwsFormatException);
      }
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
