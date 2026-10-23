import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 実際のキャラと名前を収めるフィールド内の中心座標。
class PassRunFieldGeometry {
  PassRunFieldGeometry(this.field);
  final Size field;
  double get actorSize =>
      .75 * math.min(112, math.min(field.height * .4, field.width * .5));
  double get labelScale =>
      math.min(1.0, math.max(0.0, field.height * .22 - actorSize / 2 - 2) / 16);
  double get minimum =>
      (8 + actorSize / 2 + 16 * labelScale + 2) / field.height;
  double get maximum => 1 - (8 + actorSize / 2) / field.height;
  double get middle => (minimum + maximum) / 2;
  double get movementRadius => math.max(0.0, (maximum - minimum) / 2);
}

enum PassRunFacing { front, back }

enum PassRunRunner { player, companion }

/// 1プレイ中は固定する走行プロファイル。
/// 次のプレイは別seed、復路は別乱数列。表示の脚位相と衝突時計は分離します。
class PassRunMotion {
  PassRunMotion({
    required int seed,
    this.roundSeconds = 15,
    double speedScale = PassRunMotion.speedScale,
  })  : runningSpeedScale = speedScale,
        _outgoing = _PassRunTrajectory(seed, speedScale),
        _incoming = _PassRunTrajectory(seed ^ 0x54a1, speedScale) {
    _outgoing.adaptLongForwardOnlyIntervals(outbound: true);
    _incoming.adaptLongForwardOnlyIntervals(outbound: false);
  }
  static const speedScale = 1.15;
  // Keep the whole trajectory defined for every server-supported setting.
  // The random profile must not freeze at its final knot before a 30 s round
  // running at scale 1.25 has elapsed.
  static const maxSupportedSpeedScale = 1.25;
  static const minimumSupportedSpeedScale = .85;
  static const maxRoundSeconds = 30.0;
  static const maxForecastSeconds = 6.0;
  static const profileMarginSeconds = 1.0;
  static const maximumPassFlightForecastSeconds = .65;
  static const passFlightForecastDurations = [
    .35,
    maximumPassFlightForecastSeconds,
  ];
  static const supportedMotionScales = [
    minimumSupportedSpeedScale,
    speedScale,
    maxSupportedSpeedScale,
  ];

  /// After this long without the mate reaching a legal side, bias only the
  /// next independently sampled target so a natural overtake can happen.
  // Profile time is scaled in play; this yields a 0.15 s wait at the default
  // 1.15 movement scale. The randomized next-target reroll remains bounded
  // and changes only after a prolonged one-sided interval.
  static const noPassTargetRerollThresholdSeconds = speedScale * .15;
  static const trajectoryProfileHorizonSeconds =
      (maxRoundSeconds + maxForecastSeconds) * maxSupportedSpeedScale +
          profileMarginSeconds;
  static const forwardRate = .18 * speedScale;
  static const facingSettleSeconds = .08;
  static const turnDuration = Duration(milliseconds: 1000);
  PassRunFieldGeometry geometry = PassRunFieldGeometry(const Size(375, 500));
  void updateFieldGeometry(Size field) {
    if (field.width <= 0 || field.height <= 0) return;
    geometry = PassRunFieldGeometry(field);
    _outgoing.geometry = geometry;
    _incoming.geometry = geometry;
  }

