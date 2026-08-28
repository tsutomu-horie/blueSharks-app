/// 端末のカレンダー変更に影響されない育成ゲーム用の単調時計です。
class TrainingGameClock {
  TrainingGameClock._();

  static final Stopwatch _stopwatch = Stopwatch()..start();

  /// プロセス起動後の単調経過時間をDateTime演算へ渡せる値として返します。
  static DateTime now() => DateTime.utc(2000).add(_stopwatch.elapsed);
}
