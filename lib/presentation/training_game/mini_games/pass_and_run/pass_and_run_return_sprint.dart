import 'dart:math' as math;
import 'pass_and_run_pace_assist.dart';

/// A receiver-only burst. The round clock, ball speed and passer are unchanged.
/// Samples describe positions AND velocities, so release/pause/rendering never
/// change the path merely because a different number of frames was drawn.
/// Before [start] this evaluator returns the ordinary path; the screen keeps
/// the previous event until its catch sweep has completed.
class PassRunReturnSprint implements PassRunAssistedMovement {
  PassRunReturnSprint({
    required this.start,
    required double position,
    required double velocity,
    required this.minimum,
    required this.maximum,
    required this.attackUp,
    required this.normalPosition,
    required this.normalVelocity,
    required double end,
    required this.normalSpeed,
    this.boostTarget,
    this.boostSpeed = burstSpeed,
    this.boostAcceleration = burstAcceleration,
    this.boostJerk = 18,
    double acceleration = 0,
  }) : _end = end {
    _burst = _build(start, position, velocity, acceleration, sprint: true);
  }

  static const step = .008;
  static const burstSpeed = 1.0; // usable ranges / second, only while holding
  static const burstAcceleration = 3.5;
  @override
  final double start;
  final double minimum, maximum, normalSpeed, _end;
  final bool attackUp;
  final double Function(double)? boostTarget;
  final double boostSpeed, boostAcceleration, boostJerk;
  @override
  bool get released => _releasedAt != null;
  final double Function(double) normalPosition, normalVelocity;
  late final List<({double y, double v, double a, double distance})> _burst;
  List<({double y, double v, double a, double distance})>? _coast;
  double? _releasedAt;

  List<({double y, double v, double a, double distance})> _build(
      double at, double y, double v, double a,
      {required bool sprint}) {
    final result = [(y: y, v: v, a: a, distance: 0.0)];
    var distance = 0.0;
    for (var i = 1; at + (i - 1) * step < _end; i++) {
      final t = at + (i - 1) * step;
      final edgeDistance = v < 0 ? y - minimum : maximum - y;
      final desiredAcceleration = sprint ? boostAcceleration : 1.8;
      final emergency = v * v / (2 * desiredAcceleration) + v.abs() * step >
          edgeDistance * .75;
      final accelerationLimit = emergency ? 12.0 : desiredAcceleration;
      final margin = (maximum - minimum) * .02;
      final goal = sprint
          ? (boostTarget?.call(t) ??
              (attackUp ? minimum + margin : maximum - margin))
          : normalPosition(t);
      final error = goal.clamp(minimum + margin / 4, maximum - margin / 4) - y;
      final limit = sprint ? boostSpeed : normalSpeed;
      // Anticipate the next acceleration response instead of braking only
      // after entering the edge's stopping-distance envelope.
      final projected = y + v * .18 + a * .18 * .18 / 2;
      final lower = -math.sqrt(2 *
              accelerationLimit *
              math.max(0, math.min(y, projected) - minimum)) *
          .6;
      final upper = math.sqrt(2 *
              accelerationLimit *
              math.max(0, maximum - math.max(y, projected))) *
          .6;
      final requested =
          ((error - v * .18 - a * .18 * .18 / 2) * (sprint ? 6.5 : 4) +
                  (sprint ? 0 : normalVelocity(t)))
              .clamp(-limit, limit)
              .clamp(lower, upper);
      final requestedA = emergency && v.abs() > .001
          ? -v.sign * accelerationLimit
          : ((requested - v - (sprint ? .12 : 0) * a) / (sprint ? .12 : .10))
              .clamp(-accelerationLimit, accelerationLimit);
      // The ordinary transition is jerk-limited; an already unsafe incoming
      // boundary state keeps the previous emergency brake instead of clipping y.
      final nextA = emergency
          ? requestedA
          : a +
              (requestedA - a).clamp(-(sprint ? boostJerk : 24) * step,
                  (sprint ? boostJerk : 24) * step);
      final nextV = v + (a + nextA) * .5 * step;
      final nextY = y + v * step + (a / 3 + nextA / 6) * step * step;
      distance += (nextY - y).abs();
      y = nextY;
      v = nextV;
      a = nextA;
      result.add((y: y, v: v, a: a, distance: distance));
    }
    return result;
  }

  ({double y, double v, double a, double distance}) _sample(double seconds) {
    final released = _releasedAt;
    final coasting = released != null && seconds >= released;
    final points = coasting ? _coast! : _burst;
    final beginning = coasting ? released : start;
    final index =
        ((seconds - beginning) / step).clamp(0.0, points.length - 1.0);
    final i = index.floor(), j = math.min(i + 1, points.length - 1);
    final a = points[i], b = points[j];
    final u = index - i;
    // Quintic interpolation preserves position, velocity AND acceleration
    // across samples and catch/release boundaries.
    final c0 = a.y, c1 = a.v * step, c2 = a.a * step * step / 2;
    final d = b.y - c0 - c1 - c2;
    final dv = b.v * step - c1 - 2 * c2;
    final da = b.a * step * step - 2 * c2;
    final c3 = 10 * d - 4 * dv + da / 2;
    final c4 = -15 * d + 7 * dv - da;
    final c5 = 6 * d - 3 * dv + da / 2;
    final y = c0 + u * (c1 + u * (c2 + u * (c3 + u * (c4 + u * c5))));
    final v =
        (c1 + u * (2 * c2 + u * (3 * c3 + u * (4 * c4 + u * 5 * c5)))) / step;
    final acceleration =
        (2 * c2 + u * (6 * c3 + u * (12 * c4 + u * 20 * c5))) / (step * step);
    return (
      y: y,
      v: v,
      a: acceleration,
      distance: a.distance + (b.distance - a.distance) * u
    );
  }

  @override
  double positionAt(double seconds) =>
      seconds < start ? normalPosition(seconds) : _sample(seconds).y;
  @override
  double velocityAt(double seconds) =>
      seconds < start ? normalVelocity(seconds) : _sample(seconds).v;
  @override
  double accelerationAt(double seconds) =>
      seconds < start ? 0 : _sample(seconds).a;
  @override
  double distanceSinceStart(double seconds) {
    if (seconds < start) return 0;
    final released = _releasedAt;
    final prior = released == null || seconds < released
        ? 0.0
        : _sampleBurstDistance(released);
    return prior + _sample(seconds).distance;
  }

  double _sampleBurstDistance(double seconds) {
    final index = ((seconds - start) / step).clamp(0.0, _burst.length - 1.0);
    final i = index.floor(), j = math.min(i + 1, _burst.length - 1);
    return _burst[i].distance +
        (_burst[j].distance - _burst[i].distance) * (index - i);
  }

  @override
  void release(double seconds) {
    if (_releasedAt != null) return;
    final state = _sample(seconds);
    _coast = _build(seconds, state.y, state.v, state.a, sprint: false);
    _releasedAt = seconds;
  }
}