  final double roundSeconds;
  final double runningSpeedScale;
  double get runningForwardRate => .18 * runningSpeedScale;
  final _PassRunTrajectory _outgoing, _incoming;
  _PassRunTrajectory _trajectory(bool outbound) =>
      outbound ? _outgoing : _incoming;
  double yAt(double seconds, PassRunRunner runner, {bool outbound = true}) =>
      _trajectory(outbound)
          .y(seconds, runner == PassRunRunner.companion, outbound);
  double worldVelocityYAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) =>
      _trajectory(outbound)
          .speed(seconds, runner == PassRunRunner.companion, outbound);
  double distanceAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) =>
      _trajectory(outbound)
          .distance(seconds, runner == PassRunRunner.companion, outbound);
  static ({PassRunFacing from, PassRunFacing to, double progress}) facingAt(
    double seconds,
    PassRunRunner runner, {
    bool outbound = true,
  }) {
    final facing = outbound ? PassRunFacing.back : PassRunFacing.front;
    return (from: facing, to: facing, progress: 1);
  }

  /// 交換中央で前後順が逆でも本人と仲間・名前が重ならない回避経路。
  /// 小さい画面ではキャラ寸法に比例して回避幅も縮めます。
  Offset turnOffset(
    double progress,
    PassRunRunner runner, {
    required Size field,
    required double actorSize,
    double? mateStartY,
    double? playerStartY,
  }) {
    final mate = runner == PassRunRunner.companion;
    final start = Offset(
      field.width * (mate ? .75 : .25),
      field.height *
          (mate
              ? mateStartY ?? yAt(roundSeconds, runner)
              : playerStartY ?? yAt(roundSeconds, runner)),
    );
    final end = Offset(
      field.width * (mate ? .25 : .75),
      field.height * yAt(0, runner, outbound: false),
    );
    final geometry = PassRunFieldGeometry(field);
    final playerStart = field.height *
        (playerStartY ?? yAt(roundSeconds, PassRunRunner.player));
    final mateStart = field.height *
        (mateStartY ?? yAt(roundSeconds, PassRunRunner.companion));
    final clearance = actorSize + 16 * geometry.labelScale + 4;
    final middle = ((playerStart + mateStart) / 2).clamp(
      8 + actorSize / 2 + clearance / 2,
      field.height - 8 - actorSize / 2 - clearance / 2,
    );
    final separated = (playerStart - mateStart).abs() >= clearance;
    final stageY =
        separated ? start.dy : middle + (mate ? -1 : 1) * clearance / 2;
    final stage = Offset(start.dx, stageY);
    final exchanged = Offset(end.dx, stage.dy);
    double ease(double value) =>
        Curves.easeInOut.transform(value.clamp(0.0, 1.0));
    final horizontal = start.dx + (end.dx - start.dx) * ease(progress);
    final y = progress < .25
        ? start.dy + (stage.dy - start.dy) * ease(progress / .25)
        : progress < .75
            ? stage.dy
            : exchanged.dy +
                (end.dy - exchanged.dy) * ease((progress - .75) / .25);
    return Offset(horizontal, y);
  }

  static PassRunFacing facingForVelocity(
    double velocityY, {
    required PassRunFacing previous,
  }) {
    if (!velocityY.isFinite || velocityY.abs() <= 1e-9) return previous;
    return velocityY > 0 ? PassRunFacing.front : PassRunFacing.back;
  }
}

/// 2人の独立した移動軌道を共有フィールド境界へ写像します。
class _PassRunTrajectory {
  _PassRunTrajectory(int seed, this.speedFactor)
      : _seed = seed,
        _player = _RunnerTrajectory(
          seed ^ 0x2f1bbcdc,
          PassRunMotion.trajectoryProfileHorizonSeconds,
        ),
        _companion = _RunnerTrajectory(
          seed ^ 0x6d2b79f5,
          PassRunMotion.trajectoryProfileHorizonSeconds,
        );
  final double speedFactor;
  final int _seed;
  final _RunnerTrajectory _player;
  final _RunnerTrajectory _companion;
  PassRunFieldGeometry geometry = PassRunFieldGeometry(const Size(375, 500));
  _RunnerTrajectory _runner(bool mate) => mate ? _companion : _player;

