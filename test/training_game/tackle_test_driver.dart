import 'recording_training_game_sound.dart';
import 'dart:math';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/tackle/tackle_game.screen.dart';

TackleGameScreen tackleTestScreen({
  bool hasFeint = false,
  bool downward = true,
  int approachMs = 1350,
}) =>
    TackleGameScreen(
        feedbackSoundFactory: silentTrainingGameSound,
        random: FixedTackleRandom(
            hasFeint: hasFeint, downward: downward, approachMs: approachMs));

/// Supplies the three independent draws without altering production selection.
class FixedTackleRandom implements Random {
  FixedTackleRandom(
      {required this.hasFeint,
      required this.downward,
      required this.approachMs});
  final bool hasFeint;
  final bool downward;
  final int approachMs;
  int booleanCalls = 0;
  int integerCalls = 0;
  @override
  bool nextBool() => (booleanCalls++).isEven ? hasFeint : downward;
  @override
  int nextInt(int max) {
    if (max != 501) throw StateError('Unexpected random bound $max');
    integerCalls++;
    return approachMs - 1100;
  }

  @override
  double nextDouble() => throw StateError('Unexpected floating random draw');
}
