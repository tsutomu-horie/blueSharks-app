import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game_logic.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_trial_plan.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_running_trajectory.dart';
import 'tackle_test_driver.dart';

void main() {
  for (final feint in [false, true]) {
    for (final down in [false, true]) {
      for (final delay in [1100, 1350, 1600]) {
        test('independent pattern=$feint/down=$down/wait=$delay', () {
          final random = FixedTackleRandom(
              hasFeint: feint, downward: down, approachMs: delay);
          // Repeated identical draws remain identical: no forced alternation.
          for (var i = 0; i < 3; i++) {
            final plan = TackleTrialPlan.draw(random);
            expect(plan.hasFeint, feint);
            expect(plan.actualDirection,
                down ? TackleDirection.down : TackleDirection.up);
            expect(plan.approachDuration.inMilliseconds, delay);
            expect(plan.secondApproachDuration.inMilliseconds, delay - 700);
          }
          expect(random.booleanCalls, 6);
          expect(random.integerCalls, 3);
        });
      }
    }
  }
  test('latest real750ms keeps approved model500/contact660 budget', () {
    expect(TackleRunningTrajectory.visualMilliseconds(0), 110);
    expect(TackleRunningTrajectory.visualMilliseconds(750), 500);
    expect(TackleRunningTrajectory.contactTime(500), 660);
    expect(160 / TackleRunningTrajectory.presentationRate,
        closeTo(307.6923076923, 1e-9));
  });
}
