import 'dart:async';

import 'package:flutter/material.dart';

import 'models/training_game_models.dart';

/// 鮫太朗の状態別イラストをまとめたアセット定義です。
abstract final class SametarohAssets {
  static const normalFrames = <SametarohFrame>[
    SametarohFrame(
      asset: 'assets/images/sametaroh/normal_sameraroh_1.png',
      sourceSize: Size(144, 323),
      canvasSize: Size(166, 323),
    ),
    SametarohFrame(
      asset: 'assets/images/sametaroh/normal_sametaroh_2.png',
      sourceSize: Size(166, 323),
      canvasSize: Size(166, 323),
    ),
  ];

  static const journeyFrames = <SametarohFrame>[
    SametarohFrame(
      asset: 'assets/images/sametaroh/walk_sametaroh_1.png',
      sourceSize: Size(160, 303),
      canvasSize: Size(161, 303),
    ),
    SametarohFrame(
      asset: 'assets/images/sametaroh/walk_sametaroh_2.png',
      sourceSize: Size(161, 303),
      canvasSize: Size(161, 303),
    ),
  ];

  static const initialFrames = <TrainingActionType, SametarohFrame>{
    TrainingActionType.meal: SametarohFrame(
      asset: 'assets/images/sametaroh/eating_sametaroh_start.png',
      sourceSize: Size(292, 295),
      canvasSize: Size(292, 309),
    ),
  };

