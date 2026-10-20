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
    this.tackleResult,
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

  /// 新方針の結果だけが持つ、再送時にも保持する判定根拠です。
  final TackleResultMetadata? tackleResult;

  /// タックルの総合ランクから育成反映倍率を決定します。
  factory MiniGameResult.tackle({
    required int successCount,
    required int successfulReactionTotalUs,
  }) {
    final metadata = TackleResultMetadata(
      successCount: successCount,
      successfulReactionTotalUs: successfulReactionTotalUs,
    );
    final rank = metadata.rank;
    final penaltyMean = metadata.penaltyMeanSeconds;
    final averageLabel = '${penaltyMean.toStringAsFixed(2)}秒';
    return MiniGameResult(
      type: MiniGameType.tackle,
      summary: 'タックル 総合$rank／判定平均$averageLabel／成功$successCount/3',
      score: penaltyMean,
      effectMultiplier: metadata.effectMultiplier,
      resultCode: rank,
      tackleResult: metadata,
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

/// 承認済み750ms・MISS加算平均方針の送信/永続化データです。
class TackleResultMetadata {
  static const policy = 'tackle_v2_750_penalty_mean';
  const TackleResultMetadata._(
      this.successCount, this.successfulReactionTotalUs);
  factory TackleResultMetadata(
      {required int successCount, required int successfulReactionTotalUs}) {
    if (successCount < 0 ||
        successCount > 3 ||
        successfulReactionTotalUs < 0 ||
        successfulReactionTotalUs > successCount * 750000) {
      throw ArgumentError('Invalid tackle result metadata');
    }
    return TackleResultMetadata._(successCount, successfulReactionTotalUs);
  }
  final int successCount;
  final int successfulReactionTotalUs;
  String get resultPolicy => policy;
  int get attemptCount => 3;
  int get penalizedTotalUs =>
      successfulReactionTotalUs + (3 - successCount) * 750000;
  double get penaltyMeanSeconds => penalizedTotalUs / 3000000;
  String get rank {
    if (successCount == 0) return 'D';
    if (penalizedTotalUs <= 900000) return 'S';
    if (penalizedTotalUs <= 1350000) return 'A';
    if (penalizedTotalUs <= 1800000) return 'B';
    return 'C';
  }

  double get effectMultiplier => MiniGameResult.tackleEffectMultipliers[rank]!;
  Map<String, dynamic> toJson() => {
        'result_policy': policy,
        'attempt_count': 3,
        'success_count': successCount,
        'successful_reaction_total_us': successfulReactionTotalUs,
      };

  /// メタデータが無ければ旧結果。部分欠損を旧方針へ変換しません。
  static TackleResultMetadata? fromJson(Map<dynamic, dynamic> data) {
    const keys = [
      'result_policy',
      'attempt_count',
      'success_count',
      'successful_reaction_total_us'
    ];
    if (!keys.any(data.containsKey)) return null;
    if (!keys.every(data.containsKey) ||
        data['result_policy'] != policy ||
        data['attempt_count'] is! int ||
        data['attempt_count'] != 3 ||
        data['success_count'] is! int ||
        data['successful_reaction_total_us'] is! int) {
      throw const FormatException(
          'Incomplete or invalid tackle result metadata');
    }
    try {
      return TackleResultMetadata(
          successCount: data['success_count'] as int,
          successfulReactionTotalUs:
              data['successful_reaction_total_us'] as int);
    } on ArgumentError {
      throw const FormatException('Tackle result metadata out of range');
    }
  }
}
