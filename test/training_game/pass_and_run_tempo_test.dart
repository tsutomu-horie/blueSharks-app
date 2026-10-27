import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';

void main() {
  test('sweepは通過・接線・変化半径を検出し、離れた区間はMISS', () {
    double? hit(double y, double r0, double r1) =>
        PassAndRunRules.sweptCollision(
            startX: -50,
            startY: y,
            endX: 50,
            endY: y,
            startRadius: r0,
            endRadius: r1);
    expect(hit(0, 10, 10), closeTo(.4, 1e-12));
    expect(hit(10, 10, 10), closeTo(.5, 1e-12));
    expect(hit(10.01, 10, 10), isNull);
    expect(hit(12, 10, 15), isNotNull);
    expect(hit(12, 15, 10), isNotNull);
    expect(hit(16, 15, 10), isNull);
    // 終端で半径が拡大する場合、区間直前には非衝突でも終端点は衝突する。
    expect(
        PassAndRunRules.sweptCollision(
            startX: 100.02,
            startY: 0,
            endX: 100.02,
            endY: 0,
            startRadius: 100,
            endRadius: 100),
        isNull);
    expect(
        PassAndRunRules.hasCollided(
            ballDeltaX: 100.02,
            ballDeltaY: 0,
            ballRadius: 100.03,
            mateRadius: 0),
        isTrue);
    expect(
        PassAndRunRules.sweptCollision(
            startX: 20,
            startY: 0,
            endX: 20,
            endY: 0,
            startRadius: 10,
            endRadius: 30),
        closeTo(.5, 1e-12));
  });

  test('横補正は成立した入力の±5度内だけで前後方向を保つ', () {
    for (final dx in [-100.0, 100.0]) {
      for (final degrees in [-5.01, -5.0, -4.99, 0.0, 4.99, 5.0, 5.01]) {
        final dy = dx.abs() * math.tan(degrees * math.pi / 180);
        for (final outbound in [true, false]) {
          final forward = PassAndRunRules.isForwardDirection(
            deltaX: dx,
            deltaY: dy,
            outbound: outbound,
          );
          final direction = PassAndRunRules.userPassDirection(
            PassFlick(deltaX: dx, deltaY: dy, velocityX: 500, velocityY: 0),
            outbound: outbound,
          );
          expect(direction.deltaX, dx);
          final snapped = degrees.abs() <= 5 && forward;
          expect(direction.deltaY, snapped ? 0 : dy);
          expect(
              PassAndRunRules.isForwardDirection(
                  deltaX: direction.deltaX,
                  deltaY: direction.deltaY,
                  outbound: outbound),
              !snapped && forward);
        }
      }
    }
    for (final flick in [
      const PassFlick(deltaX: 23, deltaY: -.1, velocityX: 500, velocityY: 0),
      const PassFlick(deltaX: 39, deltaY: -.1, velocityX: 399, velocityY: 0),
      const PassFlick(deltaX: 0, deltaY: -100, velocityX: 0, velocityY: 500),
    ]) {
      expect(
        PassAndRunRules.userPassDirection(flick, outbound: true).deltaY,
        flick.deltaY,
      );
    }
    // 自動返球が呼ぶ厳密判定には横補正を入れない。
    expect(
        PassAndRunRules.isForwardDirection(
            deltaX: 100, deltaY: -.01, outbound: true),
        isTrue);
  });

  test('独立移動では返球可能・前方禁止の場面が両方生まれ、速度は連続する', () {
    var legalSamples = 0;
    var forwardBlockedSamples = 0;
    var totalSamples = 0;
    var longestBlockedRun = 0;
    var roundsWithoutLegalWindow = 0;
    var measuredRounds = 0;
    final noLegalWindowCases = <String>[];
    for (var seed = 0; seed < 128; seed++) {
      for (final scale in [.85, 1.15, 1.25]) {
        final motion =
            PassRunMotion(seed: seed, roundSeconds: 30, speedScale: scale);
        for (final flightSeconds in [.35, .65]) {
          for (final outbound in [true, false]) {
            var blockedRun = 0;
            var roundLegalSamples = 0;
            measuredRounds++;
            for (var step = 0; step <= 150; step++) {
              final t = step / 10;
              final origin =
                  motion.yAt(t, PassRunRunner.companion, outbound: outbound);
              final future = motion.yAt(t + flightSeconds, PassRunRunner.player,
                  outbound: outbound);
              final forward = PassAndRunRules.isForwardDirection(
                deltaX: 187.5,
                deltaY: (future - origin) * 500,
                outbound: outbound,
              );
              totalSamples++;
              if (forward) {
                forwardBlockedSamples++;
                blockedRun++;
              } else {
                legalSamples++;
                roundLegalSamples++;
                blockedRun = 0;
              }
              longestBlockedRun = math.max(longestBlockedRun, blockedRun);

              for (final runner in PassRunRunner.values) {
                double velocity(double at) =>
                    motion.worldVelocityYAt(at, runner, outbound: outbound);
                final leftAcceleration =
                    (velocity(t) - velocity(t - .001)) / .001;
                final rightAcceleration =
                    (velocity(t + .001) - velocity(t)) / .001;
                expect(
                  (leftAcceleration - rightAcceleration).abs(),
                  lessThan(.001),
                  reason:
                      '加速度の左右差 seed=$seed scale=$scale outbound=$outbound runner=$runner t=$t left=$leftAcceleration right=$rightAcceleration',
                );
                expect(
                  motion.yAt(t, runner, outbound: outbound),
                  inInclusiveRange(
                    motion.geometry.minimum,
                    motion.geometry.maximum,
                  ),
                );
                expect(
                  velocity(t).abs(),
                  inInclusiveRange(.025, .42),
                  reason:
                      'speed bound seed=$seed scale=$scale outbound=$outbound runner=$runner t=$t',
                );
              }
            }
            if (roundLegalSamples == 0) {
              roundsWithoutLegalWindow++;
              noLegalWindowCases.add(
                'seed=$seed scale=$scale flight=$flightSeconds outbound=$outbound',
              );
            }
          }
        }
      }
    }
    expect(legalSamples, greaterThan(0));
    expect(forwardBlockedSamples, greaterThan(0));
    expect(legalSamples, lessThan(totalSamples));
    expect(forwardBlockedSamples, lessThan(totalSamples));
    // Measurement only: this test does not impose a maximum return wait.
    print(
        'legal=$legalSamples/$totalSamples (${(100 * legalSamples / totalSamples).toStringAsFixed(1)}%), forward-blocked=$forwardBlockedSamples, roundsWithoutLegalWindow=$roundsWithoutLegalWindow/$measuredRounds, longest-blocked-sample-run=$longestBlockedRun');
    print('no legal window cases=$noLegalWindowCases');
  });

  test('真横入力は上下どちらの攻撃でも前方反則にならない', () {
    for (final outbound in [true, false]) {
      expect(
        PassAndRunRules.isForwardDirection(
          deltaX: outbound ? 100 : -100,
          deltaY: 0,
          outbound: outbound,
        ),
        isFalse,
      );
    }
  });

  test('独立移動は合法角度と前方禁止角度の両方を実際に作る', () {
    final playableSeeds = {
      for (final outbound in [true, false]) outbound: <int>[]
    };
    var totalRounds = 0;
    var roundsWithoutLegalDirection = 0;
    var roundsWithoutForwardBlockedDirection = 0;
    var legalDirections = 0;
    var forwardBlockedDirections = 0;
    for (var seed = 0; seed < 128; seed++) {
      final motion = PassRunMotion(seed: seed);
      for (final outbound in [true, false]) {
        totalRounds++;
        var foundLegal = false;
        var foundForwardBlocked = false;
        for (var step = 0; step <= 145; step++) {
          final t = step / 10;
          final playerY =
              motion.yAt(t, PassRunRunner.player, outbound: outbound);
          final mateY =
              motion.yAt(t + .44, PassRunRunner.companion, outbound: outbound);
          final dy = (mateY - playerY) * 500;
          final direction = PassAndRunRules.userPassDirection(
            PassFlick(
              deltaX: 187.5,
              deltaY: dy,
              velocityX: 1875,
              velocityY: dy * 10,
            ),
            outbound: outbound,
          );
          if (PassAndRunRules.isForwardDirection(
            deltaX: direction.deltaX,
            deltaY: direction.deltaY,
            outbound: outbound,
          )) {
            foundForwardBlocked = true;
            forwardBlockedDirections++;
          } else {
            foundLegal = true;
            legalDirections++;
          }
        }
        if (foundLegal) playableSeeds[outbound]!.add(seed);
        if (!foundLegal) roundsWithoutLegalDirection++;
        if (!foundForwardBlocked) roundsWithoutForwardBlockedDirection++;
      }
    }
    expect(playableSeeds.values.any((seeds) => seeds.isNotEmpty), isTrue);
    expect(legalDirections, greaterThan(0));
    expect(forwardBlockedDirections, greaterThan(0));
    print(
        'user-aim rounds without a legal window=$roundsWithoutLegalDirection/$totalRounds; rounds without a forward-blocked direction=$roundsWithoutForwardBlockedDirection; legal/blocked samples=$legalDirections/$forwardBlockedDirections; first outbound seeds=${playableSeeds[true]!.take(12).toList()}, return seeds=${playableSeeds[false]!.take(12).toList()}');
  });

  test('ゲーム寸法・補正後の経路で合法窓と横だけの捕球率を測定する', () {
    const field = Size(768, 390);
    final geometry = PassRunFieldGeometry(field);
    final scale = geometry.actorSize / 112;
    const forwardRadius = 27.549925049569 / 2;
    const receiverRadius = 30.956565121244 / 2;
    final speed = field.width * .5 / .44;
    final catchableSeeds = {
      for (final up in [true, false]) up: <int>[]
    };
    var legalSamples = 0;
    var forwardBlockedSamples = 0;
    var horizontalCatches = 0;
    var userAimedCatches = 0;
    var attempts = 0;
    final firstCatchTime = {
      for (final up in [true, false]) up: <int, double>{}
    };

    bool catches({
      required PassRunMotion motion,
      required double seconds,
      required bool outbound,
      required Offset direction,
    }) {
      if (direction.distance == 0) return false;
      final unit = direction / direction.distance;
      final playerX = field.width * (outbound ? .25 : .75);
      final mateX = field.width * (outbound ? .75 : .25);
      final heldOffsetX = (outbound ? -13.51197411 : 13.51197411) * scale;
      final origin = Offset(
        playerX + heldOffsetX,
        field.height *
                motion.yAt(seconds, PassRunRunner.player, outbound: outbound) +
            8.919093226667 * scale,
      );
      final crossing = (mateX - origin.dx) / (unit.dx * speed);
      if (!crossing.isFinite || crossing <= 0) return false;
      double radius(double time) =>
          (forwardRadius +
              (receiverRadius - forwardRadius) * (time / .22).clamp(0.0, 1.0) +
              24) *
          scale;
      final halfWindow = radius(crossing) / (unit.dx.abs() * speed);
      final from = math.max(0.0, crossing - halfWindow);
      final to = crossing + halfWindow;
      Offset relative(double time) {
        final ball = origin + unit * speed * time;
        final mate = Offset(
          mateX,
          field.height *
              motion.yAt(seconds + time, PassRunRunner.companion,
                  outbound: outbound),
        );
        return ball - mate;
      }

      final start = relative(from), end = relative(to);
      return PassAndRunRules.sweptCollision(
            startX: start.dx,
            startY: start.dy,
            endX: end.dx,
            endY: end.dy,
            startRadius: radius(from),
            endRadius: radius(to),
          ) !=
          null;
    }

    for (var seed = 0; seed < 128; seed++) {
      final motion = PassRunMotion(seed: seed)..updateFieldGeometry(field);
      for (final outbound in [true, false]) {
        var hasCatchableAim = false;
        for (var step = 0; step <= 145; step++) {
          final seconds = step / 10;
          final playerX = field.width * (outbound ? .25 : .75);
          final mateX = field.width * (outbound ? .75 : .25);
          final start = Offset(
            playerX + (outbound ? -13.51197411 : 13.51197411) * scale,
            field.height *
                    motion.yAt(seconds, PassRunRunner.player,
                        outbound: outbound) +
                8.919093226667 * scale,
          );
          final dx = mateX - start.dx;
          var travel = .44;
          Offset aim = Offset.zero;
          for (var iteration = 0; iteration < 24; iteration++) {
            final targetY = field.height *
                motion.yAt(seconds + travel, PassRunRunner.companion,
                    outbound: outbound);
            aim = Offset(dx, targetY - start.dy);
            final raw = aim / aim.distance;
            travel = dx / (raw.dx * speed);
          }
          final userDirection = PassAndRunRules.userPassDirection(
            PassFlick(
              deltaX: aim.dx,
              deltaY: aim.dy,
              velocityX: aim.dx * 10,
              velocityY: aim.dy * 10,
            ),
            outbound: outbound,
          );
          final legal = !PassAndRunRules.isForwardDirection(
            deltaX: userDirection.deltaX,
            deltaY: userDirection.deltaY,
            outbound: outbound,
          );
          attempts++;
          if (legal) {
            legalSamples++;
            final caught = catches(
              motion: motion,
              seconds: seconds,
              outbound: outbound,
              direction: Offset(userDirection.deltaX, userDirection.deltaY),
            );
            hasCatchableAim |= caught;
            if (caught) {
              userAimedCatches++;
              firstCatchTime[outbound]!.putIfAbsent(seed, () => seconds);
            }
          } else {
            forwardBlockedSamples++;
          }

          if (catches(
            motion: motion,
            seconds: seconds,
            outbound: outbound,
            direction: Offset(dx, 0),
          )) {
            horizontalCatches++;
          }
          expect(
            PassAndRunRules.isForwardDirection(
              deltaX: dx,
              deltaY: 0,
              outbound: outbound,
            ),
            isFalse,
          );
        }
        if (hasCatchableAim) catchableSeeds[outbound]!.add(seed);
      }
    }
    expect(legalSamples, greaterThan(0));
    expect(forwardBlockedSamples, greaterThan(0));
    expect(legalSamples + forwardBlockedSamples, attempts);
    expect(horizontalCatches, greaterThan(0));
    expect(horizontalCatches, lessThan(attempts));
    expect(userAimedCatches, greaterThan(0));
    print(
        'widget geometry=$field legal=${(100 * legalSamples / attempts).toStringAsFixed(1)}% forward-blocked=${(100 * forwardBlockedSamples / attempts).toStringAsFixed(1)}%; corrected-aim catches=$userAimedCatches/$legalSamples; horizontal-only catches=$horizontalCatches/$attempts (${(100 * horizontalCatches / attempts).toStringAsFixed(1)}%); catchable seeds outbound=${catchableSeeds[true]!.take(12).toList()} return=${catchableSeeds[false]!.take(12).toList()}');
    print(
        'first actual catch times outbound=${firstCatchTime[true]!.entries.take(12).toList()} return=${firstCatchTime[false]!.entries.take(12).toList()}');
  });
}