  static const careFrames = <TrainingActionType, List<SametarohFrame>>{
    TrainingActionType.meal: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/eating_sametaroh_1.png',
        sourceSize: Size(289, 309),
        canvasSize: Size(292, 309),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/eating_sametaroh_2.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(292, 309),
      ),
    ],
    TrainingActionType.clean: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/claening_sametaroh_1.png',
        sourceSize: Size(157, 314),
        canvasSize: Size(175, 314),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/cleaning_sametaroh_2.png',
        sourceSize: Size(156, 314),
        canvasSize: Size(175, 314),
      ),
    ],
    TrainingActionType.rest: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/sleeping_sametaroh_1.png',
        sourceSize: Size(448, 267),
        canvasSize: Size(448, 301),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/sleeping_sametaroh_2.png',
        sourceSize: Size(420, 301),
        canvasSize: Size(448, 301),
      ),
    ],
    TrainingActionType.squat: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/training_sametarohj_1.png',
        sourceSize: Size(171, 315),
        canvasSize: Size(201, 315),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/training_sametaroh_2.png',
        sourceSize: Size(198, 315),
        canvasSize: Size(201, 315),
      ),
    ],
    TrainingActionType.work: [
      SametarohFrame(
        asset: 'assets/images/sametaroh/working_sametaroh_1.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(309, 349),
      ),
      SametarohFrame(
        asset: 'assets/images/sametaroh/working_sametaroh_2.png',
        sourceSize: Size(288, 309),
        canvasSize: Size(309, 349),
      ),
    ],
  };

  static const completionFrames = <TrainingActionType, SametarohFrame>{
    TrainingActionType.meal: SametarohFrame(
      asset: 'assets/images/sametaroh/eating_complete_sametaroh.png',
      sourceSize: Size(289, 305),
      canvasSize: Size(292, 309),
    ),
    TrainingActionType.clean: SametarohFrame(
      asset: 'assets/images/sametaroh/cleaning_complete_sametaroh.png',
      sourceSize: Size(175, 302),
      canvasSize: Size(175, 314),
    ),
    TrainingActionType.rest: SametarohFrame(
      asset: 'assets/images/sametaroh/sleeping_complete_sametaroh.png',
      sourceSize: Size(425, 299),
      canvasSize: Size(448, 301),
    ),
    TrainingActionType.squat: SametarohFrame(
      asset: 'assets/images/sametaroh/training_complete_sametaroh.png',
      sourceSize: Size(201, 302),
      canvasSize: Size(201, 315),
    ),
    TrainingActionType.work: SametarohFrame(
      asset: 'assets/images/sametaroh/warking_complete_sametaroh.png',
      sourceSize: Size(309, 349),
      canvasSize: Size(309, 349),
    ),
  };

  /// 支給図を原本のポーズごとに保持します。状態保存や分岐計算には使用しません。
  static const suppliedFrames = <String, SametarohFrame>{
    'pr.idle_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/idle_1.png',
      sourceSize: Size(224, 356),
      canvasSize: Size(224, 356),
    ),
    'pr.idle_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/idle_2.png',
      sourceSize: Size(224, 354),
      canvasSize: Size(224, 356),
    ),
    'pr.move_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/move_1.png',
      sourceSize: Size(196, 312),
      canvasSize: Size(196, 312),
    ),
    'pr.move_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/move_2.png',
      sourceSize: Size(196, 312),
      canvasSize: Size(196, 312),
    ),
    'pr.clean_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/clean_1.png',
      sourceSize: Size(168, 278),
      canvasSize: Size(185, 278),
    ),
    'pr.clean_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/clean_2.png',
      sourceSize: Size(170, 278),
      canvasSize: Size(185, 278),
    ),
    'pr.clean_done': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/clean_done.png',
      sourceSize: Size(185, 273),
      canvasSize: Size(185, 278),
    ),
    'pr.squat_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/squat_1.png',
      sourceSize: Size(191, 260),
      canvasSize: Size(213, 272),
    ),
    'pr.squat_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/squat_2.png',
      sourceSize: Size(213, 272),
      canvasSize: Size(213, 272),
    ),
    'pr.squat_done': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/squat_done.png',
      sourceSize: Size(189, 267),
      canvasSize: Size(213, 272),
    ),
    'pr.work_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/work_1.png',
      sourceSize: Size(292, 354),
      canvasSize: Size(370, 372),
    ),
    'pr.work_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/work_2.png',
      sourceSize: Size(290, 354),
      canvasSize: Size(370, 372),
    ),
    'pr.work_done': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/work_done.png',
      sourceSize: Size(370, 372),
      canvasSize: Size(370, 372),
    ),
    'pr.meal_start': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/meal_start.png',
      sourceSize: Size(292, 340),
      canvasSize: Size(292, 342),
    ),
    'pr.meal_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/meal_1.png',
      sourceSize: Size(290, 342),
      canvasSize: Size(292, 342),
    ),
    'pr.meal_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/meal_2.png',
      sourceSize: Size(290, 342),
      canvasSize: Size(292, 342),
    ),
    'pr.meal_done': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/meal_done.png',
      sourceSize: Size(292, 340),
      canvasSize: Size(292, 342),
    ),
    'pr.rest_1': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/rest_1.png',
      sourceSize: Size(426, 290),
      canvasSize: Size(426, 354),
    ),
    'pr.rest_2': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/rest_2.png',
      sourceSize: Size(426, 320),
      canvasSize: Size(426, 354),
    ),
    'pr.rest_done': SametarohFrame(
      asset: 'assets/images/training_game/main/pr/rest_done.png',
      sourceSize: Size(426, 354),
      canvasSize: Size(426, 354),
    ),
    'sh.idle_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/idle_1.png',
      sourceSize: Size(194, 345),
      canvasSize: Size(194, 345),
    ),
    'sh.idle_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/idle_2.png',
      sourceSize: Size(194, 345),
      canvasSize: Size(194, 345),
    ),
    'sh.move_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/move_1.png',
      sourceSize: Size(172, 306),
      canvasSize: Size(172, 306),
    ),
    'sh.move_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/move_2.png',
      sourceSize: Size(170, 306),
      canvasSize: Size(172, 306),
    ),
    'sh.clean_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/clean_1.png',
      sourceSize: Size(172, 316),
      canvasSize: Size(196, 316),
    ),
    'sh.clean_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/clean_2.png',
      sourceSize: Size(172, 316),
      canvasSize: Size(196, 316),
    ),
    'sh.clean_done': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/clean_done.png',
      sourceSize: Size(196, 316),
      canvasSize: Size(196, 316),
    ),
    'sh.squat_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/squat_1.png',
      sourceSize: Size(206, 296),
      canvasSize: Size(220, 318),
    ),
    'sh.squat_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/squat_2.png',
      sourceSize: Size(216, 318),
      canvasSize: Size(220, 318),
    ),
    'sh.squat_done': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/squat_done.png',
      sourceSize: Size(220, 306),
      canvasSize: Size(220, 318),
    ),
    'sh.work_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/work_1.png',
      sourceSize: Size(290, 312),
      canvasSize: Size(318, 354),
    ),
    'sh.work_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/work_2.png',
      sourceSize: Size(292, 312),
      canvasSize: Size(318, 354),
    ),
    'sh.work_done': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/work_done.png',
      sourceSize: Size(318, 354),
      canvasSize: Size(318, 354),
    ),
    'sh.meal_start': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/meal_start.png',
      sourceSize: Size(294, 312),
      canvasSize: Size(294, 312),
    ),
    'sh.meal_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/meal_1.png',
      sourceSize: Size(290, 308),
      canvasSize: Size(294, 312),
    ),
    'sh.meal_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/meal_2.png',
      sourceSize: Size(290, 308),
      canvasSize: Size(294, 312),
    ),
    'sh.meal_done': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/meal_done.png',
      sourceSize: Size(292, 308),
      canvasSize: Size(294, 312),
    ),
    'sh.rest_1': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/rest_1.png',
      sourceSize: Size(480, 300),
      canvasSize: Size(480, 340),
    ),
    'sh.rest_2': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/rest_2.png',
      sourceSize: Size(473, 333),
      canvasSize: Size(480, 340),
    ),
    'sh.rest_done': SametarohFrame(
      asset: 'assets/images/training_game/main/sh/rest_done.png',
      sourceSize: Size(480, 340),
      canvasSize: Size(480, 340),
    ),
    'wtb.idle_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/idle_1.png',
      sourceSize: Size(160, 342),
      canvasSize: Size(175, 342),
    ),
    'wtb.idle_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/idle_2.png',
      sourceSize: Size(175, 340),
      canvasSize: Size(175, 342),
    ),
    'wtb.move_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/move_1.png',
      sourceSize: Size(175, 342),
      canvasSize: Size(175, 342),
    ),
    'wtb.move_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/move_2.png',
      sourceSize: Size(175, 342),
      canvasSize: Size(175, 342),
    ),
    'wtb.clean_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/clean_1.png',
      sourceSize: Size(168, 340),
      canvasSize: Size(191, 340),
    ),
    'wtb.clean_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/clean_2.png',
      sourceSize: Size(168, 340),
      canvasSize: Size(191, 340),
    ),
    'wtb.clean_done': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/clean_done.png',
      sourceSize: Size(191, 340),
      canvasSize: Size(191, 340),
    ),
    'wtb.squat_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/squat_1.png',
      sourceSize: Size(188, 340),
      canvasSize: Size(214, 349),
    ),
    'wtb.squat_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/squat_2.png',
      sourceSize: Size(214, 349),
      canvasSize: Size(214, 349),
    ),
    'wtb.squat_done': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/squat_done.png',
      sourceSize: Size(188, 340),
      canvasSize: Size(214, 349),
    ),
    'wtb.work_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/work_1.png',
      sourceSize: Size(254, 319),
      canvasSize: Size(282, 352),
    ),
    'wtb.work_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/work_2.png',
      sourceSize: Size(256, 319),
      canvasSize: Size(282, 352),
    ),
    'wtb.work_done': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/work_done.png',
      sourceSize: Size(282, 352),
      canvasSize: Size(282, 352),
    ),
    'wtb.meal_start': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/meal_start.png',
      sourceSize: Size(258, 305),
      canvasSize: Size(258, 319),
    ),
    'wtb.meal_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/meal_1.png',
      sourceSize: Size(254, 317),
      canvasSize: Size(258, 319),
    ),
    'wtb.meal_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/meal_2.png',
      sourceSize: Size(254, 319),
      canvasSize: Size(258, 319),
    ),
    'wtb.meal_done': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/meal_done.png',
      sourceSize: Size(256, 315),
      canvasSize: Size(258, 319),
    ),
    'wtb.rest_1': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/rest_1.png',
      sourceSize: Size(375, 256),
      canvasSize: Size(375, 338),
    ),
    'wtb.rest_2': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/rest_2.png',
      sourceSize: Size(370, 287),
      canvasSize: Size(375, 338),
    ),
    'wtb.rest_done': SametarohFrame(
      asset: 'assets/images/training_game/main/wtb/rest_done.png',
      sourceSize: Size(373, 338),
      canvasSize: Size(375, 338),
    ),
    'jersey.prop_helmet': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/prop_helmet.png',
      sourceSize: Size(245, 390),
      canvasSize: Size(245, 390),
    ),
    'jersey.prop_plain': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/prop_plain.png',
      sourceSize: Size(243, 385),
      canvasSize: Size(243, 385),
    ),
    'jersey.hooker': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/hooker.png',
      sourceSize: Size(245, 390),
      canvasSize: Size(245, 390),
    ),
    'jersey.lock': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/lock.png',
      sourceSize: Size(190, 422),
      canvasSize: Size(190, 422),
    ),
    'jersey.flanker': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/flanker.png',
      sourceSize: Size(263, 415),
      canvasSize: Size(263, 415),
    ),
    'jersey.number_eight': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/number_eight.png',
      sourceSize: Size(293, 396),
      canvasSize: Size(293, 396),
    ),
    'jersey.scrum_half_and_stand_off': SametarohFrame(
      asset:
          'assets/images/training_game/main/jersey/scrum_half_and_stand_off.png',
      sourceSize: Size(231, 402),
      canvasSize: Size(231, 402),
    ),
    'jersey.center': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/center.png',
      sourceSize: Size(234, 376),
      canvasSize: Size(234, 376),
    ),
    'jersey.wing': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/wing.png',
      sourceSize: Size(210, 415),
      canvasSize: Size(210, 415),
    ),
    'jersey.fullback': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/fullback.png',
      sourceSize: Size(230, 394),
      canvasSize: Size(230, 394),
    ),
    'jersey.newborn': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/newborn.png',
      sourceSize: Size(140, 228),
      canvasSize: Size(140, 228),
    ),
    'jersey.ghost': SametarohFrame(
      asset: 'assets/images/training_game/main/jersey/ghost.png',
      sourceSize: Size(234, 402),
      canvasSize: Size(234, 402),
    ),
  };

  static SametarohFrame get newbornFrame => suppliedFrames['jersey.newborn']!;

  /// 原本で確認できたポジションだけを選び、未知値は既存表示へ戻します。
  static SametarohFrame? positionFrameFor(String position) {
    final pose = const {
      'プロップ': 'prop_plain',
      'フッカー': 'hooker',
      'ロック': 'lock',
      'フランカー': 'flanker',
      'ナンバーエイト': 'number_eight',
      'スクラムハーフ': 'scrum_half_and_stand_off',
      'スタンドオフ': 'scrum_half_and_stand_off',
      'センター': 'center',
      'ウイング': 'wing',
      'フルバック': 'fullback',
    }[position];
    return pose == null ? null : suppliedFrames['jersey.$pose'];
  }

  static const supportedBodyKeys = ['pr', 'sh', 'wtb'];

  /// Controllerが既に確定した大別表示を、本人採用済みの素材へ対応させます。
  /// 未判定・未知の表示から分岐を推測しません。
  static String? bodyKeyForBranch(String? branch) => const {
        'A フォワード型': 'pr',
        'B 司令塔型': 'sh',
        'C バックス型': 'wtb',
      }[branch];

  // 同じ体形の再buildで画像の先読み・初期フレームをリセットしないよう、
  // 連番リストを一度だけ作成します。
  static final _bodySequences = <String, List<SametarohFrame>>{
    for (final body in supportedBodyKeys)
      for (final action in [
        'idle',
        'move',
        'meal',
        'clean',
        'rest',
        'squat',
        'work'
      ])
        '$body.$action': List<SametarohFrame>.unmodifiable([
          suppliedFrames['$body.${action}_1']!,
          suppliedFrames['$body.${action}_2']!,
        ]),
  };

  static List<SametarohFrame> idleFramesForBodyKey(String? bodyKey) =>
      _bodySequences['$bodyKey.idle'] ?? normalFrames;

  static List<SametarohFrame> journeyFramesForBodyKey(String? bodyKey) =>
      _bodySequences['$bodyKey.move'] ?? journeyFrames;

  static SametarohFrame? initialFrameFor(
    TrainingActionType type, {
    String? bodyKey,
  }) =>
      type == TrainingActionType.meal && supportedBodyKeys.contains(bodyKey)
          ? suppliedFrames['$bodyKey.meal_start']
          : initialFrames[type];

  static List<SametarohFrame> careFramesFor(
    TrainingActionType type, {
    String? bodyKey,
  }) {
    final frames = careFrames[type];
    if (frames == null) {
      throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。');
    }
    return _bodySequences['$bodyKey.${type.name}'] ?? frames;
  }

  static SametarohFrame completionFrameFor(
    TrainingActionType type, {
    String? bodyKey,
  }) {
    final frame = completionFrames[type];
    if (frame == null) {
      throw ArgumentError.value(type, 'type', 'お世話画面の対象外です。');
    }
    return supportedBodyKeys.contains(bodyKey)
        ? suppliedFrames['$bodyKey.${type.name}_done']!
        : frame;
  }
}

