import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pass_and_run_motion.dart';

enum PassRunCharacter { normal, companion }

/// 承認済みの保持／非保持だけを使う、2コマのパス＆ラン表示です。
/// 判定中心を胴体に置き、同じ脚位相の持ち替えで全身を動かしません。
class PassAndRunCharacterVisual extends StatelessWidget {
  const PassAndRunCharacterVisual({
    required this.character,
    required this.holding,
    required this.frame,
    required this.facing,
    required this.size,
    this.ballKey,
    this.visualScale = 1.0,
    super.key,
  });

  static const canvasSize = 112.0;

  static Iterable<String> get assets sync* {
    for (final name in ['normal', 'mate']) {
      for (final facing in ['front', 'back']) {
        for (final state in ['hold', 'free']) {
          for (final phase in ['a', 'b']) {
            yield 'assets/images/training_game/minigames/pass_run_${name}_${facing}_${state}_$phase.png';
          }
        }
      }
    }
    yield 'assets/images/training_game/minigames/pass_run_ball.png';
  }

  final PassRunCharacter character;
  final bool holding;
  final int frame;
  final PassRunFacing facing;
  final double size;
  final Key? ballKey;
  final double visualScale;
  static const candidateVisualScale = 1.15;

  String get assetPath {
    final name = character == PassRunCharacter.normal ? 'normal' : 'mate';
    final state = holding ? 'hold' : 'free';
    final phase = frame.isEven ? 'a' : 'b';
    return 'assets/images/training_game/minigames/pass_run_${name}_${facing.name}_${state}_$phase.png';
  }

  /// 承認済み3x保持画像の赤い球縁を測定した楕円です。
  /// 原画を変えず、球の中心・長短径・傾きを描画側で合わせます。
  static PassRunBallGeometry heldBallGeometry({
    required PassRunCharacter character,
    required int frame,
    required PassRunFacing facing,
    required double size,
  }) {
    // Front ball ellipse measured from the approved master. Rear is the
    // anatomical projection behind the body; only its exposed crescent is visible.
    final back = facing == PassRunFacing.back;
    final raw = PassRunBallGeometry(
      offset: Offset(back ? -13.51197411 : 13.51197411, 8.919093226667),
      longAxis: 29.62079706,
      shortAxis: 14.836856553333,
      angle: back ? -1.219072525474 : 1.219072525474,
    );
    return raw.scaled(size / canvasSize);
  }

  static Offset heldBallOffset({
    required PassRunCharacter character,
    required int frame,
    required PassRunFacing facing,
    required double size,
  }) =>
      heldBallGeometry(
        character: character,
        frame: frame,
        facing: facing,
        size: size,
      ).offset;

  @override
  Widget build(BuildContext context) {
    final geometry = heldBallGeometry(
      character: character,
      frame: frame,
      facing: facing,
      size: size,
    );
    final freeAsset = assetPath.replaceFirst('_hold_', '_free_');
    Widget heldBall() => Positioned(
          left: size / 2 + geometry.offset.dx - geometry.extent / 2,
          top: size / 2 + geometry.offset.dy - geometry.extent / 2,
          child: PassAndRunBallVisual(geometry: geometry),
        );
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (holding && facing == PassRunFacing.back) heldBall(),
            Transform.scale(
              scale: visualScale,
              child: Image.asset(
                freeAsset,
                gaplessPlayback: true,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
            if (holding && facing == PassRunFacing.front) heldBall(),
            // 保持球も飛翔球と同じ描画を使い、座標と径を拡大から分離する。
            if (holding)
              Positioned(
                left: size / 2 + geometry.offset.dx - geometry.extent / 2,
                top: size / 2 + geometry.offset.dy - geometry.extent / 2,
                child: Semantics(
                  key: ballKey,
                  label: 'ボールを保持',
                  child: SizedBox(
                    width: geometry.extent,
                    height: geometry.extent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 不透明な球縁を基準にした寸法。長短径は直径、angleは楕円の主軸です。
@immutable
class PassRunBallGeometry {
  const PassRunBallGeometry({
    required this.offset,
    required this.longAxis,
    required this.shortAxis,
    required this.angle,
  });
  final Offset offset;
  final double longAxis;
  final double shortAxis;
  final double angle;
  double get extent => longAxis + 4;
  double get collisionRadius => longAxis / 2;

  PassRunBallGeometry scaled(double scale, {bool mirrored = false}) =>
      PassRunBallGeometry(
        offset: Offset(mirrored ? -offset.dx : offset.dx, offset.dy) * scale,
        longAxis: longAxis * scale,
        shortAxis: shortAxis * scale,
        angle: mirrored ? math.pi - angle : angle,
      );

  static PassRunBallGeometry lerp(
    PassRunBallGeometry a,
    PassRunBallGeometry b,
    double t,
  ) {
    final p = t.clamp(0, 1).toDouble();
    // PNGの柄には向きがあるため360度周期で補間し、終点の絵柄も一致させます。
    final da = (b.angle - a.angle + math.pi) % (math.pi * 2) - math.pi;
    return PassRunBallGeometry(
      offset: Offset.lerp(a.offset, b.offset, p)!,
      longAxis: a.longAxis + (b.longAxis - a.longAxis) * p,
      shortAxis: a.shortAxis + (b.shortAxis - a.shortAxis) * p,
      angle: a.angle + da * p,
    );
  }
}

/// 飛翔球のPNGそのものは不変。保持画と同じ楕円になるよう描画変換します。
class PassAndRunBallVisual extends StatelessWidget {
  const PassAndRunBallVisual({required this.geometry, super.key});
  final PassRunBallGeometry geometry;
  static const source = PassRunBallGeometry(
    offset: Offset(15.63450647194253, 10.854759100834167),
    longAxis: 26.18282484368637,
    shortAxis: 12.880872837084896,
    angle: -2.635116879341312,
  );

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..translateByDouble(geometry.extent / 2, geometry.extent / 2, 0, 1)
      ..rotateZ(geometry.angle)
      ..scaleByDouble(
        geometry.longAxis / source.longAxis,
        geometry.shortAxis / source.shortAxis,
        1,
        1,
      )
      ..rotateZ(-source.angle)
      ..translateByDouble(-source.offset.dx, -source.offset.dy, 0, 1);
    return SizedBox.square(
      dimension: geometry.extent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 32,
            height: 22,
            child: Transform(
              alignment: Alignment.topLeft,
              transform: matrix,
              child: Image.asset(
                'assets/images/training_game/minigames/pass_run_ball.png',
                width: 32,
                height: 22,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