  /// A long one-sided interval changes only one runner's next few random
  /// targets. The other runner keeps its independent curve; this creates a
  /// chance to overtake without snapping either actor to a legal location.
  void adaptLongForwardOnlyIntervals({
    required bool outbound,
  }) {
    const sampleSeconds = .02;
    final random = math.Random(_seed ^ (outbound ? 0x1b4d : 0x7e21));
    final flightWindows = [
      for (final duration in PassRunMotion.passFlightForecastDurations)
        for (final scale in PassRunMotion.supportedMotionScales)
          duration * scale,
    ];
    final playerCarrierBlockedSeconds =
        List<double>.filled(flightWindows.length, 0);
    final mateCarrierBlockedSeconds =
        List<double>.filled(flightWindows.length, 0);
    var assistCount = 0;
    const assistLimit = 44;
    final baselineReversals = _relativeOrderReversals();

    // Build the same deterministic trajectory regardless of the configured
    // round length or movement scale. Scale only changes how quickly the
    // existing profile is traversed during play.
    final adaptationHorizon =
        PassRunMotion.maxRoundSeconds * PassRunMotion.maxSupportedSpeedScale;
    for (var trajectorySeconds = 0.0;
        trajectorySeconds <= adaptationHorizon && assistCount < assistLimit;
        trajectorySeconds += sampleSeconds) {
      final playerNow = _player.position(trajectorySeconds);
      final mateNow = _companion.position(trajectorySeconds);
      // Track both carriers independently. A player-to-mate legal window does
      // not imply a mate-to-player return window, and vice versa.
      final due = <(bool mateCarrier, int flightIndex)>[];
      for (var i = 0; i < flightWindows.length; i++) {
        final flight = flightWindows[i];
        final playerFuture = _player.position(trajectorySeconds + flight);
        final mateFuture = _companion.position(trajectorySeconds + flight);
        // y() mirrors the incoming screen coordinates, and the attack
        // direction mirrors too. Raw trajectory legality is the same both ways.
        final playerCarrierBlocked = mateFuture < playerNow;
        final mateCarrierBlocked = playerFuture < mateNow;
        playerCarrierBlockedSeconds[i] = playerCarrierBlocked
            ? playerCarrierBlockedSeconds[i] + sampleSeconds
            : 0;
        mateCarrierBlockedSeconds[i] = mateCarrierBlocked
            ? mateCarrierBlockedSeconds[i] + sampleSeconds
            : 0;
        if (playerCarrierBlocked &&
            playerCarrierBlockedSeconds[i] + 1e-9 >=
                PassRunMotion.noPassTargetRerollThresholdSeconds) {
          due.add((false, i));
        }
        if (mateCarrierBlocked &&
            mateCarrierBlockedSeconds[i] + 1e-9 >=
                PassRunMotion.noPassTargetRerollThresholdSeconds) {
          due.add((true, i));
        }
      }
      if (due.isEmpty) {
        continue;
      }

      // If both lanes are blocked, choose which carrier's next random target
      // to bias; do not synchronize the runners or force a legal position.
      double blockedFor((bool, int) request) => request.$1
          ? mateCarrierBlockedSeconds[request.$2]
          : playerCarrierBlockedSeconds[request.$2];
      final longest = due.map(blockedFor).reduce(math.max);
      final oldest = due.where((v) => blockedFor(v) >= longest - 1e-9).toList();
      final target = oldest[random.nextInt(oldest.length)];
      final blockedMateToPlayer = target.$1;
      final targetFlightSeconds = flightWindows[target.$2];
      final evaluationTime = trajectorySeconds <=
              PassRunMotion.noPassTargetRerollThresholdSeconds + .04
          ? 0.0
          : trajectorySeconds;
      final originalWait = _nextLegalWait(
        evaluationTime,
        targetFlightSeconds,
        mateCarrier: blockedMateToPlayer,
      );
      final originalOtherWait = _nextLegalWait(
        evaluationTime,
        targetFlightSeconds,
        mateCarrier: !blockedMateToPlayer,
      );
      var adjusted = false;
      final initialPlanning = evaluationTime == 0;
      List<double> candidateWaits() => [
            for (final flight in flightWindows)
              for (final carrier in [false, true])
                _nextLegalWait(evaluationTime, flight, mateCarrier: carrier),
          ];
      final originalWaits = initialPlanning
          ? candidateWaits()
          : [originalWait, originalOtherWait];
      var bestWorst = originalWaits.reduce(math.max);
      var bestTotal =
          originalWaits.fold<double>(0, (sum, value) => sum + value * value);
      bool? bestMate;
      List<double>? bestControls;
      final firstChoice = random.nextBool();
      for (final adjustMate in [firstChoice, !firstChoice]) {
        final actor = adjustMate ? _companion : _player;
        final originalControls = actor.snapshotControls();
        for (var candidate = 0;
            candidate < (initialPlanning ? 16 : 8);
            candidate++) {
          actor.restoreControls(originalControls);
          final trial =
              candidate == 0 ? target : due[random.nextInt(due.length)];
          final rerolled = actor.rerollNextGoalsAcross(
            fromTime: trajectorySeconds,
            other: adjustMate ? _player : _companion,
            targetLeadSeconds: flightWindows[trial.$2],
            targetHigherThanOther: adjustMate != trial.$1,
            random: random,
          );
          final nextWait = rerolled
              ? _nextLegalWait(evaluationTime, targetFlightSeconds,
                  mateCarrier: blockedMateToPlayer)
              : originalWait;
          final otherWait = rerolled
              ? _nextLegalWait(evaluationTime, targetFlightSeconds,
                  mateCarrier: !blockedMateToPlayer)
              : originalOtherWait;
          final waits = initialPlanning && rerolled
              ? candidateWaits()
              : [nextWait, otherWait];
          final worst = waits.reduce(math.max);
          final total =
              waits.fold<double>(0, (sum, value) => sum + value * value);
          final shortened = worst + .05 < bestWorst ||
              ((worst - bestWorst).abs() < 1e-9 && total + .05 < bestTotal);
          final useful = rerolled &&
              shortened &&
              _preservesMovementEnvelope(
                baselineReversals: baselineReversals,
              );
          if (useful) {
            bestWorst = worst;
            bestTotal = total;
            bestMate = adjustMate;
            bestControls = actor.snapshotControls();
          }
        }
        actor.restoreControls(originalControls);
      }
      if (bestControls != null) {
        _runner(bestMate!).restoreControls(bestControls);
        adjusted = true;
      }
      if (adjusted) {
        assistCount++;
        // A reroll changes both paths. Let the opposite carrier keep its
        // elapsed blocked time if it is still blocked; clearing both clocks
        // can repeatedly serve one role and starve a simultaneous return.
        if (blockedMateToPlayer) {
          mateCarrierBlockedSeconds.fillRange(0, flightWindows.length, 0.0);
        } else {
          playerCarrierBlockedSeconds.fillRange(0, flightWindows.length, 0.0);
        }
      } else if (blockedMateToPlayer) {
        mateCarrierBlockedSeconds.fillRange(0, flightWindows.length, 0.0);
      } else {
        playerCarrierBlockedSeconds.fillRange(0, flightWindows.length, 0.0);
      }
    }
  }

