import 'dart:math' as math;

/// Changes only progress along the existing random path. No target position,
/// lane alignment, or replacement path is created.
abstract interface class PassRunAssistedMovement {
  double get start;
  bool get released;
  double positionAt(double seconds);
  double velocityAt(double seconds);
  double accelerationAt(double seconds);
  double distanceSinceStart(double seconds);
  void release(double seconds);
}

class PassRunPaceAssist implements PassRunAssistedMovement {
  PassRunPaceAssist(
      {required this.start,
      required this.normalPosition,
      required this.normalVelocity,
      required double targetRate,
      required this.attackUp,
      PassRunPaceAssist? previous})
      : _phase = previous?.phaseAt(start) ?? start,
        _rate = previous?.rateAt(start) ?? 1,
        _slope = previous?.rateSlopeAt(start) ?? 0 {
    _segments.add(_PaceSegment(start, _phase, _rate, _slope, targetRate));
  }
  static const transitionSeconds = .7;
  @override
  final double start;
  final double _phase, _rate, _slope;
  final bool attackUp;
  final double Function(double) normalPosition, normalVelocity;
  final _segments = <_PaceSegment>[];
  @override
  bool released = false;
  _PaceSegment _at(double t) =>
      _segments.lastWhere((s) => t >= s.start, orElse: () => _segments.first);
  double phaseAt(double t) => t < start ? t : _at(t).phaseAt(t);
  double rateAt(double t) => t < start ? 1 : _at(t).rateAt(t);
  double rateSlopeAt(double t) => t < start ? 0 : _at(t).slopeAt(t);
  @override
  double positionAt(double t) => normalPosition(phaseAt(t));
  @override
  double velocityAt(double t) => normalVelocity(phaseAt(t)) * rateAt(t);
  @override
  double accelerationAt(double t) {
    final p = phaseAt(t), r = rateAt(t);
    final baseA =
        (normalVelocity(p + .0001) - normalVelocity(p - .0001)) / .0002;
    return baseA * r * r + normalVelocity(p) * rateSlopeAt(t);
  }

  @override
  double distanceSinceStart(double t) => t <= start
      ? 0
      : (attackUp ? -1 : 1) * (positionAt(t) - positionAt(start));
  @override
  void release(double t) {
    if (released) return;
    _segments.add(_PaceSegment(t, phaseAt(t), rateAt(t), rateSlopeAt(t), 1));
    released = true;
  }
}

class _PaceSegment {
  _PaceSegment(this.start, this.phase, this.initial, this.slope, this.target);
  final double start, phase, initial, slope, target;
  static const d = PassRunPaceAssist.transitionSeconds;
  double get c1 => slope * d;
  double get c2 => 3 * (target - initial) - 2 * c1;
  double get c3 => 2 * (initial - target) + c1;
  double rateAt(double t) {
    final u = ((t - start) / d).clamp(0.0, 1.0);
    return initial + c1 * u + c2 * u * u + c3 * u * u * u;
  }

  double slopeAt(double t) {
    if (t - start >= d) return 0;
    final u = ((t - start) / d).clamp(0.0, 1.0);
    return (c1 + 2 * c2 * u + 3 * c3 * u * u) / d;
  }

  double phaseAt(double t) {
    final elapsed = math.max(0.0, t - start), u = (elapsed / d).clamp(0.0, 1.0);
    final integrated = d *
        (initial * u +
            c1 * u * u / 2 +
            c2 * u * u * u / 3 +
            c3 * u * u * u * u / 4);
    return phase + integrated + math.max(0.0, elapsed - d) * target;
  }
}
