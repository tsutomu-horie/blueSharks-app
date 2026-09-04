import 'training_game_models.dart';

/// 育成アクションの実行可否を管理します。
///
/// サーバーが返すクールタイムとデバッグ用の解除設定を分離して扱います。
/// 送信中の行動も別途ロックし、レスポンス前の連打が同じアクションを
/// 同期キューへ積み続けないようにします。
class TrainingActionGate {
  TrainingActionGate({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final _clientCooldownUntil = <TrainingActionType, DateTime>{};
  final _serverCooldownUntil = <TrainingActionType, DateTime>{};
  final _pendingActions = <TrainingActionType>{};

  /// サーバーのクールタイムまたは送信中状態を含めて実行可否を返します。
  bool canPerform(
    TrainingActionType type, {
    required bool clientCooldownEnabled,
    bool bypassServerCooldown = false,
  }) {
    if (_pendingActions.contains(type)) return false;
    final until = _effectiveUntil(
      type,
      clientCooldownEnabled,
      bypassServerCooldown: bypassServerCooldown,
    );
    return until == null || !_now().isBefore(until);
  }

  /// 表示すべきクールタイムの残り時間を返します。
  Duration remaining(
    TrainingActionType type, {
    required bool clientCooldownEnabled,
    bool bypassServerCooldown = false,
  }) {
    final until = _effectiveUntil(
      type,
      clientCooldownEnabled,
      bypassServerCooldown: bypassServerCooldown,
    );
    if (until == null) return Duration.zero;
    final value = until.difference(_now());
    return value.isNegative ? Duration.zero : value;
  }

  /// 行動の送信を開始したことを記録します。
  bool markPending(TrainingActionType type) => _pendingActions.add(type);

  /// 行動の送信完了を記録します。
  void clearPending(TrainingActionType type) => _pendingActions.remove(type);

  /// デバッグ用の端末側クールタイム設定を変更します。
  void setClientCooldownEnabled(TrainingActionType type, bool enabled) {
    if (!enabled) _clientCooldownUntil.remove(type);
  }

  /// 端末側クールタイムを開始します。
  void startClientCooldown(
    TrainingActionType type, {
    required bool enabled,
    required Duration duration,
  }) {
    if (enabled) _clientCooldownUntil[type] = _now().add(duration);
  }

  /// サーバーが返したクールタイムを置き換えます。
  void replaceServerCooldowns(
    Map<TrainingActionType, DateTime> cooldowns, {
    Map<TrainingActionType, DateTime> preserveUntil = const {},
  }) {
    _serverCooldownUntil
      ..clear()
      ..addAll(cooldowns);
    for (final entry in preserveUntil.entries) {
      final current = _serverCooldownUntil[entry.key];
      if (_now().isBefore(entry.value) &&
          (current == null || current.isBefore(entry.value))) {
        _serverCooldownUntil[entry.key] = entry.value;
      }
    }
  }

  /// ローカルスナップショットに保存されたクールタイムを追加します。
  void mergeServerCooldowns(Map<TrainingActionType, DateTime> cooldowns) {
    for (final entry in cooldowns.entries) {
      final current = _serverCooldownUntil[entry.key];
      if (_now().isBefore(entry.value) &&
          (current == null || current.isBefore(entry.value))) {
        _serverCooldownUntil[entry.key] = entry.value;
      }
    }
  }

  /// 現在有効なクールタイムをスナップショットへ保存します。
  Map<TrainingActionType, DateTime> snapshot(
    Map<TrainingActionType, bool> clientCooldownEnabled,
  ) {
    final snapshot = <TrainingActionType, DateTime>{};
    for (final type in TrainingActionType.values) {
      final until = _effectiveUntil(type, clientCooldownEnabled[type] ?? false);
      if (until != null && _now().isBefore(until)) snapshot[type] = until;
    }
    return snapshot;
  }

  /// 新しい育成サイクルの開始時に状態を破棄します。
  void clear() {
    _clientCooldownUntil.clear();
    _serverCooldownUntil.clear();
    _pendingActions.clear();
  }

  DateTime? _effectiveUntil(
    TrainingActionType type,
    bool clientCooldownEnabled, {
    bool bypassServerCooldown = false,
  }) {
    final serverUntil =
        bypassServerCooldown ? null : _serverCooldownUntil[type];
    final clientUntil =
        clientCooldownEnabled ? _clientCooldownUntil[type] : null;
    if (serverUntil == null) return clientUntil;
    if (clientUntil == null || serverUntil.isAfter(clientUntil)) {
      return serverUntil;
    }
    return clientUntil;
  }
}