  double _nextLegalWait(double fromTime, double flightSeconds,
      {required bool mateCarrier}) {
    final carrier = mateCarrier ? _companion : _player;
    final receiver = mateCarrier ? _player : _companion;
    var consecutiveLegal = 0;
    final maximumWait = math.min(
      12.0,
      math.max(
          0.0,
          PassRunMotion.trajectoryProfileHorizonSeconds -
              fromTime -
              flightSeconds),
    );
    for (var tick = 0; tick * .1 <= maximumWait; tick++) {
      final wait = tick * .1;
      final legal = receiver.position(fromTime + wait + flightSeconds) >=
          carrier.position(fromTime + wait);
      consecutiveLegal = legal ? consecutiveLegal + 1 : 0;
      if (consecutiveLegal >= 2) return math.max(0.0, wait - .1);
    }
    return maximumWait + .1;
  }

  int _relativeOrderReversals() {
    var previousOrder = 0;
    var reversals = 0;
    for (var tick = 0; tick <= 150; tick++) {
      final seconds = tick * .1;
      final difference =
          _player.position(seconds) - _companion.position(seconds);
      if (difference.abs() < .01) continue;
      final order = difference.sign.toInt();
      if (previousOrder != 0 && order != previousOrder) reversals++;
      previousOrder = order;
    }
    return reversals;
  }