/// 1枚の素材を共通キャンバスへ配置するための情報です。
class SametarohFrame {
  const SametarohFrame({
    required this.asset,
    required this.sourceSize,
    required this.canvasSize,
  });

  final String asset;
  final Size sourceSize;
  final Size canvasSize;
}

/// 指定されたフレームを一定間隔で切り替えて表示します。
class SametarohAnimatedImage extends StatefulWidget {
  const SametarohAnimatedImage({
    required this.frames,
    required this.width,
    required this.height,
    this.initialFrame,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    super.key,
  });

  final List<SametarohFrame> frames;
  final double width;
  final double height;
  final SametarohFrame? initialFrame;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  State<SametarohAnimatedImage> createState() => _SametarohAnimatedImageState();
}

class _SametarohAnimatedImageState extends State<SametarohAnimatedImage> {
  static const frameDuration = Duration(milliseconds: 650);

  Timer? _timer;
  int _frameIndex = 0;
  int _precacheGeneration = 0;
  bool _isReady = false;
  bool _showInitialFrame = false;

  @override
  void initState() {
    super.initState();
    _showInitialFrame = widget.initialFrame != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_precacheAndStart());
  }

  @override
  void didUpdateWidget(covariant SametarohAnimatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final framesChanged = oldWidget.frames != widget.frames;
    final initialFrameChanged =
        oldWidget.initialFrame?.asset != widget.initialFrame?.asset;
    if (framesChanged || initialFrameChanged) {
      _frameIndex = 0;
      _isReady = false;
      _showInitialFrame = widget.initialFrame != null;
      unawaited(_precacheAndStart());
    }
  }

  /// 初期フレームを先に表示し、残りのフレームを先読みしてから再生します。
  Future<void> _precacheAndStart() async {
    final generation = ++_precacheGeneration;
    _timer?.cancel();
    _timer = null;
    final initialFrame = widget.initialFrame;
    if (initialFrame != null) {
      await _precacheFrame(initialFrame);
      if (!mounted || generation != _precacheGeneration) return;
      setState(() => _isReady = true);
    }
    await Future.wait<void>(widget.frames.map(_precacheFrame));
    if (!mounted || generation != _precacheGeneration) return;
    if (!_isReady) setState(() => _isReady = true);
    _startTimer();
  }

  /// 1枚の先読み失敗が、他フレームの先読みを中断しないようにします。
  Future<void> _precacheFrame(SametarohFrame frame) async {
    try {
      await precacheImage(AssetImage(frame.asset), context);
    } catch (_) {
      // 失敗した素材は通常のImageProviderの読み込みに任せて再生します。
    }
  }

  void _startTimer() {
    if (widget.frames.length < 2 || _timer != null) return;
    _timer = Timer.periodic(frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_showInitialFrame) {
          _showInitialFrame = false;
          _frameIndex = 0;
        } else {
          _frameIndex = (_frameIndex + 1) % widget.frames.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      final initialFrame = widget.initialFrame;
      if (initialFrame != null) {
        return SametarohFrameImage(
          frame: initialFrame,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          semanticLabel: widget.semanticLabel,
        );
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final frame = _showInitialFrame && widget.initialFrame != null
        ? widget.initialFrame!
        : widget.frames[_frameIndex];
    return SametarohFrameImage(
      frame: frame,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel,
    );
  }
}

/// 共通キャンバス上に1枚の鮫太朗素材を描画します。
class SametarohFrameImage extends StatelessWidget {
  const SametarohFrameImage({
    required this.frame,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
    super.key,
  });

  final SametarohFrame frame;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: fit,
        alignment: alignment,
        child: SizedBox(
          width: frame.canvasSize.width,
          height: frame.canvasSize.height,
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: frame.sourceSize.width,
              height: frame.sourceSize.height,
              child: Image.asset(
                frame.asset,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
