/// タックルで相手が実際に移動する方向です。
enum TackleDirection {
  up,
  down,
}

/// タックル1セットの判定結果です。
class TackleAttempt {
  /// 1セット分の結果を作成します。
  const TackleAttempt({
    required this.isCorrect,
    this.reaction,
  });

  /// 正しい方向を制限時間内にタップできたかを示します。
  final bool isCorrect;

  /// 踏み込み開始からタップまでの時間です。
  final Duration? reaction;

  /// 資料の暫定しきい値に従ったセット単位のランクです。
  String get rank {
    if (!isCorrect || reaction == null || reaction! > TackleRules.inputLimit) {
      return 'MISS';
    }
    final milliseconds = reaction!.inMilliseconds;
    if (milliseconds <= 150) return 'PERFECT';
    if (milliseconds <= 250) return 'GREAT';
    if (milliseconds <= 350) return 'GOOD';
    return 'OK';
  }
}

/// タックルの確定値と暫定ランク判定を集約します。
abstract final class TackleRules {
  /// 1プレイで実施するセット数です。
  static const setCount = 3;

  /// 踏み込み後に入力を受け付ける時間です。
  static const inputLimit = Duration(milliseconds: 500);

  /// 3セットの総合ランクを返します。
  static String overallRank(List<TackleAttempt> attempts) {
    // MISSの最終扱いは未確定のため、資料にある厳しい暫定案を採用します。
    if (attempts.length < setCount ||
        attempts.any((attempt) => attempt.rank == 'MISS')) {
      return 'D';
    }
    final average = averageReaction(attempts);
    if (average == null) return 'D';
    if (average.inMilliseconds <= 200) return 'S';
    if (average.inMilliseconds <= 300) return 'A';
    if (average.inMilliseconds <= 400) return 'B';
    if (average.inMilliseconds <= 500) return 'C';
    return 'D';
  }

  /// 成功した3セットの平均反応時間を返します。
  static Duration? averageReaction(List<TackleAttempt> attempts) {
    final successes = attempts
        .where((attempt) => attempt.isCorrect && attempt.reaction != null)
        .toList();
    if (successes.isEmpty) return null;
    final total = successes.fold<int>(
      0,
      (sum, attempt) => sum + attempt.reaction!.inMicroseconds,
    );
    return Duration(microseconds: total ~/ successes.length);
  }
}