  bool _preservesMovementEnvelope({required int baselineReversals}) {
    // A no-pass adjustment may add a natural overtake, but it must not erase
    // the independently sampled movement range or reduce this seed's existing
    // order reversals. This keeps the adjustment from creating a new pattern.
    if (_relativeOrderReversals() < baselineReversals) return false;
    for (final trajectory in [_player, _companion]) {
      var minimum = 1.0;
      var maximum = 0.0;
      for (var tick = 0; tick <= 150; tick++) {
        final value = trajectory.position(tick * .1);
        minimum = math.min(minimum, value);
        maximum = math.max(maximum, value);
      }
      if (maximum - minimum < .2) return false;
    }
    return true;
  }

  double y(double seconds, bool mate, bool up) {
    final t = seconds * speedFactor;
    final fraction = _runner(mate).position(t);
    final oriented = up ? fraction : 1 - fraction;
    return geometry.minimum + geometry.movementRadius * 2 * oriented;
  }

  double speed(double seconds, bool mate, bool up) {
    final t = seconds * speedFactor;
    final fieldVelocity =
        _runner(mate).velocity(t) * geometry.movementRadius * 2 * speedFactor;
    return (up ? fieldVelocity : -fieldVelocity) +
        (up ? -.18 : .18) * speedFactor;
  }

  double distance(double t, bool mate, bool up) =>
      .18 * speedFactor * t + (up ? -1 : 1) * (y(t, mate, up) - y(0, mate, up));
}

/// Each runner gets independent random positions, intervals and distances.
/// The sampled points are continuous values within the same broad bounds; they
/// are not fixed slots or a repeating endpoint shuttle. A non-uniform cubic
/// B-spline keeps position, speed, and acceleration continuous.
class _RunnerTrajectory {
  _RunnerTrajectory(int seed, double horizonSeconds) {
    final random = math.Random(seed);
    final controlCount =
        (horizonSeconds / _targetAverageControlSpanSeconds).ceil() + _degree;
    final spanWeights = List<double>.generate(
      controlCount - _degree,
      (_) => .75 + random.nextDouble() * .5,
    );
    final totalWeight = spanWeights.fold(0.0, (sum, weight) => sum + weight);
    final knots = <double>[0, 0, 0, 0];
    var knotTime = 0.0;
    for (var i = 0; i < spanWeights.length - 1; i++) {
      knotTime += horizonSeconds * spanWeights[i] / totalWeight;
      knots.add(knotTime);
    }
    knots.addAll(List<double>.filled(_degree + 1, horizonSeconds));

    final controls = <double>[.025 + random.nextDouble() * .95];
    while (controls.length < controlCount) {
      final previousIndex = controls.length - 1;
      final knotSpan =
          knots[previousIndex + _degree + 1] - knots[previousIndex + 1];
      final maximumDistance = math.min(
        .4,
        _maximumNormalizedSpeed * knotSpan / _degree,
      );
      final minimumDistance = math.min(.20, maximumDistance * .5);
      final from = controls.last;
      var target = from;
      for (var attempt = 0; attempt < 16; attempt++) {
        target = .025 + random.nextDouble() * .95;
        final distance = (target - from).abs();
        if (distance < minimumDistance) continue;
        if (distance > maximumDistance) {
          target = from + (target - from).sign * maximumDistance;
        }
        break;
      }
      if ((target - from).abs() < minimumDistance) {
        final lowerRoom = from - .025;
        final upperRoom = .975 - from;
        final canMoveLower = lowerRoom >= minimumDistance;
        final canMoveUpper = upperRoom >= minimumDistance;
        final moveUpper = canMoveUpper && (!canMoveLower || random.nextBool());
        final available = math.min(
          maximumDistance,
          moveUpper ? upperRoom : lowerRoom,
        );
        final distance = minimumDistance +
            random.nextDouble() * math.max(0, available - minimumDistance);
        target = from + (moveUpper ? distance : -distance);
      }
      controls.add(target);
    }

    _controlPoints = controls;
    _knots = knots;
    _rebuildDerivatives();
  }

