import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 清潔値に合わせて、育成ホームの足元へ小物を散らします。
///
/// 小物画像はユーザー確認済みの生成補完候補です。
/// 元の行動スプライトから切り抜いた画像ではなく、
/// 元絵とは形や細部に差があります。
class TrainingHomeFloorLitter extends StatefulWidget {
  const TrainingHomeFloorLitter({
    required this.cleanliness,
    required this.characterFootClearance,
    required this.controlsClearance,
    this.randomSeed,
    super.key,
  });

  /// 清潔メーター値。80以上では小物を表示しません。
  final double cleanliness;

  /// レイアウトをテストで再現するための任意seedです。
  final int? randomSeed;

  /// 親Stack下端からキャラクター足元までの余白。
  final double characterFootClearance;

  /// ボタン列に重ならないため、親Stack下端から空ける余白。
  final double controlsClearance;

  /// 清潔値の段階ごとに、表示する小物数を返します。
  static int itemCountForCleanliness(double cleanliness) {
    if (cleanliness.isNaN) return 0;
    if (cleanliness >= 80) return 0;
    if (cleanliness >= 65) return 1;
    if (cleanliness >= 50) return 2;
    if (cleanliness >= 35) return 3;
    if (cleanliness >= 20) return 4;
    return 5;
  }

  @override
  State<TrainingHomeFloorLitter> createState() =>
      _TrainingHomeFloorLitterState();
}

class _TrainingHomeFloorLitterState extends State<TrainingHomeFloorLitter> {
  static const _outdoorSceneWidth = 485.0;
  static const _outdoorSceneHeight = 700.0;
  static const _outdoorGrassStartY = 422.0;

  static const _props = <_FloorPropSpec>[
    _FloorPropSpec(
      assetPath:
          'assets/images/training_game/home_floor_litter/dumbbell_candidate.png',
      widthFactor: 1,
      heightFactor: 1,
      angle: -.035,
    ),
    _FloorPropSpec(
      assetPath:
          'assets/images/training_game/home_floor_litter/baby_bottle_candidate.png',
      widthFactor: .82,
      heightFactor: .82,
      angle: math.pi / 2,
    ),
    _FloorPropSpec(
      assetPath:
          'assets/images/training_game/home_floor_litter/work_pc_candidate.png',
      widthFactor: 1.35,
      heightFactor: .68,
      angle: -.035,
    ),
    _FloorPropSpec(
      assetPath:
          'assets/images/training_game/home_floor_litter/broom_candidate.png',
      widthFactor: .74,
      heightFactor: .74,
      angle: 1.02,
    ),
    _FloorPropSpec(
      assetPath:
          'assets/images/training_game/home_floor_litter/rugby_ball_floor_candidate.png',
      widthFactor: 1.28,
      heightFactor: .86,
      angle: .08,
    ),
  ];

  static const _columnCount = 5;
  static const _scatteredSlots = <_FloorSlot>[
    _FloorSlot(x: .12, depth: .04),
    _FloorSlot(x: .88, depth: .18),
    _FloorSlot(x: .12, depth: .86),
    _FloorSlot(x: .88, depth: .96),
    _FloorSlot(x: .50, depth: .50, belowCharacter: true),
  ];

  late int _seed;
  Size? _cachedSize;
  List<_PlacedFloorProp>? _cachedLayout;

  @override
  void initState() {
    super.initState();
    _seed = widget.randomSeed ?? math.Random().nextInt(0x7fffffff);
  }

