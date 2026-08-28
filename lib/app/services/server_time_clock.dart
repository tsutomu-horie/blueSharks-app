/// サーバー時刻を基準に、通信間の現在時刻を推定する時計です。
///
/// サーバーから受け取った日時を基準にし、通信後の経過だけは端末の単調時計
/// で補間します。端末のカレンダー日時やタイムゾーンは参照しません。
class ServerTimeClock {
  ServerTimeClock._();

  static final ServerTimeClock instance = ServerTimeClock._();

  DateTime? _serverTimeAtSync;
  Stopwatch? _elapsedSinceSync;

  bool get isSynchronized => _serverTimeAtSync != null;

  /// APIレスポンスのサーバー時刻で基準を更新します。
  void synchronize(DateTime serverTime) {
    _serverTimeAtSync = serverTime;
    _elapsedSinceSync = Stopwatch()..start();
  }

  /// 最後に同期したサーバー時刻からの経過時間です。
  Duration get elapsedSinceSync => _elapsedSinceSync?.elapsed ?? Duration.zero;

  /// 現在のサーバー時刻です。
  ///
  /// ゲーム画面はサーバー状態の取得後に操作可能になるため、通常は同期済み
  /// です。未同期時は壁時計を使わず、単調時計を基準にした値を返します。
  DateTime get now => (_serverTimeAtSync ?? DateTime.utc(2000)).add(
        elapsedSinceSync,
      );
}
