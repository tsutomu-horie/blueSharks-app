import 'package:flutter/material.dart';

/// 支給原本のボールを含まない横向きポーズです。
enum MiniGameCharacterPose {
  rightRest,
  rightReach,
  leftReach,
  leftRest;

  String get assetPath => switch (this) {
        rightRest =>
          'assets/images/training_game/minigames/side_right_rest.png',
        rightReach =>
          'assets/images/training_game/minigames/side_right_reach.png',
        leftReach =>
          'assets/images/training_game/minigames/side_left_reach.png',
        leftRest => 'assets/images/training_game/minigames/side_left_rest.png',
      };

  /// 原本の足元中心です。左右で鼻先の余白が異なります。
  double get footAnchorX => switch (this) {
        rightRest || rightReach => 33 / 76,
        leftReach || leftRest => 43 / 76,
      };

  static MiniGameCharacterPose forPass({
    required bool outbound,
    required bool passing,
  }) {
    return outbound
        ? (passing ? rightReach : rightRest)
        : (passing ? leftReach : leftRest);
  }
}

/// 元のemojiと同じレイアウト領域の中で支給キャラクターを描画します。
/// 判定座標、入力領域、移動アニメーションは呼び出し元が保持します。
class MiniGameCharacterAsset extends StatefulWidget {
  const MiniGameCharacterAsset({
    required this.pose,
    required this.fontSize,
    super.key,
  });

  final MiniGameCharacterPose pose;
  final double fontSize;

  @override
  State<MiniGameCharacterAsset> createState() => _MiniGameCharacterAssetState();
}

class _MiniGameCharacterAssetState extends State<MiniGameCharacterAsset> {
  Size? _legacySize;
  double? _maximumWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _legacySize = null;
  }

  @override
  void didUpdateWidget(covariant MiniGameCharacterAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fontSize != widget.fontSize) _legacySize = null;
  }

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = defaults.style.merge(
      TextStyle(fontSize: widget.fontSize),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // AnimatedAlign depends on its child's dimensions. Keep the former
        // Text's metrics instead of replacing it with a narrower image box.
        if (_legacySize == null || _maximumWidth != constraints.maxWidth) {
          final metrics = TextPainter(
            text: TextSpan(text: '🦈', style: style),
            textDirection: direction,
            textScaler: scaler,
            textHeightBehavior: defaults.textHeightBehavior,
          )..layout(maxWidth: constraints.maxWidth);
          _legacySize = metrics.size;
          _maximumWidth = constraints.maxWidth;
          metrics.dispose();
        }
        final size = _legacySize!;
        final imageWidth = widget.fontSize * 76 / 144;
        return SizedBox(
          width: size.width,
          height: size.height,
          child: IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: Offset((.5 - widget.pose.footAnchorX) * imageWidth, 0),
                child: Image.asset(
                  widget.pose.assetPath,
                  width: imageWidth,
                  height: widget.fontSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
