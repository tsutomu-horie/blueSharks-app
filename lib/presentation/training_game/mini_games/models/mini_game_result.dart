import '../../models/mini_game_settings.dart';

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
    TackleSettings settings = const TackleSettings(),
  }) {
    final metadata = TackleResultMetadata(
      successCount: successCount,
      successfulReactionTotalUs: successfulReactionTotalUs,
      settings: settings,
    );
    final rank = metadata.rank;
    final penaltyMean = metadata.penaltyMeanSeconds;
    final averageLabel = '${penaltyMean.toStringAsFixed(2)}秒';
    return MiniGameResult(
      type: MiniGameType.tackle,
      summary:
          'タックル 総合$rank／判定平均$averageLabel／成功$successCount/${settings.setCount}',
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
  static const snapshotPolicy = 'tackle_v3_snapshot_penalty_mean';
  const TackleResultMetadata._(
      this.successCount, this.successfulReactionTotalUs, this.settings);
  factory TackleResultMetadata(
      {required int successCount,
      required int successfulReactionTotalUs,
      TackleSettings settings = const TackleSettings()}) {
    // An unsigned result always uses the fixed v2 rules. Custom rules require
    // the server-issued snapshot; a partially missing v3 never becomes v2.
    if (settings.snapshotToken == null && !settings.hasDefaultRules) {
      throw ArgumentError('Unsigned custom tackle settings');
    }
    final validated = TackleSettings.fromJson(settings.toJson());
    if (successCount < 0 ||
        successCount > validated.setCount ||
        successfulReactionTotalUs < 0 ||
        successfulReactionTotalUs >
            successCount * validated.inputLimit.inMicroseconds) {
      throw ArgumentError('Invalid tackle result metadata');
    }
    return TackleResultMetadata._(
        successCount, successfulReactionTotalUs, validated);
  }
  final int successCount;
  final int successfulReactionTotalUs;
  final TackleSettings settings;
  String get resultPolicy =>
      settings.snapshotToken == null ? policy : snapshotPolicy;
  int get attemptCount => settings.setCount;
  int get penalizedTotalUs =>
      successfulReactionTotalUs +
      (attemptCount - successCount) * settings.inputLimit.inMicroseconds;
  double get penaltyMeanSeconds => penalizedTotalUs / (attemptCount * 1000000);
  String get rank {
    if (successCount == 0) return 'D';
    if (penalizedTotalUs <= settings.overallSMaxMs * 1000 * attemptCount) {
      return 'S';
    }
    if (penalizedTotalUs <= settings.overallAMaxMs * 1000 * attemptCount) {
      return 'A';
    }
    if (penalizedTotalUs <= settings.overallBMaxMs * 1000 * attemptCount) {
      return 'B';
    }
    return 'C';
  }

  double get effectMultiplier => MiniGameResult.tackleEffectMultipliers[rank]!;
  Map<String, dynamic> toJson() => {
        'result_policy': resultPolicy,
        'attempt_count': attemptCount,
        'success_count': successCount,
        'successful_reaction_total_us': successfulReactionTotalUs,
        if (settings.snapshotToken != null) ...{
          'rule_snapshot_token': settings.snapshotToken,
          // Local-only readable copy for deterministic recovery. The server trusts
          // only the authenticated token, never this client copy.
          'rule_snapshot': settings.toJson(),
        },
      };
  static TackleResultMetadata? fromJson(Map<dynamic, dynamic> data) {
    const keys = [
      'result_policy',
      'attempt_count',
      'success_count',
      'successful_reaction_total_us'
    ];
    if (![...keys, 'rule_snapshot', 'rule_snapshot_token']
        .any(data.containsKey)) {
      return null;
    }
    if (!keys.every(data.containsKey) ||
        data['attempt_count'] is! int ||
        data['success_count'] is! int ||
        data['successful_reaction_total_us'] is! int) {
      throw const FormatException('Incomplete tackle result metadata');
    }
    TackleSettings settings;
    if (data['result_policy'] == policy) {
      if (data.containsKey('rule_snapshot') ||
          data.containsKey('rule_snapshot_token') ||
          data['attempt_count'] != 3) {
        throw const FormatException('Invalid fixed tackle result');
      }
      settings = const TackleSettings();
    } else if (data['result_policy'] == snapshotPolicy) {
      settings =
          TackleSettings.fromJson(data['rule_snapshot'], requireToken: true);
      if (data['rule_snapshot_token'] != settings.snapshotToken ||
          data['attempt_count'] != settings.setCount) {
        throw const FormatException('Inconsistent tackle snapshot');
      }
    } else {
      throw const FormatException('Unknown tackle result policy');
    }
    try {
      return TackleResultMetadata(
          successCount: data['success_count'] as int,
          successfulReactionTotalUs:
              data['successful_reaction_total_us'] as int,
          settings: settings);
    } on ArgumentError {
      throw const FormatException('Tackle result metadata out of range');
    }
  }
}
