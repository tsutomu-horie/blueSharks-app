import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_position_classifier.dart';

void main() {
  group('TrainingGamePositionClassifier', () {
    test('10ポジションを仕様順に判定できる', () {
      final cases = <Map<String, Object>>[
        {'expected': 'プロップ', 'values': _trends(fw: 100, cmd: 10, run: 5, bulk: 10, tech: 1)},
        {'expected': 'フッカー', 'values': _trends(fw: 100, cmd: 10, run: 5, bulk: 10, tech: 10)},
        {'expected': 'ロック', 'values': _trends(fw: 100, cmd: 10, run: 5, bulk: 10, tech: 5)},
        {'expected': 'フランカー', 'values': _trends(fw: 100, cmd: 20, run: 60, bulk: 10, tech: 20)},
        {'expected': 'ナンバーエイト', 'values': _trends(fw: 100, cmd: 20, run: 60, bulk: 10, tech: 5)},
        {'expected': 'スクラムハーフ', 'values': _trends(fw: 50, cmd: 100, run: 10, bulk: 1, tech: 1)},
        {'expected': 'スタンドオフ', 'values': _trends(fw: 30, cmd: 100, run: 10, bulk: 1, tech: 1)},
        {'expected': 'センター', 'values': _trends(fw: 60, cmd: 30, run: 100, bulk: 1, tech: 1)},
        {'expected': 'ウイング', 'values': _trends(fw: 20, cmd: 30, run: 100, bulk: 1, tech: 1)},
        {'expected': 'フルバック', 'values': _trends(fw: 40, cmd: 35, run: 30, bulk: 1, tech: 1)},
      ];

      for (final item in cases) {
        expect(
          TrainingGamePositionClassifier.classify(item['values']! as Map<String, double>),
          item['expected'],
        );
      }
    });

    test('主傾向が未成立なら補助傾向だけで確定しない', () {
      expect(TrainingGamePositionClassifier.classify(_trends()), '判定前');
      expect(TrainingGamePositionClassifier.classify(_trends(tech: 10)), '判定前');
    });

    test('BULKが0でも番兵値でフッカーに確定しない', () {
      expect(
        TrainingGamePositionClassifier.classify(_trends(fw: 100, tech: 10)),
        'プロップ',
      );
    });
  });
}

/// 各テストケースの傾向値を明示的に組み立てます。
Map<String, double> _trends({
  double fw = 0,
  double cmd = 0,
  double run = 0,
  double bulk = 0,
  double tech = 0,
}) => {
      'FW': fw,
      'CMD': cmd,
      'RUN': run,
      'BULK': bulk,
      'TECH': tech,
    };
