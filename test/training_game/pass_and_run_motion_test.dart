import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('seed120と110の長い初期待ちを再発させない', () {
    for (final seed in [120, 110]) {
      final watch = Stopwatch()..start();
      final motion =
          PassRunMotion(seed: seed, roundSeconds: 30, speedScale: .85);
      watch.stop();
      // ignore: avoid_print
      print('construction seed=$seed elapsedUs=${watch.elapsedMicroseconds}');
      for (final outbound in [true, false]) {
        for (final carrier in PassRunRunner.values) {
          var legalSamples = 0;
          var forwardSamples = 0;
          double? firstLegalAt;
          var blockedRun = 0.0;
          var longestBlocked = 0.0;
          for (var step = 0; step <= 750; step++) {
            final seconds = step * .02;
            final origin = motion.yAt(
              seconds,
              carrier,
              outbound: outbound,
            );
            final future = motion.yAt(
              seconds + .65,
              carrier == PassRunRunner.player
                  ? PassRunRunner.companion
                  : PassRunRunner.player,
              outbound: outbound,
            );
            final forward = PassAndRunRules.isForwardDirection(
              deltaX: -187.5,
              deltaY: future - origin,
              outbound: outbound,
            );
            if (forward) {
              forwardSamples++;
              blockedRun += .02;
              longestBlocked = math.max(longestBlocked, blockedRun);
            } else {
              legalSamples++;
              blockedRun = 0;
              firstLegalAt ??= seconds;
            }
          }
          expect(
            legalSamples,
            greaterThan(0),
            reason:
                'seed=$seed carrier=$carrier outbound=$outbound has no legal window',
          );
          expect(
            forwardSamples,
            greaterThan(0),
            reason:
                'seed=$seed carrier=$carrier outbound=$outbound should retain blocked positions',
          );
          // Regression: this seed previously began with 8.8 s of blocked returns.
          expect(firstLegalAt, lessThanOrEqualTo(4.0));
          expect(longestBlocked, lessThan(8.0),
              reason: 'seed=$seed carrier=$carrier outbound=$outbound '
                  'must not restore the old 8.58/11.3 second stall');
          // ignore: avoid_print
          print(
            'seed=$seed carrier=$carrier outbound=$outbound '
            'firstLegal=${firstLegalAt?.toStringAsFixed(2)}s '
            'legal=$legalSamples forwardOnly=$forwardSamples '
            'longestBlocked=${longestBlocked.toStringAsFixed(2)}s',
          );
        }
      }
    }
  });

  test('各人が独立したランダム区間で共有の広い可動域を使う', () {
    expect(PassRunMotion.forwardRate, closeTo(.207, 1e-12));
    expect(PassRunMotion.turnDuration, const Duration(milliseconds: 1000));
    expect(PassAndRunRules.roundDuration, const Duration(seconds: 15));
    expect(PassAndRunRules.standardPassDuration,
        const Duration(milliseconds: 440));
    expect(PassAndRunRules.missPenalty, const Duration(seconds: 1));
    var sampleMinimum = 1.0;
    var sampleMaximum = 0.0;
    var shortestSpan = 1.0;
    var longestSpan = 0.0;
    var broadTracks = 0;
    final minimumByRunnerAndDirection = {
      for (final runner in PassRunRunner.values)
        for (final up in [true, false]) (runner, up): 1.0,
    };
    final maximumByRunnerAndDirection = {
      for (final runner in PassRunRunner.values)
        for (final up in [true, false]) (runner, up): 0.0,
    };
    for (var seed = 0; seed < 1000; seed++) {
      final motion = PassRunMotion(seed: seed);
      for (final up in [true, false]) {
        for (final runner in PassRunRunner.values) {
          var last = motion.worldVelocityYAt(0, runner, outbound: up);
          var trackMinimum = 1.0;
          var trackMaximum = 0.0;
          for (var ms = 0; ms <= 17000; ms += 20) {
            final t = ms / 1000;
            final y = motion.yAt(t, runner, outbound: up);
            // 全員に共通する、名前と体を収めたフィールド境界を使う。
            expect(
                y,
                inInclusiveRange(
                    motion.geometry.minimum, motion.geometry.maximum));
            if (ms <= 15000) {
              trackMinimum = math.min(trackMinimum, y);
              trackMaximum = math.max(trackMaximum, y);
            }
            sampleMinimum = math.min(sampleMinimum, y);
            sampleMaximum = math.max(sampleMaximum, y);
            minimumByRunnerAndDirection[(runner, up)] = math.min(
              minimumByRunnerAndDirection[(runner, up)]!,
              y,
            );
            maximumByRunnerAndDirection[(runner, up)] = math.max(
              maximumByRunnerAndDirection[(runner, up)]!,
              y,
            );
            final v = motion.worldVelocityYAt(t, runner, outbound: up);
            expect(up ? v < 0 : v > 0, isTrue);
            expect(v.abs(), inInclusiveRange(.025, .42));
            expect((v - last).abs(), lessThan(.01));
            last = v;
          }
          final span = trackMaximum - trackMinimum;
          shortestSpan = math.min(shortestSpan, span);
          longestSpan = math.max(longestSpan, span);
          if (span > .2) broadTracks++;
        }
      }
    }
    expect(sampleMinimum, lessThan(.2));
    expect(sampleMaximum, greaterThan(.8));
    expect(shortestSpan, greaterThan(.05));
    expect(longestSpan, greaterThan(.25));
    expect(broadTracks, greaterThan(3200));
    for (final runner in PassRunRunner.values) {
      for (final up in [true, false]) {
        final key = (runner, up);
        expect(
          minimumByRunnerAndDirection[key],
          lessThan(.2),
          reason: '$runner ${up ? '上' : '下'}攻撃で共通範囲の上端へ移動できる',
        );
        expect(
          maximumByRunnerAndDirection[key],
          greaterThan(.8),
          reason: '$runner ${up ? '上' : '下'}攻撃で共通範囲の下端へ移動できる',
        );
      }
    }
  });

  test('同一seedの15秒でも端点固定でなく何度か移動方向が変わる', () {
    final motion = PassRunMotion(seed: 3)
      ..updateFieldGeometry(const Size(768, 390));
    for (final runner in PassRunRunner.values) {
      final positions = [
        for (var tick = 0; tick <= 300; tick++) motion.yAt(tick * .05, runner),
      ];
      final span = positions.reduce(math.max) - positions.reduce(math.min);
      final directionChanges = <int>[];
      int? previousDirection;
      for (var i = 1; i < positions.length; i++) {
        final delta = positions[i] - positions[i - 1];
        if (delta.abs() <= .00005) continue;
        final direction = delta.sign.toInt();
        if (previousDirection != null && direction != previousDirection) {
          directionChanges.add(i);
        }
        previousDirection = direction;
      }
      expect(span, greaterThan(.2),
          reason: '$runner uses more than one fixed point');
      expect(directionChanges.length, greaterThanOrEqualTo(2),
          reason: '$runner changes direction within the round');
    }
  });

  test('同seedは再現し、別seed・往復・両者は別軌道、脚距離は増える', () {
    final a = PassRunMotion(seed: 54),
        b = PassRunMotion(seed: 54),
        c = PassRunMotion(seed: 95);
    for (final runner in PassRunRunner.values) {
      expect(a.yAt(2, runner), b.yAt(2, runner));
      expect(a.yAt(2, runner), isNot(c.yAt(2, runner)));
      expect(a.yAt(2, runner), isNot(1 - a.yAt(2, runner, outbound: false)));
      for (final up in [true, false]) {
        for (var ms = 1; ms <= 15000; ms += 20) {
          final t = ms / 1000;
          expect(a.distanceAt(t, runner, outbound: up),
              greaterThan(a.distanceAt(t - .001, runner, outbound: up)));
        }
      }
    }
    var relativeMinimum = 1.0;
    var relativeMaximum = 0.0;
    for (var ms = 0; ms <= 15000; ms += 20) {
      final seconds = ms / 1000;
      final relative = a.yAt(seconds, PassRunRunner.player) -
          a.yAt(seconds, PassRunRunner.companion);
      relativeMinimum = math.min(relativeMinimum, relative);
      relativeMaximum = math.max(relativeMaximum, relative);
    }
    expect(relativeMaximum - relativeMinimum, greaterThan(.2));
  });

  test('独立速度で前後関係が15秒の間に繰り返し反転する', () {
    var repeatedOvertakes = 0;
    for (var seed = 0; seed < 128; seed++) {
      final motion = PassRunMotion(seed: seed);
      var previousOrder = 0;
      var reversals = 0;
      for (var ms = 0; ms <= 15000; ms += 100) {
        final t = ms / 1000;
        final relative = motion.yAt(t, PassRunRunner.player) -
            motion.yAt(t, PassRunRunner.companion);
        if (relative.abs() < .01) continue;
        final order = relative.sign.toInt();
        if (previousOrder != 0 && order != previousOrder) reversals++;
        previousOrder = order;
      }
      if (reversals >= 2) repeatedOvertakes++;
    }
    expect(repeatedOvertakes, greaterThan(96));
  });
  test('1000seedの左右交換は狭幅・横画面でも体と名前が重ならず端点へ連続', () {
    for (var seed = 0; seed < 1000; seed++) {
      final m = PassRunMotion(seed: seed);
      for (final field in [
        const Size(208, 262),
        const Size(288, 262),
        const Size(370, 568),
        const Size(812, 200)
      ]) {
        m.updateFieldGeometry(field);
        final size = .75 *
            (112.0.clamp(0, field.height * .4).clamp(0, field.width * .5));
        final labelScale = m.geometry.labelScale;
        for (var i = 0; i <= 100; i++) {
          final p = i / 100;
          Rect body(PassRunRunner runner) => Rect.fromCenter(
              center: m.turnOffset(p, runner, field: field, actorSize: size),
              width: size,
              height: size);
          final a = body(PassRunRunner.player),
              b = body(PassRunRunner.companion);
          expect(a.overlaps(b), isFalse, reason: '$seed $field $p');
          final label = Rect.fromLTWH(
            a.left,
            a.top - 16 * labelScale - 2,
            size,
            16 * labelScale,
          );
          expect(label.overlaps(b), isFalse, reason: 'label $seed $field $p');
          for (final r in [a, b]) {
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(field.width));
            expect(r.bottom, lessThanOrEqualTo(field.height));
          }
        }
        for (final runner in PassRunRunner.values) {
          final mate = runner == PassRunRunner.companion;
          expect(
              m.turnOffset(0, runner, field: field, actorSize: size),
              Offset(field.width * (mate ? .75 : .25),
                  field.height * m.yAt(15, runner)));
          expect(
              (m.turnOffset(1, runner, field: field, actorSize: size) -
                      Offset(field.width * (mate ? .25 : .75),
                          field.height * m.yAt(0, runner, outbound: false)))
                  .distance,
              lessThan(1e-6));
        }
      }
    }
  });
  test('No54は顔とカメラに依存せず上/下攻撃に対する前方だけ禁止', () {
    for (final up in [true, false]) {
      for (final dx in [-100.0, 0.0, 100.0]) {
        for (final dy in [-100.0, -.000001, 0.0, .000001, 100.0]) {
          expect(
              PassAndRunRules.isForwardDirection(
                  deltaX: dx, deltaY: dy, outbound: up),
              up ? dy < 0 : dy > 0);
        }
      }
    }
  });
}