  static const _degree = 3;
  static const _targetAverageControlSpanSeconds = 2.0;
  // Each runner keeps its own seed, interval, and distance. The minimum
  // normalized step avoids near-stationary spans while preserving the
  // validated continuous-speed envelope. Ball speed and pass legality remain
  // independent.
  static const _maximumNormalizedSpeed = .18;
  late List<double> _controlPoints;
  late List<double> _knots;
  late List<double> _velocityPoints;
  late List<double> _velocityKnots;
  late List<double> _accelerationPoints;
  late List<double> _accelerationKnots;

  void _rebuildDerivatives() {
    _velocityKnots = _knots.sublist(1, _knots.length - 1);
    _velocityPoints = [
      for (var i = 0; i < _controlPoints.length - 1; i++)
        _degree *
            (_controlPoints[i + 1] - _controlPoints[i]) /
            (_knots[i + _degree + 1] - _knots[i + 1]),
    ];
    _accelerationKnots = _velocityKnots.sublist(
      1,
      _velocityKnots.length - 1,
    );
    _accelerationPoints = [
      for (var i = 0; i < _velocityPoints.length - 1; i++)
        (_degree - 1) *
            (_velocityPoints[i + 1] - _velocityPoints[i]) /
            (_velocityKnots[i + _degree] - _velocityKnots[i + 1]),
    ];
  }

