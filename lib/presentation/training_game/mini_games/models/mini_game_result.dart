/// 育成画面へ返すミニゲームの種別です。
enum MiniGameType {
  tackle,
  passAndRun,
}

/// 育成画面へ返す型付きのミニゲーム結果です。
class MiniGameResult {
  /// ICCドリフトで調整中とされるタックルの暫定育成倍率です。
  ///
  /// 正式なスコア帯別加算値が決まるまで、Controllerはこの倍率を
  /// 内部傾向値と仕事加算の両方に適用します。
  static const tackleEffectMultipliers = <String, double>{
    'S': 1.25,
    'A': 1.0,
    'B': .75,
    'C': .5,
    'D': .25,
  };

  /// ミニゲーム結果を作成します。
  const MiniGameResult({
    required this.type,
    required this.summary,
    required this.score,
    required this.effectMultiplier,
    this.resultCode,
  });

  final MiniGameType type;

  /// 育成ログへ表示する結果の要約です。
  final String summary;

  /// API履歴への拡張時にも利用できるゲーム固有の数値スコアです。
  final double score;

  /// 内部傾向値と仕事加算へ適用する暫定倍率です。
  final double effectMultiplier;

  /// サーバーが倍率を再計算するための結果コードです。
  final String? resultCode;

  /// タックルの総合ランクから育成反映倍率を決定します。
  factory MiniGameResult.tackle({
    required String rank,
    required double? averageSeconds,
    required int successCount,
  }) {
    final averageLabel = averageSeconds == null
        ? '計測なし'
        : '${averageSeconds.toStringAsFixed(2)}秒';
    return MiniGameResult(
      type: MiniGameType.tackle,
      summary: 'タックル 総合$rank／平均$averageLabel／成功$successCount/3',
      score: averageSeconds ?? .5,
      effectMultiplier: tackleEffectMultipliers[rank] ?? .25,
      resultCode: rank,
    );
  }

  /// パス成功回数から育成反映倍率を決定します。
  factory MiniGameResult.passAndRun({
    required int outboundScore,
    required int inboundScore,
  }) {
    final total = outboundScore + inboundScore;
    return MiniGameResult(
      type: MiniGameType.passAndRun,
      summary: 'パス＆ラン 成功$total回（往路$outboundScore＋復路$inboundScore）',
      score: total.toDouble(),
      effectMultiplier: _passAndRunEffectMultiplier(total),
    );
  }

  /// パス＆ランの成功回数を、資料記載の暫定育成倍率へ変換します。
  static double _passAndRunEffectMultiplier(int total) {
    if (total >= 16) return 1.25;
    if (total >= 11) return 1.0;
    if (total >= 6) return .75;
    if (total >= 1) return .5;
    return .25;
  }
}
