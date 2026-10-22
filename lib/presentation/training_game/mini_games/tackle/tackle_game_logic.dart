import '../../models/mini_game_settings.dart';

/// タックルで相手が実際に移動する方向です。
enum TackleDirection { up, down }

/// タックル1セットの判定結果です。
class TackleAttempt {
  /// 1セット分の結果を作成します。
  const TackleAttempt({
    required this.isCorrect,
    this.reaction,
    this.settings = const TackleSettings(),
  });

  /// 正しい方向を制限時間内にタップできたかを示します。
  final bool isCorrect;

  /// 踏み込み開始からタップまでの時間です。
  final Duration? reaction;

  final TackleSettings settings;

  /// 正しい方向を設定された制限時間内に入力した場合だけ成功です。
  bool get isSuccess =>
      isCorrect &&
      reaction != null &&
      !reaction!.isNegative &&
      reaction! <= settings.inputLimit;

  /// セット単位のランクです。
  String get rank {
    if (!isSuccess) {
      return 'MISS';
    }
    final milliseconds = reaction!.inMilliseconds;
    if (milliseconds <= settings.perfectMaxMs) return 'PERFECT';
    if (milliseconds <= settings.greatMaxMs) return 'GREAT';
    if (milliseconds <= settings.goodMaxMs) return 'GOOD';
    return 'OK';
  }
}

/// タックルの確定値とランク判定を集約します。
abstract final class TackleRules {
  /// 1プレイで実施するセット数です。
  static const setCount = 3;

  /// 踏み込み後に入力を受け付ける時間です。
  static const inputLimit = Duration(milliseconds: 750);

  /// MISSを入力制限時間として含め、全MISSだけDとする総合ランクです。
  static String overallRank(
    List<TackleAttempt> attempts, {
    TackleSettings settings = const TackleSettings(),
  }) {
    if (attempts.length != settings.setCount ||
        successCount(attempts, settings: settings) == 0) {
      return 'D';
    }
    final total = _judgedTotalMicroseconds(attempts, settings);
    // 平均の丸めで境界をまたがないよう、整数の合計で比較します。
    if (total <= settings.overallSMaxMs * 1000 * settings.setCount) return 'S';
    if (total <= settings.overallAMaxMs * 1000 * settings.setCount) return 'A';
    if (total <= settings.overallBMaxMs * 1000 * settings.setCount) return 'B';
    return 'C';
  }

  static bool _isSuccess(TackleAttempt attempt, TackleSettings settings) =>
      attempt.isCorrect &&
      attempt.reaction != null &&
      !attempt.reaction!.isNegative &&
      attempt.reaction! <= settings.inputLimit;

  /// 制限時間内に正しい方向を入力した回数です。
  static int successCount(
    List<TackleAttempt> attempts, {
    TackleSettings settings = const TackleSettings(),
  }) =>
      attempts.where((attempt) => _isSuccess(attempt, settings)).length;

  /// APIでの再計算にも使う、成功した反応時間だけの整数合計です。
  static int successfulReactionTotalUs(
    List<TackleAttempt> attempts, {
    TackleSettings settings = const TackleSettings(),
  }) =>
      attempts.where((attempt) => _isSuccess(attempt, settings)).fold<int>(
          0, (sum, attempt) => sum + attempt.reaction!.inMicroseconds);

  static int _judgedTotalMicroseconds(
    List<TackleAttempt> attempts,
    TackleSettings settings,
  ) =>
      successfulReactionTotalUs(attempts, settings: settings) +
      (settings.setCount - successCount(attempts, settings: settings)) *
          settings.inputLimit.inMicroseconds;

  /// MISSを入力制限時間として全セットに含めた判定平均です。
  static Duration? averageReaction(
    List<TackleAttempt> attempts, {
    TackleSettings settings = const TackleSettings(),
  }) {
    if (attempts.length != settings.setCount) return null;
    return Duration(
      microseconds:
          _judgedTotalMicroseconds(attempts, settings) ~/ settings.setCount,
    );
  }
}
