import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';

const customTackle = TackleSettings(
  setCount: 2,
  inputLimitMs: 1000,
  perfectMaxMs: 100,
  greatMaxMs: 200,
  goodMaxMs: 300,
  overallSMaxMs: 200,
  overallAMaxMs: 400,
  overallBMaxMs: 600,
  snapshotToken: 'test-snapshot-token',
);

Map<String, dynamic> passJson() => {
      'schema': 1,
      'round_duration_ms': 30000,
      'run_speed_scale': .85,
      'lane_swap_duration_ms': 1500,
      'ball_half_field_travel_ms': 650,
      'miss_penalty_ms': 3000,
    };

Map<String, dynamic> envelope({Object? tackle, Object? passRun}) => {
      'schema': 1,
      'tackle': tackle ?? customTackle.toJson(),
      'pass_run': passRun ?? passJson(),
    };

void expectDefaultPass(PassRunSettings settings) {
  expect(settings.roundDurationMs, 15000);
  expect(settings.runSpeedScale, 1.15);
  expect(settings.laneSwapDurationMs, 1000);
  expect(settings.ballHalfFieldTravelMs, 440);
  expect(settings.missPenaltyMs, 1000);
}

void main() {
  group('設定bundleのatomic fallback', () {
    test('schema1は署名付きTackleとPassRunを完全に読み込む', () {
      final settings = MiniGameSettings.fromJson(envelope());
      expect(settings.tackle.toJson(), customTackle.toJson());
      expect(settings.passRun.roundDurationMs, 30000);
      expect(settings.passRun.runSpeedScale, .85);
      expect(settings.passRun.laneSwapDurationMs, 1500);
      expect(settings.passRun.ballHalfFieldTravelMs, 650);
      expect(settings.passRun.missPenaltyMs, 3000);
    });

    test('不正・未知envelopeは両ゲームの既定値へ戻る', () {
      for (final value in [
        null,
        [],
        'bad',
        {},
        {...envelope(), 'schema': 2}
      ]) {
        final settings = MiniGameSettings.fromJson(value);
        expect(settings.tackle.toJson(), const TackleSettings().toJson());
        expectDefaultPass(settings.passRun);
      }
    });

    test('Tackleの欠損・型・範囲・順序・token不正はTackle全体だけ戻る', () {
      final invalid = <Object?>[
        [],
        {},
        {...customTackle.toJson(), 'schema': 2},
        {...customTackle.toJson()}..remove('snapshot_token'),
        {...customTackle.toJson()}..remove('input_limit_ms'),
        {...customTackle.toJson(), 'snapshot_token': ''},
        {...customTackle.toJson(), 'snapshot_token': 123},
        {...customTackle.toJson(), 'set_count': 0},
        {...customTackle.toJson(), 'input_limit_ms': 2001},
        {...customTackle.toJson(), 'input_limit_ms': '1000'},
        {...customTackle.toJson(), 'set_count': 2.0},
        {
          ...customTackle.toJson(),
          'attempt_rank_max_ms': {'perfect': 200, 'great': 100, 'good': 300}
        },
        {
          ...customTackle.toJson(),
          'overall_mean_max_ms': {'s': 200, 'a': 400}
        },
      ];
      for (final value in invalid) {
        final settings = MiniGameSettings.fromJson(envelope(tackle: value));
        expect(settings.tackle.toJson(), const TackleSettings().toJson());
        expect(settings.passRun.roundDurationMs, 30000);
      }
    });

    test('PassRunの各field欠損・型・範囲不正はPassRun全体だけ戻る', () {
      final invalid = <Object?>[
        [],
        {},
        {...passJson(), 'schema': 2}
      ];
      for (final key in passJson().keys.where((key) => key != 'schema')) {
        invalid.add({...passJson()}..remove(key));
        invalid.add({...passJson(), key: 'invalid'});
      }
      for (final entry in {
        'round_duration_ms': [9999, 30001, 15000.0],
        'run_speed_scale': [.849, 1.251, double.nan, double.infinity],
        'lane_swap_duration_ms': [799, 1501],
        'ball_half_field_travel_ms': [349, 651],
        'miss_penalty_ms': [499, 3001],
      }.entries) {
        for (final value in entry.value) {
          invalid.add({...passJson(), entry.key: value});
        }
      }
      for (final value in invalid) {
        final settings = MiniGameSettings.fromJson(envelope(passRun: value));
        expectDefaultPass(settings.passRun);
        expect(settings.tackle.toJson(), customTackle.toJson());
      }
      final lower = PassRunSettings.fromJson({
        ...passJson(),
        'round_duration_ms': 10000,
        'run_speed_scale': 1.25,
        'lane_swap_duration_ms': 800,
        'ball_half_field_travel_ms': 350,
        'miss_penalty_ms': 500
      });
      expect(lower.roundDurationMs, 10000);
      expect(lower.runSpeedScale, 1.25);
    });
  });

  group('Tackle保存metadataの判定再現', () {
    Map<String, dynamic> saved() => jsonDecode(jsonEncode(TackleResultMetadata(
            successCount: 1,
            successfulReactionTotalUs: 200000,
            settings: customTackle)
        .toJson())) as Map<String, dynamic>;

    test('v3の2set/1000ms設定をJSON journal往復で保持する', () {
      final data = saved();
      final restored = TackleResultMetadata.fromJson(data)!;
      expect(restored.toJson(), data);
      expect(restored.resultPolicy, TackleResultMetadata.snapshotPolicy);
      expect(restored.settings.toJson(), customTackle.toJson());
      expect(restored.attemptCount, 2);
      expect(restored.penalizedTotalUs, 1200000);
      expect(restored.penaltyMeanSeconds, .6);
      expect(restored.rank, 'B');
      expect(restored.effectMultiplier, .75);
    });

    test('v3のtoken・local snapshot欠損と未知/部分metadataを拒否する', () {
      final invalid = <Map<String, dynamic>>[
        {...saved()}..remove('rule_snapshot_token'),
        {...saved()}..remove('rule_snapshot'),
        {...saved()}..remove('success_count'),
        {...saved(), 'result_policy': 'unknown'},
        {...saved(), 'rule_snapshot_token': 'different-token'},
        {...saved(), 'attempt_count': 3},
        {...saved(), 'successful_reaction_total_us': 1000001},
        {'rule_snapshot_token': 'orphan'},
        {
          ...saved(),
          'rule_snapshot': {...customTackle.toJson()}..remove('snapshot_token')
        },
      ];
      for (final data in invalid) {
        expect(
            () => TackleResultMetadata.fromJson(data), throwsFormatException);
      }
      expect(TackleResultMetadata.fromJson({'unrelated': true}), isNull);
      expect(
          () => TackleResultMetadata(
              successCount: 1,
              successfulReactionTotalUs: 1,
              settings: const TackleSettings(setCount: 2)),
          throwsArgumentError);
    });

    test('v2は別の現行設定を読んでも固定3set/750msで復元する', () {
      final data = TackleResultMetadata(
              successCount: 2, successfulReactionTotalUs: 150000)
          .toJson();
      final current = MiniGameSettings.fromJson(envelope());
      expect(current.tackle.setCount, 2);
      final restored = TackleResultMetadata.fromJson(data)!;
      expect(restored.resultPolicy, TackleResultMetadata.policy);
      expect(restored.settings.toJson(), const TackleSettings().toJson());
      expect(restored.attemptCount, 3);
      expect(restored.penalizedTotalUs, 900000);
      expect(restored.rank, 'S');
      expect(restored.toJson().containsKey('rule_snapshot_token'), isFalse);
    });

    test('v3総合閾値の境界をµs整数で判定し、全MISSはD', () {
      for (final sample in [
        (400000, 'S'),
        (400001, 'A'),
        (800000, 'A'),
        (800001, 'B'),
        (1200000, 'B'),
        (1200001, 'C'),
      ]) {
        final metadata = TackleResultMetadata(
            successCount: 2,
            successfulReactionTotalUs: sample.$1,
            settings: customTackle);
        expect(
            TackleResultMetadata.fromJson(metadata.toJson())!.rank, sample.$2);
      }
      final miss = TackleResultMetadata(
          successCount: 0,
          successfulReactionTotalUs: 0,
          settings: customTackle);
      expect(miss.rank, 'D');
      expect(miss.penalizedTotalUs, 2000000);
    });
  });
}