  @override
  void didUpdateWidget(covariant TrainingHomeFloorLitter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.randomSeed != widget.randomSeed) {
      _seed = widget.randomSeed ?? math.Random().nextInt(0x7fffffff);
      _cachedSize = null;
      _cachedLayout = null;
    } else if (oldWidget.characterFootClearance !=
            widget.characterFootClearance ||
        oldWidget.controlsClearance != widget.controlsClearance) {
      _cachedSize = null;
      _cachedLayout = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount =
        TrainingHomeFloorLitter.itemCountForCleanliness(widget.cleanliness);
    if (visibleCount == 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
              return const SizedBox.shrink();
            }
            final size = Size(
              math.max(0.0, constraints.maxWidth).toDouble(),
              math.max(0.0, constraints.maxHeight).toDouble(),
            );
            final layout = _layoutFor(size);
            if (layout.length < visibleCount) return const SizedBox.shrink();
            final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < visibleCount; index++)
                  _buildProp(
                    layout[index],
                    index,
                    devicePixelRatio,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_PlacedFloorProp> _layoutFor(Size size) {
    if (_cachedSize == size && _cachedLayout != null) return _cachedLayout!;

    final floorTop =
        math.max(0.0, size.height - widget.characterFootClearance).toDouble();
    final floorBottom = math
        .min(size.height, size.height - widget.controlsClearance)
        .toDouble();
    final floorHeight = math.max(0.0, floorBottom - floorTop).toDouble();
    if (size.width <= 0 || floorHeight <= 0) {
      _cachedSize = size;
      _cachedLayout = const <_PlacedFloorProp>[];
      return _cachedLayout!;
    }

    final random = math.Random(_seed);
    final props = [..._props]..shuffle(random);
    final slots = [..._scatteredSlots]..shuffle(random);
    final unit = math
        .min(
          math.min(size.width * .10, 44.0),
          floorHeight * .60,
        )
        .toDouble();

    // The background is width-fitted and bottom-aligned behind the HUD/room.
    final grassDistanceFromBottom =
        (_outdoorSceneHeight - _outdoorGrassStartY) *
            size.width /
            _outdoorSceneWidth;
    final sideTop =
        math.max(0.0, size.height - grassDistanceFromBottom).toDouble();
    final sideHeight = math.max(0.0, floorBottom - sideTop).toDouble();
    final tallestSideProp = props
        .map((prop) => _rotatedSize(
              unit * prop.widthFactor,
              unit * prop.heightFactor,
              prop.angle,
            ).height)
        .reduce((a, b) => math.max(a, b).toDouble());
    final useScatteredGround = sideHeight >= tallestSideProp * 2.5;
    final columnWidth = size.width / _columnCount;
    final placements = <_PlacedFloorProp>[];

    for (var index = 0; index < props.length; index++) {
      final prop = props[index];
      var imageWidth = unit * prop.widthFactor;
      var imageHeight = unit * prop.heightFactor;
      var envelope = _rotatedSize(imageWidth, imageHeight, prop.angle);

      // 小さな画面や短い床では、列幅と安全な高さに合わせて縮めます。
      final maxWidth = useScatteredGround ? size.width * .15 : columnWidth - 6;
      final availableHeight = useScatteredGround ? sideHeight : floorHeight;
      final widthScale =
          math.min(1.0, math.max(0.0, maxWidth) / envelope.width).toDouble();
      final heightScale = math
          .min(1.0, math.max(0.0, availableHeight - 4) / envelope.height)
          .toDouble();
      final scale = math.min(widthScale, heightScale).toDouble();
      imageWidth *= scale;
      imageHeight *= scale;
      envelope = _rotatedSize(imageWidth, imageHeight, prop.angle);

      late double left;
      late double top;
      if (useScatteredGround) {
        final slot = slots[index];
        if (slot.belowCharacter) {
          final topRange =
              math.max(0.0, floorHeight - envelope.height).toDouble();
          top = floorTop + topRange * random.nextDouble();
          left = (size.width - envelope.width) / 2;
        } else {
          final topRange =
              math.max(0.0, sideHeight - envelope.height).toDouble();
          top = sideTop + topRange * slot.depth;
          final laneCenter = size.width * slot.x;
          final jitter = size.width * .015 * (random.nextDouble() * 2 - 1);
          left = laneCenter - envelope.width / 2 + jitter;
          left = left.clamp(0.0, size.width - envelope.width).toDouble();
        }
      } else {
        // 極端に短い表示域では足元の帯を5列に分けて衝突を防ぎます。
        final column = index;
        final cellLeft = column * columnWidth;
        final horizontalRange =
            math.max(0.0, columnWidth - envelope.width).toDouble();
        left = cellLeft + horizontalRange * (.12 + random.nextDouble() * .76);
        final topRange =
            math.max(0.0, floorHeight - envelope.height).toDouble();
        top = floorTop + topRange * (.08 + random.nextDouble() * .84);
      }
      placements.add(
        _PlacedFloorProp(
          spec: prop,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          envelopeSize: envelope,
          left: left,
          top: top,
        ),
      );
    }

    _cachedSize = size;
    _cachedLayout = placements;
    return placements;
  }

  Widget _buildProp(
    _PlacedFloorProp placement,
    int index,
    double devicePixelRatio,
  ) {
    final cacheWidth = math
        .max(1, (placement.imageWidth * devicePixelRatio * 2).round())
        .toInt();
    return Positioned(
      left: placement.left,
      top: placement.top,
      width: placement.envelopeSize.width,
      height: placement.envelopeSize.height,
      child: SizedBox(
        key: ValueKey<String>('training-home-floor-litter-item-$index'),
        width: placement.envelopeSize.width,
        height: placement.envelopeSize.height,
        child: Center(
          child: Transform.rotate(
            angle: placement.spec.angle,
            child: DecoratedBox(
              key: ValueKey<String>(
                'training-home-floor-litter-asset-$index',
              ),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(
                    AssetImage(placement.spec.assetPath),
                    width: cacheWidth,
                  ),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              child: SizedBox(
                width: placement.imageWidth,
                height: placement.imageHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Size _rotatedSize(double width, double height, double angle) {
    final cosine = math.cos(angle).abs();
    final sine = math.sin(angle).abs();
    return Size(
      width * cosine + height * sine,
      width * sine + height * cosine,
    );
  }
}

class _FloorPropSpec {
  const _FloorPropSpec({
    required this.assetPath,
    required this.widthFactor,
    required this.heightFactor,
    required this.angle,
  });

  final String assetPath;
  final double widthFactor;
  final double heightFactor;
  final double angle;
}

class _PlacedFloorProp {
  const _PlacedFloorProp({
    required this.spec,
    required this.imageWidth,
    required this.imageHeight,
    required this.envelopeSize,
    required this.left,
    required this.top,
  });

  final _FloorPropSpec spec;
  final double imageWidth;
  final double imageHeight;
  final Size envelopeSize;
  final double left;
  final double top;
}

class _FloorSlot {
  const _FloorSlot({
    required this.x,
    required this.depth,
    this.belowCharacter = false,
  });

  final double x;
  final double depth;
  final bool belowCharacter;
}
