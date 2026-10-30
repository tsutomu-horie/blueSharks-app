/// Presentation only. These thresholds mirror existing retirement checks; this
/// class never advances time, ends a game, or synchronizes anything to the API.
class TrainingRetirementWarning {
  const TrainingRetirementWarning({
    required this.episode,
    required this.title,
    required this.body,
    required this.remainingHours,
  });

  final String episode;
  final String title;
  final String body;
  // Only selects the most urgent warning. No countdown is displayed.
  final double remainingHours;

  static const foodBalanceTitle = '食事のバランスに注意';
  static const foodBalanceBody =
      '食事の数値が高い状態が続いています。この状態が続くと、鮫太郎が引退するおそれがあります。ごはんを控え、数値が下がるのを待ちましょう。';

  static const _zeroLimits = {'食事': 48, '体調': 48, '清潔': 72};

  /// Includes not-yet-due episodes so a clock resync cannot reopen a dismissed
  /// card. Recovery, a new cycle, and the existing end state remove episodes.
  static Set<String> activeEpisodes({
    required String scope,
    required Map<String, double> meters,
    required Map<String, DateTime> overStartedAt,
    required Map<String, int> zeroHours,
    required int elapsedHours,
  }) {
    final result = <String>{};
    for (final name in ['食事', '仕事']) {
      final start = overStartedAt[name];
      if ((meters[name] ?? 0) > 100 && start != null) {
        result.add('$scope:over:$name:${start.toUtc().toIso8601String()}');
      }
    }
    for (final name in _zeroLimits.keys) {
      final hours = zeroHours[name] ?? 0;
      if (meters[name] == 0 && hours > 0 && elapsedHours >= hours) {
        // Both counters advance only in _tickMainHour. Their difference is a
        // stable active-game-hour checkpoint, including after background resume.
        result.add('$scope:zero:$name:${elapsedHours - hours}');
      }
    }
    return result;
  }

  static List<TrainingRetirementWarning> evaluate({
    required String scope,
    required int stageIndex,
    required bool ended,
    required Map<String, double> meters,
    required Map<String, DateTime> overStartedAt,
    required Map<String, int> zeroHours,
    required int elapsedHours,
    DateTime? serverNow,
  }) {
    if (stageIndex < 2 || stageIndex > 4 || ended) return const [];
    final warnings = <TrainingRetirementWarning>[];
    for (final name in ['食事', '仕事']) {
      final start = overStartedAt[name];
      if ((meters[name] ?? 0) <= 100 || start == null || serverNow == null) {
        continue;
      }
      final elapsed = serverNow.difference(start);
      if (elapsed < const Duration(hours: 48) ||
          elapsed >= const Duration(hours: 72)) {
        continue;
      }
      warnings.add(TrainingRetirementWarning(
        episode: '$scope:over:$name:${start.toUtc().toIso8601String()}',
        title: name == '食事' ? foodBalanceTitle : '仕事のバランスに注意',
        body: name == '食事'
            ? foodBalanceBody
            : '仕事の数値が高い状態が続いています。この状態が続くと、鮫太郎が引退するおそれがあります。仕事や仕事の数値が増える練習を控え、数値が下がるのを待ちましょう。',
        remainingHours:
            72 - elapsed.inMicroseconds / Duration.microsecondsPerHour,
      ));
    }
    for (final entry in _zeroLimits.entries) {
      final hours = zeroHours[entry.key] ?? 0;
      if (meters[entry.key] != 0 ||
          hours < entry.value - 24 ||
          hours >= entry.value ||
          elapsedHours < hours) {
        continue;
      }
      final name = entry.key;
      final action = switch (name) {
        '食事' => 'ごはんで食事の数値を回復させましょう。',
        '体調' => '休養で体調の数値を回復させましょう。',
        _ => '掃除で清潔の数値を回復させましょう。',
      };
      warnings.add(TrainingRetirementWarning(
        episode: '$scope:zero:$name:${elapsedHours - hours}',
        title: '$nameの回復が必要です',
        body: '$nameが0の状態が続いています。この状態が続くと、鮫太郎が引退するおそれがあります。$action',
        remainingHours: (entry.value - hours).toDouble(),
      ));
    }
    warnings.sort((a, b) {
      final urgency = a.remainingHours.compareTo(b.remainingHours);
      return urgency != 0 ? urgency : a.episode.compareTo(b.episode);
    });
    return warnings;
  }
}
