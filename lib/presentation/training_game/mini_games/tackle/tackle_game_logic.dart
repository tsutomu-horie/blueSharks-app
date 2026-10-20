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

  /// 正しい方向を0〜750msで入力した場合だけ成功です。
  bool get isSuccess =>
      isCorrect &&
      reaction != null &&
      !reaction!.isNegative &&
      reaction! <= TackleRules.inputLimit;

  /// セット単位のランクです。
  String get rank {
    if (!isSuccess) {
      return 'MISS';
    }
    final milliseconds = reaction!.inMilliseconds;
    if (milliseconds <= 150) return 'PERFECT';
    if (milliseconds <= 250) return 'GREAT';
    if (milliseconds <= 350) return 'GOOD';
    return 'OK';
  }
}

/// タックルの確定値とランク判定を集約します。
abstract final class TackleRules {
  /// 1プレイで実施するセット数です。
  static const setCount = 3;

  /// 踏み込み後に入力を受け付ける時間です。
  static const inputLimit = Duration(milliseconds: 750);

  /// 3セットの総合ランクです。MISSは750ms、全MISSだけDです。
  static String overallRank(List<TackleAttempt> attempts) {
    if (attempts.length != setCount || successCount(attempts) == 0) return 'D';
    final total = _judgedTotalMicroseconds(attempts);
    // 平均の丸めで境界をまたがないよう、整数の合計で比較します。
    if (total <= 300000 * setCount) return 'S';
    if (total <= 450000 * setCount) return 'A';
    if (total <= 600000 * setCount) return 'B';
    return 'C';
  }

  /// 制限時間内に正しい方向を入力した回数です。
  static int successCount(List<TackleAttempt> attempts) =>
      attempts.where((attempt) => attempt.isSuccess).length;

  /// APIでの再計算にも使う、成功した反応時間だけの整数合計です。
  static int successfulReactionTotalUs(List<TackleAttempt> attempts) =>
      attempts.where((attempt) => attempt.isSuccess).fold<int>(
            0,
            (sum, attempt) => sum + attempt.reaction!.inMicroseconds,
          );

  static int _judgedTotalMicroseconds(List<TackleAttempt> attempts) =>
      successfulReactionTotalUs(attempts) +
      (setCount - successCount(attempts)) * inputLimit.inMicroseconds;

  /// MISSを750msとして全3回に含めた判定平均です。
  static Duration? averageReaction(List<TackleAttempt> attempts) {
    if (attempts.length != setCount) return null;
    return Duration(
        microseconds: _judgedTotalMicroseconds(attempts) ~/ setCount);
  }
}
