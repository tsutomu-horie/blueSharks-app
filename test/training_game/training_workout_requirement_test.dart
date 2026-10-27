import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_workout_requirement.dart';

void main() {
  const baseline = <String, double>{
    '食事': 50,
    '清潔': 50,
    '体調': 50,
  };

  for (final meter in ['食事', '清潔', '体調']) {
    test('$meterは49で不足、50で筋トレ可能', () {
      final belowThreshold = <String, double>{...baseline, meter: 49};
      final atThreshold = <String, double>{...baseline, meter: 50};

      expect(TrainingWorkoutRequirement.missingMeters(belowThreshold), [meter]);
      expect(
        TrainingWorkoutRequirement.messageFor(belowThreshold),
        contains('$meterが50未満です。'),
      );
      expect(TrainingWorkoutRequirement.isMet(atThreshold), isTrue);
      expect(TrainingWorkoutRequirement.messageFor(atThreshold), isNull);
    });
  }

  test('複数の不足項目と対応する回復行動をまとめて案内する', () {
    const meters = <String, double>{
      '食事': 49,
      '清潔': 50,
      '体調': 0,
    };

    expect(TrainingWorkoutRequirement.missingMeters(meters), ['食事', '体調']);
    expect(
      TrainingWorkoutRequirement.messageFor(meters),
      '食事・体調が50未満です。ごはん・休養で50以上に整えてから筋トレしましょう。',
    );
  });
}
