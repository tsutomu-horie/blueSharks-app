/// Server settings are parsed as complete, versioned bundles. A game receives
/// one immutable instance; later fetches cannot change an active play.
class MiniGameSettings {
  const MiniGameSettings(
      {this.tackle = const TackleSettings(),
      this.passRun = const PassRunSettings()});
  final TackleSettings tackle;
  final PassRunSettings passRun;

  factory MiniGameSettings.fromJson(Object? value) {
    if (value is! Map || value['schema'] is! int || value['schema'] != 1) {
      return const MiniGameSettings();
    }
    TackleSettings tackle = const TackleSettings();
    PassRunSettings passRun = const PassRunSettings();
    try {
      tackle = TackleSettings.fromJson(value['tackle'], requireToken: true);
    } on FormatException {/* Whole tackle bundle falls back. */}
    try {
      passRun = PassRunSettings.fromJson(value['pass_run']);
    } on FormatException {/* Whole pass/run bundle falls back. */}
    return MiniGameSettings(tackle: tackle, passRun: passRun);
  }
}

int _integer(Map value, String key, int min, int max) {
  final n = value[key];
  if (n is! int || n < min || n > max) {
    throw FormatException('Invalid mini-game field: $key');
  }
  return n;
}

class TackleSettings {
  const TackleSettings(
      {this.setCount = 3,
      this.inputLimitMs = 750,
      this.perfectMaxMs = 150,
      this.greatMaxMs = 250,
      this.goodMaxMs = 350,
      this.overallSMaxMs = 300,
      this.overallAMaxMs = 450,
      this.overallBMaxMs = 600,
      this.snapshotToken});
  final int setCount, inputLimitMs, perfectMaxMs, greatMaxMs, goodMaxMs;
  final int overallSMaxMs, overallAMaxMs, overallBMaxMs;
  final String? snapshotToken;
  bool get hasDefaultRules =>
      setCount == 3 &&
      inputLimitMs == 750 &&
      perfectMaxMs == 150 &&
      greatMaxMs == 250 &&
      goodMaxMs == 350 &&
      overallSMaxMs == 300 &&
      overallAMaxMs == 450 &&
      overallBMaxMs == 600;
  Duration get inputLimit => Duration(milliseconds: inputLimitMs);

  factory TackleSettings.fromJson(Object? value, {bool requireToken = false}) {
    if (value is! Map ||
        value['schema'] is! int ||
        value['schema'] != 1 ||
        value['attempt_rank_max_ms'] is! Map ||
        value['overall_mean_max_ms'] is! Map) {
      throw const FormatException('Invalid tackle settings');
    }
    final token = value['snapshot_token'];
    if ((token != null &&
            (token is! String || token.isEmpty || token.length > 16384)) ||
        (requireToken && token == null)) {
      throw const FormatException('Missing tackle snapshot');
    }
    final limit = _integer(value, 'input_limit_ms', 400, 2000);
    final attempt = value['attempt_rank_max_ms'] as Map;
    final overall = value['overall_mean_max_ms'] as Map;
    final p = _integer(attempt, 'perfect', 1, limit - 1);
    final g = _integer(attempt, 'great', 1, limit - 1);
    final d = _integer(attempt, 'good', 1, limit - 1);
    final s = _integer(overall, 's', 1, limit - 1);
    final a = _integer(overall, 'a', 1, limit - 1);
    final b = _integer(overall, 'b', 1, limit - 1);
    if (!(p < g && g < d && s < a && a < b)) {
      throw const FormatException('Unordered tackle thresholds');
    }
    return TackleSettings(
        setCount: _integer(value, 'set_count', 1, 10),
        inputLimitMs: limit,
        perfectMaxMs: p,
        greatMaxMs: g,
        goodMaxMs: d,
        overallSMaxMs: s,
        overallAMaxMs: a,
        overallBMaxMs: b,
        snapshotToken: token as String?);
  }

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'set_count': setCount,
        'input_limit_ms': inputLimitMs,
        'attempt_rank_max_ms': {
          'perfect': perfectMaxMs,
          'great': greatMaxMs,
          'good': goodMaxMs
        },
        'overall_mean_max_ms': {
          's': overallSMaxMs,
          'a': overallAMaxMs,
          'b': overallBMaxMs
        },
        if (snapshotToken != null) 'snapshot_token': snapshotToken,
      };
}

class PassRunSettings {
  const PassRunSettings(
      {this.roundDurationMs = 15000,
      this.runSpeedScale = 1.15,
      this.laneSwapDurationMs = 1000,
      this.ballHalfFieldTravelMs = 440,
      this.missPenaltyMs = 1000});
  final int roundDurationMs,
      laneSwapDurationMs,
      ballHalfFieldTravelMs,
      missPenaltyMs;
  final double runSpeedScale;
  factory PassRunSettings.fromJson(Object? value) {
    if (value is! Map || value['schema'] is! int || value['schema'] != 1) {
      throw const FormatException('Invalid pass/run settings');
    }
    final speed = value['run_speed_scale'];
    if (speed is! num || !speed.isFinite || speed < .85 || speed > 1.25) {
      throw const FormatException('Invalid run speed');
    }
    return PassRunSettings(
        roundDurationMs: _integer(value, 'round_duration_ms', 10000, 30000),
        runSpeedScale: speed.toDouble(),
        laneSwapDurationMs: _integer(value, 'lane_swap_duration_ms', 800, 1500),
        ballHalfFieldTravelMs:
            _integer(value, 'ball_half_field_travel_ms', 350, 650),
        missPenaltyMs: _integer(value, 'miss_penalty_ms', 500, 3000));
  }
}
