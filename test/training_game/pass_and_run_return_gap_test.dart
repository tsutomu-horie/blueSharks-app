import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_motion.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_return_sprint.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/pass_and_run/pass_and_run_pace_assist.dart';

const _halfFieldSeconds = .44;
const _tick = .008;

double _basePosition(PassRunMotion motion, double at, bool outbound) {
  final span = motion.geometry.movementRadius * 2;
  return (motion.yAt(at, PassRunRunner.companion, outbound: outbound) -
          motion.geometry.minimum) /
      span;
}

double _baseVelocity(PassRunMotion motion, double at, bool outbound) {
  final span = motion.geometry.movementRadius * 2;
  return (motion.worldVelocityYAt(at, PassRunRunner.companion,
              outbound: outbound) +
          (outbound ? 1 : -1) * motion.runningForwardRate) /
      span;
}

double _interceptTime({
  required Size field,
  required double seconds,
  required double originY,
  required double Function(double) targetY,
  required double halfFieldTravelSeconds,
}) {
  final speed = field.width * .5 / halfFieldTravelSeconds;
  final maxFlight = (field.width + field.height + 224) / speed;
  var low = 0.0, high = maxFlight;
  for (var i = 0; i < 40; i++) {
    final mid = (low + high) / 2;
    final vertical = (targetY(seconds + mid) - originY).abs();
    final distance = math.sqrt(
        math.pow(field.width * .5, 2) + math.pow(vertical * field.height, 2));
    if (distance > speed * mid) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return high;
}

double? _firstLegalPlayerPassWait({
  required PassRunMotion motion,
  required Size field,
  required double roundSeconds,
  required bool outbound,
  required double halfFieldTravelSeconds,
}) {
  final span = motion.geometry.movementRadius * 2;
  double basePosition(double at) {
    final y = motion.yAt(at, PassRunRunner.player, outbound: outbound);
    return (y - motion.geometry.minimum) / span;
  }

  double baseVelocity(double at) =>
      (motion.worldVelocityYAt(at, PassRunRunner.player, outbound: outbound) +
          (outbound ? 1 : -1) * motion.runningForwardRate) /
      span;
  PassRunPaceAssist? assist;
  double? blockedSince, lastDecisionAt;
  for (var tick = 0; tick * _tick < roundSeconds; tick++) {
    final at = tick * _tick;
    double playerY(double t) =>
        motion.geometry.minimum +
        span * (assist?.positionAt(t) ?? basePosition(t));
    double mateY(double t) =>
        motion.yAt(t, PassRunRunner.companion, outbound: outbound);
    final directionY = mateY(at) - playerY(at);
    final blocked = outbound ? directionY < 0 : directionY > 0;
    if (!blocked) {
      blockedSince = null;
      assist?.release(at);
    } else {
      blockedSince ??= at;
      if (at - blockedSince >= .65 &&
          (lastDecisionAt == null || at - lastDecisionAt >= .35)) {
        final forecastSeconds = roundSeconds + PassRunMotion.maxForecastSeconds;
        final phaseRoom = math.max(
          0.0,
          PassRunMotion.trajectoryProfileHorizonSeconds /
                  motion.runningSpeedScale -
              forecastSeconds,
        );
        final maximumRate = math.min(
          1.12,
          1 + phaseRoom / (forecastSeconds * 1.25),
        );
        PassRunPaceAssist? selected;
        var bestCost = double.infinity;
        for (final rate in [1.0, maximumRate, .88]) {
          final candidate = PassRunPaceAssist(
            start: at,
            normalPosition: basePosition,
            normalVelocity: baseVelocity,
            targetRate: rate,
            attackUp: outbound,
            previous: assist,
          );
          var firstLegal = 3.05, deficit = 0.0;
          for (var forecast = 1; forecast <= 60; forecast++) {
            final ahead = forecast * .05;
            final difference = (mateY(at + ahead) -
                    (motion.geometry.minimum +
                        span * candidate.positionAt(at + ahead))) *
                (outbound ? 1 : -1);
            if (difference >= .01 && firstLegal > 3) firstLegal = ahead;
            deficit += math.max(0, -difference) * (1 - ahead / 4);
          }
          final cost = firstLegal * 100 + deficit;
          if (cost < bestCost) {
            bestCost = cost;
            selected = candidate;
          }
        }
        assist = selected!;
        lastDecisionAt = at;
      }
    }
    final originY = playerY(at);
    final flight = _interceptTime(
      field: field,
      seconds: at,
      originY: originY,
      targetY: mateY,
      halfFieldTravelSeconds: halfFieldTravelSeconds,
    );
    final delta = mateY(at + flight) - originY;
    if (outbound ? delta >= 0 : delta <= 0) return at;
  }
  return null;
}

PassRunReturnSprint _startSprint({
  required PassRunMotion motion,
  required bool outbound,
  required double start,
  PassRunReturnSprint? previous,
  required double roundSeconds,
  required double boostSpeed,
  required double boostAcceleration,
  required double recoverySpeedScale,
}) {
  final span = motion.geometry.movementRadius * 2;
  double position(double at) => _basePosition(motion, at, outbound);
  double velocity(double at) => _baseVelocity(motion, at, outbound);
  return PassRunReturnSprint(
    start: start,
    position: previous?.positionAt(start) ?? position(start),
    velocity: previous?.velocityAt(start) ?? velocity(start),
    acceleration: previous?.accelerationAt(start) ??
        (velocity(start + .001) - velocity(start)) / .001,
    minimum: 0,
    maximum: 1,
    attackUp: outbound,
    normalPosition: position,
    normalVelocity: velocity,
    end: roundSeconds + 6,
    normalSpeed: .18 * motion.runningSpeedScale / span * recoverySpeedScale,
    boostSpeed: boostSpeed,
    boostAcceleration: boostAcceleration,
  );
}

/// Models the live cycle: a successful catch starts the mate sprint; the
/// return launches at the first 8 ms ticker where its future receiver point is
/// legal; the return uses the configured fixed ball speed; and the next user
/// pass is legal only when the mate's predicted intercept is behind the holder.
({
  List<double> waits,
  List<double> inRoundWaits,
  List<double> switchWaits,
  List<double> catchToReturn,
  int missedReturns,
  int censored
}) _waitsAfterReturns({
  required PassRunMotion motion,
  required Size field,
  required bool outbound,
  required double roundSeconds,
  required double caughtAt,
  required double halfFieldTravelSeconds,
  required double boostSpeed,
  required double boostAcceleration,
  required double recoverySpeedScale,
  bool sprintAfterCatch = true,
  bool relativeRecovery = false,
  int repeatPasses = 3,
}) {
  final span = motion.geometry.movementRadius * 2;
  PassRunReturnSprint? sprint = sprintAfterCatch
      ? _startSprint(
          motion: motion,
          outbound: outbound,
          start: caughtAt,
          roundSeconds: roundSeconds,
          boostSpeed: boostSpeed,
          boostAcceleration: boostAcceleration,
          recoverySpeedScale: recoverySpeedScale,
        )
      : null;
  var caught = caughtAt;
  final waits = <double>[];
  final inRoundWaits = <double>[];
  final switchWaits = <double>[];
  final catchToReturn = <double>[];
  var missedReturns = 0;
  var censored = 0;
  PassRunPaceAssist? playerAssist;
  double? blockedSince, lastPaceDecisionAt;

  double normalPlayerPosition(double at) {
    final y = motion.yAt(at, PassRunRunner.player, outbound: outbound);
    return (y - motion.geometry.minimum) / span;
  }

  double normalPlayerVelocity(double at) =>
      (motion.worldVelocityYAt(at, PassRunRunner.player, outbound: outbound) +
          (outbound ? 1 : -1) * motion.runningForwardRate) /
      span;

  double mateFraction(double at) =>
      sprint?.positionAt(at) ?? _basePosition(motion, at, outbound);

  double playerY(double at) =>
      motion.geometry.minimum +
      span * (playerAssist?.positionAt(at) ?? normalPlayerPosition(at));

  void updatePlayerAssist(double at,
      {required bool mateCarrier, required bool playerCarrier}) {
    if (!mateCarrier && !playerCarrier) {
      blockedSince = null;
      playerAssist?.release(at);
      return;
    }
    final mateNow = motion.geometry.minimum + span * mateFraction(at);
    final directionY = mateCarrier
        ? playerY(at +
                _interceptTime(
                  field: field,
                  seconds: at,
                  originY: mateNow,
                  targetY: playerY,
                  halfFieldTravelSeconds: halfFieldTravelSeconds,
                )) -
            mateNow
        : mateNow - playerY(at);
    final blocked = outbound ? directionY < 0 : directionY > 0;
    if (!blocked) {
      blockedSince = null;
      playerAssist?.release(at);
      return;
    }
    blockedSince ??= at;
    if (at - blockedSince! < (mateCarrier ? .25 : .65) ||
        (lastPaceDecisionAt != null && at - lastPaceDecisionAt! < .35)) {
      return;
    }
    final forecastSeconds = roundSeconds + PassRunMotion.maxForecastSeconds;
    final phaseRoom = math.max(
      0,
      PassRunMotion.trajectoryProfileHorizonSeconds / motion.runningSpeedScale -
          forecastSeconds,
    );
    final maximumRate = math.min(
      1.12,
      1 + phaseRoom / (forecastSeconds * 1.25),
    );
    final previous = playerAssist;
    final candidates = <PassRunPaceAssist>[];
    var bestCost = double.infinity;
    for (final rate in [1.0, maximumRate, .88]) {
      final candidate = PassRunPaceAssist(
        start: at,
        normalPosition: normalPlayerPosition,
        normalVelocity: normalPlayerVelocity,
        targetRate: rate,
        attackUp: outbound,
        previous: previous,
      );
      var firstLegal = 3.05, deficit = 0.0;
      for (var tick = 1; tick <= 60; tick++) {
        final ahead = tick * .05;
        final mateFuture =
            motion.geometry.minimum + span * mateFraction(at + ahead);
        final difference = (mateCarrier
                ? candidate.positionAt(at + ahead) * span +
                    motion.geometry.minimum -
                    mateFuture
                : mateFuture -
                    (candidate.positionAt(at + ahead) * span +
                        motion.geometry.minimum)) *
            (outbound ? 1 : -1);
        if (difference >= .01 && firstLegal > 3) firstLegal = ahead;
        deficit += math.max(0, -difference) * (1 - ahead / 4);
      }
      final cost = firstLegal * 100 + deficit;
      if (cost < bestCost) {
        bestCost = cost;
        candidates
          ..clear()
          ..add(candidate);
      }
    }
    playerAssist = candidates.single;
    lastPaceDecisionAt = at;
  }

  for (var pass = 0; pass < repeatPasses; pass++) {
    double mateY(double at) =>
        motion.geometry.minimum + span * mateFraction(at);

    var returnStart = caught + .096;
    var releaseFlight = 0.0;
    for (var tick = 1; caught + tick * _tick < roundSeconds; tick++) {
      final at = caught + tick * _tick;
      updatePlayerAssist(at, mateCarrier: true, playerCarrier: false);
      if (at + 1e-9 < caught + .096) continue;
      if (at >= roundSeconds) break;
      final originY = mateY(at);
      final flight = _interceptTime(
        field: field,
        seconds: at,
        originY: originY,
        targetY: playerY,
        halfFieldTravelSeconds: halfFieldTravelSeconds,
      );
      final delta = playerY(at + flight) - originY;
      if (outbound ? delta >= 0 : delta <= 0) {
        playerAssist?.release(at);
        final settledFlight = _interceptTime(
          field: field,
          seconds: at,
          originY: originY,
          targetY: playerY,
          halfFieldTravelSeconds: halfFieldTravelSeconds,
        );
        final settledDelta = playerY(at + settledFlight) - originY;
        if (outbound ? settledDelta < 0 : settledDelta > 0) continue;
        returnStart = at;
        releaseFlight = settledFlight;
        break;
      }
    }
    if (releaseFlight == 0) {
      missedReturns++;
      break;
    }

    // The production screen begins its return at this legal release and
    // releases the mate sprint before calculating the next send opportunity.
    double recoveryTarget(double at) {
      final playerFraction = (playerY(at) - motion.geometry.minimum) / span;
      final behind =
          PassRunReturnSprint.recoveryBehindFraction * (outbound ? 1 : -1);
      return (playerFraction + behind).clamp(.025, .975).toDouble();
    }

    sprint?.release(
      returnStart,
      recoveryTarget: relativeRecovery ? recoveryTarget : null,
    );
    blockedSince = null;
    final readyAt = returnStart + releaseFlight;
    if (readyAt >= roundSeconds) break;
    catchToReturn.add(readyAt - caught);

    var nextPassAt = readyAt;
    var foundNextPass = false;
    for (var tick = 1; readyAt + tick * _tick < roundSeconds; tick++) {
      final at = readyAt + tick * _tick;
      updatePlayerAssist(at, mateCarrier: false, playerCarrier: true);
      final originY = playerY(at);
      final flight = _interceptTime(
        field: field,
        seconds: at,
        originY: originY,
        targetY: mateY,
        halfFieldTravelSeconds: halfFieldTravelSeconds,
      );
      final delta = mateY(at + flight) - originY;
      if (outbound ? delta >= 0 : delta <= 0) {
        nextPassAt = at;
        foundNextPass = true;
        break;
      }
    }
    if (!foundNextPass) {
      if (outbound) {
        final afterTurn = _firstLegalPlayerPassWait(
          motion: motion,
          field: field,
          roundSeconds: roundSeconds,
          outbound: false,
          halfFieldTravelSeconds: halfFieldTravelSeconds,
        );
        if (afterTurn == null) {
          censored++;
        } else {
          final total = roundSeconds - readyAt + 1 + afterTurn;
          waits.add(total);
          switchWaits.add(total);
        }
      } else {
        censored++;
      }
      break;
    }
    waits.add(nextPassAt - readyAt);
    inRoundWaits.add(nextPassAt - readyAt);
    playerAssist?.release(nextPassAt);
    blockedSince = null;
    final userFlight = _interceptTime(
      field: field,
      seconds: nextPassAt,
      originY: playerY(nextPassAt),
      targetY: mateY,
      halfFieldTravelSeconds: halfFieldTravelSeconds,
    );
    caught = nextPassAt + userFlight;
    if (caught >= roundSeconds) break;
    if (sprintAfterCatch) {
      final previous = sprint;
      sprint = _startSprint(
        motion: motion,
        outbound: outbound,
        start: caught,
        previous: previous,
        roundSeconds: roundSeconds,
        boostSpeed: boostSpeed,
        boostAcceleration: boostAcceleration,
        recoverySpeedScale: recoverySpeedScale,
      );
    }
  }
  return (
    waits: waits,
    inRoundWaits: inRoundWaits,
    switchWaits: switchWaits,
    catchToReturn: catchToReturn,
    missedReturns: missedReturns,
    censored: censored,
  );
}

void main() {
  test('返球完了後から次の合法パスまでを変更前後で定量比較する', () {
    const field = Size(390, 700);
    const tunings = [
      (
        speed: 1.0,
        acceleration: 3.5,
        recovery: 1.0,
        sprint: true,
        relativeRecovery: false,
      ),
      (
        speed: 1.0,
        acceleration: 3.5,
        recovery: 1.0,
        sprint: true,
        relativeRecovery: true,
      ),
    ];
    final reports = <bool,
        ({
      double p95,
      double max,
      double inRoundP95,
      double inRoundMax,
      double switchP95,
      double switchMax,
      double returnP95,
      double returnMax,
      int samples,
      int missedReturns,
      int censored,
    })>{};
    final firstEventWaits = <bool, Map<String, double>>{};
    for (final tuning in tunings) {
      final waits = <double>[];
      final inRoundWaits = <double>[];
      final switchWaits = <double>[];
      final returns = <double>[];
      var missedReturns = 0;
      var censored = 0;
      final waitsByScenario = <String, double>{};
      for (var seed = 0; seed < 8; seed++) {
        for (final scale in PassRunMotion.supportedMotionScales) {
          final motion = PassRunMotion(seed: seed, speedScale: scale)
            ..updateFieldGeometry(field);
          for (final outbound in [true, false]) {
            for (final caught in [0.0, 2.5, 5.0, 7.5, 10.0]) {
              final result = _waitsAfterReturns(
                motion: motion,
                field: field,
                outbound: outbound,
                roundSeconds: 15,
                caughtAt: caught,
                halfFieldTravelSeconds: _halfFieldSeconds,
                boostSpeed: tuning.speed,
                boostAcceleration: tuning.acceleration,
                recoverySpeedScale: tuning.recovery,
                sprintAfterCatch: tuning.sprint,
                relativeRecovery: tuning.relativeRecovery,
              );
              waits.addAll(result.waits);
              inRoundWaits.addAll(result.inRoundWaits);
              switchWaits.addAll(result.switchWaits);
              returns.addAll(result.catchToReturn);
              missedReturns += result.missedReturns;
              censored += result.censored;
              if (result.waits.isNotEmpty) {
                waitsByScenario['$seed|$scale|$outbound|$caught'] =
                    result.waits.first;
              }
            }
          }
        }
      }
      waits.sort();
      inRoundWaits.sort();
      switchWaits.sort();
      returns.sort();
      expect(waits, isNotEmpty);
      final p95 =
          waits[(waits.length * .95).floor().clamp(0, waits.length - 1)];
      final returnP95 =
          returns[(returns.length * .95).floor().clamp(0, returns.length - 1)];
      final inRoundP95 = inRoundWaits[(inRoundWaits.length * .95)
          .floor()
          .clamp(0, inRoundWaits.length - 1)];
      final switchP95 = switchWaits[
          (switchWaits.length * .95).floor().clamp(0, switchWaits.length - 1)];
      reports[tuning.relativeRecovery] = (
        p95: p95,
        max: waits.last,
        inRoundP95: inRoundP95,
        inRoundMax: inRoundWaits.last,
        switchP95: switchP95,
        switchMax: switchWaits.last,
        returnP95: returnP95,
        returnMax: returns.last,
        samples: waits.length,
        missedReturns: missedReturns,
        censored: censored,
      );
      firstEventWaits[tuning.relativeRecovery] = waitsByScenario;
      // ignore: avoid_print
      print(
          'relativeRecovery=${tuning.relativeRecovery} boost=${tuning.speed.toStringAsFixed(2)} accel=${tuning.acceleration.toStringAsFixed(1)} post-return n=${waits.length} p95=${p95.toStringAsFixed(3)}s max=${waits.last.toStringAsFixed(3)}s inRound=${inRoundWaits.length} p95=${inRoundP95.toStringAsFixed(3)}s max=${inRoundWaits.last.toStringAsFixed(3)}s switch=${switchWaits.length} p95=${switchP95.toStringAsFixed(3)}s max=${switchWaits.last.toStringAsFixed(3)}s; catch-to-return p95=${returnP95.toStringAsFixed(3)}s max=${returns.last.toStringAsFixed(3)}s missedReturn=$missedReturns censoredInbound=$censored');
    }

    final before = reports[false]!;
    final after = reports[true]!;
    // Pair only the first return event for an identical seed/scale/direction/
    // catch-time scenario; later repeated passes can diverge by design.
    final pairedKeys = firstEventWaits[false]!
        .keys
        .toSet()
        .intersection(firstEventWaits[true]!.keys.toSet());
    final pairedBefore =
        pairedKeys.map((key) => firstEventWaits[false]![key]!).toList()..sort();
    final pairedAfter =
        pairedKeys.map((key) => firstEventWaits[true]![key]!).toList()..sort();
    final pairedImprovements = pairedKeys
        .map((key) =>
            firstEventWaits[false]![key]! - firstEventWaits[true]![key]!)
        .toList()
      ..sort();
    final improvedPairs = pairedImprovements.where((value) => value > 0).length;
    expect(pairedKeys.length, greaterThan(20));
    final pairedBeforeP95 = pairedBefore[
        (pairedBefore.length * .95).floor().clamp(0, pairedBefore.length - 1)];
    final pairedAfterP95 = pairedAfter[
        (pairedAfter.length * .95).floor().clamp(0, pairedAfter.length - 1)];
    // ignore: avoid_print
    print(
        'paired first-return events n=${pairedKeys.length}; p95=${pairedBeforeP95.toStringAsFixed(3)}s -> ${pairedAfterP95.toStringAsFixed(3)}s; max=${pairedBefore.last.toStringAsFixed(3)}s -> ${pairedAfter.last.toStringAsFixed(3)}s; improved pairs=$improvedPairs/${pairedKeys.length}, median wait reduction=${pairedImprovements[pairedImprovements.length ~/ 2].toStringAsFixed(3)}s');
    expect(pairedAfterP95, lessThan(pairedBeforeP95));
    expect(pairedAfter.last, lessThan(pairedBefore.last));
    expect(improvedPairs, greaterThan(pairedKeys.length ~/ 2));
    expect(after.returnP95, lessThan(before.returnP95 + .1));
    expect(after.returnMax, lessThan(before.returnMax + .1));
  });
}
