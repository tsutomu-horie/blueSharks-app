import 'package:flutter/material.dart';

import '../mini_game_character_asset.dart';

/// タックル画面だけで、元のレイアウト領域を保ったまま攻撃ポーズを表示します。
class TacklePlayerVisual extends StatelessWidget {
  const TacklePlayerVisual({
    required this.attacking,
    this.downward = false,
    this.visualScale = 1.0,
    super.key,
  });

  final bool attacking;
  final bool downward;
  final double visualScale;
  static const candidateVisualScale = 1.15;

  // Frozen transparent extraction, 615 x 1251 native pixels.
  // Foot anchor is the mean center of the two feet in the bottom four rows.
  static const attackAssetPath =
      'assets/images/training_game/minigames/tackle_attack_normal.png';
  static const double attackAspectRatio = 615 / 1251;
  static const double attackFootAnchorX = 0.6231101832797189;

  @override
  Widget build(BuildContext context) {
    const height = 72.0;
    const width = height * attackAspectRatio;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The non-positioned rest visual retains the exact legacy emoji box
        // used by AnimatedAlign, including inherited text metrics.
        Opacity(
          opacity: attacking ? 0 : 1,
          child: Transform.scale(
            scale: visualScale,
            child: const MiniGameCharacterAsset(
              pose: MiniGameCharacterPose.rightRest,
              fontSize: height,
            ),
          ),
        ),
        if (attacking)
          Positioned.fill(
            child: IgnorePointer(
              child: OverflowBox(
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: Transform.translate(
                  offset: const Offset((.5 - attackFootAnchorX) * width, 0),
                  child: Transform.scale(
                    scale: visualScale,
                    // Preserve the calibrated arm contact pixel after Y flip.
                    alignment: Alignment(
                      2 * 607 / 615 - 1,
                      (downward ? -1 : 1) * (2 * 455 / 1251 - 1),
                    ),
                    child: Transform.flip(
                      flipY: downward,
                      child: Image.asset(
                        attackAssetPath,
                        key: const Key('tackle-player-attack'),
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.low,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
