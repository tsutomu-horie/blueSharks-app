/// 育成傾向からラグビーのポジションを判定します。
class TrainingGamePositionClassifier {
  /// 全傾向値を受け取り、判定不能時は「判定前」を返します。
  static String classify(Map<String, double> trends) {
    final forward = trends['FW'] ?? 0;
    final command = trends['CMD'] ?? 0;
    final run = trends['RUN'] ?? 0;
    final bulk = trends['BULK'] ?? 0;
    final tech = trends['TECH'] ?? 0;
    final main = {'FW': forward, 'CMD': command, 'RUN': run};
    final total = main.values.reduce((sum, value) => sum + value);

    // 主傾向が未成立の場合、補助傾向だけではポジションを確定できません。
    if (total == 0) return '判定前';

    final ordered = main.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final top = ordered.first.key;
    final second = ordered[1].key;
    final purity = ordered.first.value / total;
    final ratio = ordered.first.value == 0
        ? 0
        : ordered[1].value / ordered.first.value;
    final techBulk = bulk == 0 ? null : tech / bulk;
    final floor =
        main.values.reduce((first, second) => first < second ? first : second);

    if (purity < .5 && floor >= 30) return 'フルバック';
    if (top == 'FW' && second == 'RUN' && ratio >= .55) {
      return tech >= bulk ? 'フランカー' : 'ナンバーエイト';
    }
    // BULKが0の場合はTECH/BULKを作らず、比率を前提とする判定を通しません。
    if (top == 'FW' && techBulk != null && techBulk >= 1) return 'フッカー';
    if (top == 'FW' && techBulk != null && techBulk >= .35) return 'ロック';
    if (top == 'FW') return 'プロップ';
    if (top == 'CMD') return ratio >= .4 ? 'スクラムハーフ' : 'スタンドオフ';
    return second == 'FW' && ratio >= .55 ? 'センター' : 'ウイング';
  }
}
