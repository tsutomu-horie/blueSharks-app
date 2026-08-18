/// 育成ゲームで実行できる行動の種類です。
enum TrainingActionType {
  meal,
  clean,
  rest,
  squat,
  tackle,
  passAndRun,
  work,
}

/// 画面に表示する育成行動の定義です。
class TrainingActionDefinition {
  /// 行動定義を作成します。
  const TrainingActionDefinition({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
  });

  final TrainingActionType type;
  final String label;
  final String description;
  final String icon;
}

/// 育成ゲームの段階定義です。
class TrainingStageDefinition {
  /// 段階定義を作成します。
  const TrainingStageDefinition({
    required this.name,
    required this.description,
    required this.unlockHours,
    this.days,
  });

  final String name;
  final String description;
  final int unlockHours;
  final int? days;
}