  bool rerollNextGoalsAcross({
    required double fromTime,
    required _RunnerTrajectory other,
    required double targetLeadSeconds,
    required bool targetHigherThanOther,
    required math.Random random,
  }) {
    var index = 1;
    // Both carrier requests get an initial planning turn before the first
    // clamped control section is treated as settled.
    if (fromTime > PassRunMotion.noPassTargetRerollThresholdSeconds + .04) {
      while (index < _controlPoints.length && _knots[index] <= fromTime) {
        index++;
      }
    }
    if (index >= _controlPoints.length) return false;
    final originalControls = snapshotControls();
    double edgeLimit(int previous) => math.min(
          .4,
          _maximumNormalizedSpeed *
              (_knots[previous + _degree + 1] - _knots[previous + 1]) /
              _degree,
        );

    // Keep the smallest future section that can reach a random goal and rejoin
    // the untouched curve without exceeding either neighbouring speed bound.
    for (var count = 2; count <= 5; count++) {
      restoreControls(originalControls);
      final last = math.min(index + count - 1, _controlPoints.length - 1);
      final goalIndex = math.min(index + 1, last);
      final goalTime = (_knots[goalIndex + 1] +
              _knots[goalIndex + 2] +
              _knots[goalIndex + 3]) /
          3;
      // Higher raw goals are receiver goals; compare the carrier at release.
      // Lower goals belong to the carrier; compare the receiver at arrival.
      final comparisonTime = math.max(
          0.0,
          goalTime +
              (targetHigherThanOther ? -targetLeadSeconds : targetLeadSeconds));
      if (comparisonTime > PassRunMotion.trajectoryProfileHorizonSeconds) {
        continue;
      }
      final otherAtGoal = other.position(comparisonTime);
      final margin = .04 + random.nextDouble() * .08;
      final lowerGoal = targetHigherThanOther ? otherAtGoal + margin : .025;
      final upperGoal = targetHigherThanOther ? .975 : otherAtGoal - margin;
      if (upperGoal - lowerGoal < .04) continue;
      final targetGoal =
          lowerGoal + random.nextDouble() * (upperGoal - lowerGoal);
      final initial = originalControls[index - 1];
      var previous = initial;
      var feasible = true;
      var adjusted = false;
      for (var point = index; point <= last; point++) {
        final maximumDistance = edgeLimit(point - 1);
        var minimum = math.max(.025, previous - maximumDistance);
        var maximum = math.min(.975, previous + maximumDistance);
        if (last + 1 < originalControls.length) {
          var remainingDistance = 0.0;
          for (var edge = point; edge <= last; edge++) {
            remainingDistance += edgeLimit(edge);
          }
          final next = originalControls[last + 1];
          minimum = math.max(minimum, next - remainingDistance);
          maximum = math.min(maximum, next + remainingDistance);
        }
        if (minimum > maximum) {
          feasible = false;
          break;
        }
        // The cubic spline already eases the movement. Pursue the sampled
        // goal within the speed bounds instead of easing the controls again.
        var target = targetGoal.clamp(minimum, maximum).toDouble();
        final minimumDistance = math.min(.20, maximumDistance * .5);
        if ((target - previous).abs() < minimumDistance) {
          final direction = (targetGoal - previous).sign;
          final preferred = previous + direction * minimumDistance;
          final alternate = previous - direction * minimumDistance;
          if (preferred >= minimum && preferred <= maximum) {
            target = preferred;
          } else if (alternate >= minimum && alternate <= maximum) {
            target = alternate;
          }
        }
        adjusted |= (target - originalControls[point]).abs() > 1e-9;
        _controlPoints[point] = target;
        previous = target;
      }
      if (!feasible ||
          !adjusted ||
          (_controlPoints[last] - targetGoal).abs() > .04) {
        continue;
      }
      _rebuildDerivatives();
      if (_velocityPoints
          .every((v) => v.abs() <= _maximumNormalizedSpeed + 1e-9)) {
        return true;
      }
    }
    restoreControls(originalControls);
    return false;
  }

  double _evaluate(
    List<double> points,
    List<double> knots,
    int degree,
    double t,
  ) {
    if (t <= knots[degree]) return points.first;
    if (t >= knots[points.length]) return points.last;

    var span = degree;
    while (span < points.length - 1 && t >= knots[span + 1]) {
      span++;
    }
    final work = <double>[
      for (var j = 0; j <= degree; j++) points[span - degree + j],
    ];
    for (var order = 1; order <= degree; order++) {
      for (var j = degree; j >= order; j--) {
        final knotIndex = span - degree + j;
        final denominator =
            knots[knotIndex + degree + 1 - order] - knots[knotIndex];
        final alpha =
            denominator == 0 ? 0.0 : (t - knots[knotIndex]) / denominator;
        work[j] = (1 - alpha) * work[j - 1] + alpha * work[j];
      }
    }
    return work[degree];
  }

  double position(double t) => _evaluate(_controlPoints, _knots, _degree, t);

  List<double> snapshotControls() => List<double>.of(_controlPoints);

  void restoreControls(List<double> controls) {
    _controlPoints = List<double>.of(controls);
    _rebuildDerivatives();
  }

  double velocity(double t) {
    if (t < 0) {
      final startVelocity =
          _evaluate(_velocityPoints, _velocityKnots, _degree - 1, 0);
      final startAcceleration = _evaluate(
        _accelerationPoints,
        _accelerationKnots,
        _degree - 2,
        0,
      );
      return startVelocity + startAcceleration * t;
    }
    return _evaluate(_velocityPoints, _velocityKnots, _degree - 1, t);
  }
}
