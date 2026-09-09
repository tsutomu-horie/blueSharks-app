import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';

void main() {
  test('お世話5種に行動中フレームと完了フレームが割り当てられている', () {
    const careActions = [
      TrainingActionType.meal,
      TrainingActionType.clean,
      TrainingActionType.rest,
      TrainingActionType.squat,
      TrainingActionType.work,
    ];

    for (final action in careActions) {
      final frames = SametarohAssets.careFramesFor(action);
      final completion = SametarohAssets.completionFrameFor(action);
      expect(frames, isNotEmpty);
      expect(completion.asset, isNotEmpty);
      expect(frames.map((frame) => frame.canvasSize).toSet(), hasLength(1));
      expect(completion.canvasSize, frames.first.canvasSize);
    }

    final mealFrames = SametarohAssets.careFramesFor(TrainingActionType.meal);
    expect(
      mealFrames.map((frame) => frame.asset),
      [
        'assets/images/sametaroh/eating_sametaroh_1.png',
        'assets/images/sametaroh/eating_sametaroh_2.png',
      ],
    );
    expect(
      SametarohAssets.initialFrames[TrainingActionType.meal]?.asset,
      'assets/images/sametaroh/eating_sametaroh_start.png',
    );
  });

  test('通常画面と旅立ち画面に2フレームずつ割り当てられている', () {
    expect(SametarohAssets.normalFrames, hasLength(2));
    expect(SametarohAssets.journeyFrames, hasLength(2));
    expect(
      SametarohAssets.normalFrames.map((frame) => frame.canvasSize).toSet(),
      hasLength(1),
    );
    expect(
      SametarohAssets.journeyFrames.map((frame) => frame.canvasSize).toSet(),
      hasLength(1),
    );
  });
}
