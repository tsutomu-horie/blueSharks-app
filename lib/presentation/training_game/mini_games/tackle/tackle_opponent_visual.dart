import 'package:flutter/material.dart';

/// 元のランナーemojiの領域を保って、支給Bキャラクターを表示します。
class TackleOpponentVisual extends StatelessWidget {
  const TackleOpponentVisual({super.key});

  static const assetPath =
      'assets/images/training_game/minigames/tackle_opponent_b.png';
  // Match Normal rest alpha128 body height (206/216 at canvas height 72).
  static const imageHeight = 72 * (206 / 216) * (891 / 867);
  // Grow toward the player, keeping the former image right edge fixed.
  // This avoids new exit remnants on narrower fields without moving targets.
  static const imageOffsetX = -(imageWidth - 58 * 562 / 891) / 2;
  static const imageOffsetY = -1 / 3;
  static const imageWidth = imageHeight * 562 / 891;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Preserve inherited text metrics and AnimatedAlign coordinates.
            const Opacity(
              opacity: 0,
              child: Text('🏃', style: TextStyle(fontSize: 58)),
            ),
            Positioned.fill(
              child: OverflowBox(
                minWidth: imageWidth,
                maxWidth: imageWidth,
                minHeight: imageHeight,
                maxHeight: imageHeight,
                child: Transform.translate(
                  offset: const Offset(imageOffsetX, imageOffsetY),
                  child: Image.asset(
                    assetPath,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.low,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
