import 'package:flutter/material.dart';

import 'models/training_game_models.dart';

/// 支給参考図から人物・UIガイドを除いて取り出した背景と配置です。
/// 座標は参考図の1パネル内。画面全体へ45%を掛ける指定ではありません。
class TrainingCareScene {
  const TrainingCareScene._(this.asset, this.characterRect);

  final String asset;
  final Rect characterRect;

  static const sourceSize = Size(161.575, 233.089);

  /// 休養は承認済みの「睡眠中＝夜、完了＝昼」を表示します。
  /// ほかの動作はポーズによって背景を切り替えません。
  static TrainingCareScene? forAction(
    TrainingActionType action, {
    bool completed = false,
    bool isChild = false,
  }) {
    if (isChild) {
      if (action == TrainingActionType.work ||
          action == TrainingActionType.tackle ||
          action == TrainingActionType.passAndRun) {
        return null;
      }
      final base = forAction(action, completed: completed)!;
      final registration = forAction(action)!;
      // 支給背景の食事canvas幅と共通の足元を使い、512角を全コマ同寸に配置。
      // bboxを使った個別trimや完了時の再中央揃えはしません。
      const extent = 66.15;
      return TrainingCareScene._(
        base.asset,
        Rect.fromLTWH(
          registration.characterRect.center.dx - extent / 2,
          188.55 - extent,
          extent,
          extent,
        ),
      );
    }
    if (action == TrainingActionType.rest) {
      return completed
          ? const TrainingCareScene._(
              'assets/images/training_game/scenes/rest_room_day.png',
              Rect.fromLTWH(34.1395, 123.0274, 95.85, 67.5),
            )
          : const TrainingCareScene._(
              'assets/images/training_game/scenes/rest_room_night.png',
              Rect.fromLTWH(34.215, 120.8561, 95.85, 67.5),
            );
    }
    return const <TrainingActionType, TrainingCareScene>{
      TrainingActionType.squat: TrainingCareScene._(
        'assets/images/training_game/scenes/gym_bench.png',
        Rect.fromLTWH(91.132, 117.899, 46.35, 70.65),
      ),
      TrainingActionType.clean: TrainingCareScene._(
        'assets/images/training_game/scenes/clean_room.png',
        Rect.fromLTWH(93.754, 117.449, 40.5, 71.1),
      ),
      TrainingActionType.work: TrainingCareScene._(
        'assets/images/training_game/scenes/work_office.png',
        Rect.fromLTWH(45.91, 109.153, 69.75, 79.2),
      ),
      TrainingActionType.meal: TrainingCareScene._(
        'assets/images/training_game/scenes/meal_office.png',
        Rect.fromLTWH(47.477, 118.157, 66.15, 70.2),
      ),
    }[action];
  }
}

/// 背景と家具を含むキャラ素材を同じ座標系で描画します。
/// 全パネルをcontainで収め、家具や完了ポーズを画面の縦横比で切りません。
class TrainingCareSceneView extends StatelessWidget {
  const TrainingCareSceneView({
    required this.scene,
    required this.character,
    super.key,
  });

  final TrainingCareScene scene;
  final Widget character;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.contain,
        child: SizedBox.fromSize(
          size: TrainingCareScene.sourceSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(scene.asset),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: scene.characterRect,
                  child: character,
                ),
              ],
            ),
          ),
        ),
      );
}
