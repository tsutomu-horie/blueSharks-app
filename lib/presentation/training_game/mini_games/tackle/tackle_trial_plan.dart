import 'dart:math';

import 'tackle_game_logic.dart';

/// Independent draws: feint presence, actual direction, approach duration.
class TackleTrialPlan {
  const TackleTrialPlan({
    required this.hasFeint,
    required this.actualDirection,
    required this.approachDuration,
  });
  factory TackleTrialPlan.draw(Random random) => TackleTrialPlan(
        hasFeint: random.nextBool(),
        actualDirection:
            random.nextBool() ? TackleDirection.down : TackleDirection.up,
        approachDuration: Duration(milliseconds: 1100 + random.nextInt(501)),
      );
  final bool hasFeint;
  final TackleDirection actualDirection;
  final Duration approachDuration;
  Duration get secondApproachDuration =>
      approachDuration - const Duration(milliseconds: 700);
}
