/// サーバーが確認した、成長期開始の選択肢と置換対象です。
class TrainingDebugGrowthOptions {
  TrainingDebugGrowthOptions.fromJson(Map<String, dynamic> json) {
    final current = json['current_game'];
    final choices = json['branches'];
    if (current is! Map || choices is! List) throw StateError('開始条件を確認できません。');
    currentGame = Map<String, dynamic>.from(current);
    if (['id', 'cycle_no', 'lock_version']
            .any((key) => currentGame[key] is! int) ||
        currentGame['started_at'] is! String ||
        DateTime.tryParse(currentGame['started_at']) == null) {
      throw StateError('置き換える育成を確認できません。');
    }
    branches = Map.fromEntries(choices.map((choice) {
      if (choice is! Map ||
          !const ['FW', 'COMMAND', 'BACKS'].contains(choice['code']) ||
          choice['name'] is! String) {
        throw StateError('分岐の一覧を確認できません。');
      }
      return MapEntry(choice['code'] as String, choice['name'] as String);
    }));
    if (branches.isEmpty) throw StateError('利用できる分岐がありません。');
  }

  late final Map<String, dynamic> currentGame;
  late final Map<String, String> branches;

  Map<String, dynamic> request(String branch) {
    if (!branches.containsKey(branch)) throw StateError('分岐を選び直してください。');
    return {
      'branch_code': branch,
      'confirm_replace': true,
      'expected_player_id': currentGame['id'],
      'expected_cycle_no': currentGame['cycle_no'],
      'expected_lock_version': currentGame['lock_version'],
      'expected_started_at': currentGame['started_at'],
    };
  }
}
