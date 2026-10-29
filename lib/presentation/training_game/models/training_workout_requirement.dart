/// 筋トレ前に必要なメーターと、不足時に整える行動を管理します。
abstract final class TrainingWorkoutRequirement {
  static const minimumValue = 50;

  static const _recoveryActionByMeter = <String, String>{
    '食事': 'ごはん',
    '清潔': '掃除',
    '体調': '休養',
  };

  /// HOMEと同じ四捨五入後の表示値が50未満のメーターを返します。
  static List<String> missingMeters(Map<String, double> meters) =>
      _recoveryActionByMeter.keys
          .where((name) => (meters[name] ?? 0).round() < minimumValue)
          .toList(growable: false);

  /// 筋トレを始められる状態かを返します。
  static bool isMet(Map<String, double> meters) =>
      missingMeters(meters).isEmpty;

  /// 筋トレできない理由と、必要な回復行動を短く返します。
  static String? messageFor(Map<String, double> meters) {
    final missing = missingMeters(meters);
    if (missing.isEmpty) return null;

    final names = missing.join('・');
    final actions =
        missing.map((name) => _recoveryActionByMeter[name]!).join('・');
    return '$namesが$minimumValue未満です。'
        '$actionsで$minimumValue以上に整えてから筋トレしましょう。';
  }
}
