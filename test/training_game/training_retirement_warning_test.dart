import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_retirement_warning.dart';

void main() {
  final at = DateTime.utc(2026, 10, 30, 10, 23, 45);
  List<TrainingRetirementWarning> warnings({
    int stage = 2,
    bool ended = false,
    String name = '食事',
    double value = 145,
    Duration age = const Duration(hours: 48),
    bool timestamp = true,
    DateTime? now,
    int zero = 0,
    int elapsed = 100,
  }) =>
      TrainingRetirementWarning.evaluate(
        scope: 'synthetic-cycle',
        stageIndex: stage,
        ended: ended,
        meters: {name: value},
        overStartedAt: timestamp ? {name: at.subtract(age)} : {},
        zeroHours: {name: zero},
        elapsedHours: elapsed,
        serverNow: now ?? at,
      );

  test('food/work over-state uses exact 48h inclusive / 72h exclusive', () {
    for (final name in ['食事', '仕事']) {
      for (final entry in {
        const Duration(hours: 47, minutes: 59, seconds: 59): 0,
        const Duration(hours: 48): 1,
        const Duration(hours: 71, minutes: 59, seconds: 59): 1,
        const Duration(hours: 72): 0,
      }.entries) {
        expect(warnings(name: name, age: entry.key), hasLength(entry.value));
      }
    }
  });
  test('missing/future clock evidence, recovery, ended and tutorial never warn',
      () {
    expect(warnings(timestamp: false), isEmpty);
    expect(warnings(age: const Duration(hours: -1)), isEmpty);
    expect(warnings(value: 100), isEmpty);
    expect(warnings(value: 99.9999), isEmpty);
    expect(warnings(ended: true), isEmpty);
    for (final stage in [0, 1, 5]) {
      expect(warnings(stage: stage), isEmpty);
    }
    expect(
        TrainingRetirementWarning.evaluate(
          scope: 'fake',
          stageIndex: 2,
          ended: false,
          meters: {'食事': 145},
          overStartedAt: {'食事': at.subtract(const Duration(hours: 49))},
          zeroHours: {},
          elapsedHours: 0,
        ),
        isEmpty);
  });
  test('zero warnings use existing active counters, not wall-clock time', () {
    for (final entry in {'食事': 48, '体調': 48, '清潔': 72}.entries) {
      for (final hours in [
        entry.value - 25,
        entry.value - 24,
        entry.value - 1,
        entry.value
      ]) {
        final expected = hours >= entry.value - 24 && hours < entry.value;
        expect(
            warnings(
                name: entry.key,
                value: 0,
                zero: hours,
                now: at.add(const Duration(days: 100))),
            hasLength(expected ? 1 : 0));
      }
      expect(warnings(name: entry.key, value: 0.01, zero: entry.value - 1),
          isEmpty);
    }
    expect(warnings(name: '仕事', value: 0, zero: 48), isEmpty);
  });
  test(
      'same active-hour episode survives ticks; recovery/new zero is different',
      () {
    Set<String> episodes(double value, int elapsed, int zero) =>
        TrainingRetirementWarning.activeEpisodes(
            scope: 'same-player-cycle',
            meters: {'食事': value},
            overStartedAt: {},
            zeroHours: {'食事': zero},
            elapsedHours: elapsed);
    expect(episodes(0, 30, 24), episodes(0, 31, 25));
    expect(episodes(1, 31, 25), isEmpty);
    expect(episodes(0, 60, 24), isNot(episodes(0, 30, 24)));
  });
  test('approved food copy is exact; other reasons name actionable care', () {
    final food = warnings().single;
    expect(food.title, '食事のバランスに注意');
    expect(food.body,
        '食事の数値が高い状態が続いています。この状態が続くと、鮫太郎が引退するおそれがあります。ごはんを控え、数値が下がるのを待ちましょう。');
    expect(warnings(name: '仕事').single.body, contains('仕事の数値が増える練習を控え'));
    for (final entry in {'食事': 'ごはん', '体調': '休養', '清潔': '掃除'}.entries) {
      expect(
          warnings(name: entry.key, value: 0, zero: entry.key == '清潔' ? 48 : 24)
              .single
              .body,
          contains(entry.value));
    }
  });
}
