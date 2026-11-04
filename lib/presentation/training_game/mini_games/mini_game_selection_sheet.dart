import 'package:flutter/material.dart';

import '../models/training_game_models.dart';
import '../training_home_controls.dart';
import '../training_game_theme.dart';
import 'mini_game_selection_frame.dart';

/// 選択だけを返し、ゲームの開始・報酬・待機時間は呼び出し元へ委ねます。
Future<TrainingActionType?> showMiniGameSelectionSheet(BuildContext context) {
  // シート表示中の入口連打で、同じ選択画面を重ねません。
  if (ModalRoute.of(context)?.isCurrent != true) {
    return Future.value();
  }
  return showModalBottomSheet<TrainingActionType>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: TrainingHomeStyle.navy.withValues(alpha: .55),
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => const MiniGameSelectionSheet(),
  );
}

/// 承認済みの濃紺グラデーション案で、2種類の練習を選びます。
class MiniGameSelectionSheet extends StatefulWidget {
  const MiniGameSelectionSheet({super.key});

  @override
  State<MiniGameSelectionSheet> createState() => _MiniGameSelectionSheetState();
}

class _MiniGameSelectionSheetState extends State<MiniGameSelectionSheet> {
  bool _selected = false;

  void _select(TrainingActionType? type) {
    // 閉じるアニメーション中の二度目のタップでHOMEまでpopしません。
    if (_selected || ModalRoute.of(context)?.isCurrent != true) return;
    _selected = true;
    Navigator.of(context).pop(type);
  }

  @override
  Widget build(BuildContext context) => TrainingGameTheme(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: MiniGameSelectionFrame(
              surface: MiniGameSelectionSurface.window,
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Container(height: 3, color: const Color(0xff57d5e0)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                    child: Column(children: [
                      _SelectionCard(
                        type: TrainingActionType.tackle,
                        number: '01',
                        title: 'タックル',
                        category: '反応・タイミング',
                        description: 'フェイントを見抜いて\n相手の動く方向をタップ',
                        asset:
                            'assets/images/training_game/minigames/tackle_attack_normal.png',
                        imageSize: const Size(63, 96),
                        onSelected: _select,
                      ),
                      const SizedBox(height: 14),
                      _SelectionCard(
                        type: TrainingActionType.passAndRun,
                        number: '02',
                        title: 'パス＆ラン',
                        category: 'フリック・パス',
                        description: '仲間に向けてフリック\n　パスをつないで走ろう',
                        asset:
                            'assets/images/training_game/selection/pass_run_ball.png',
                        imageSize: const Size(74, 68),
                        onSelected: _select,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _header() => ClipPath(
        clipper: const ShapeBorderClipper(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
        ),
        child: ColoredBox(
          color: TrainingHomeStyle.navy,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
            child: Row(children: [
              const Icon(Icons.sports_rugby, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ミニゲームを選ぶ',
                        style: TextStyle(fontSize: 19, color: Colors.white)),
                    SizedBox(height: 5),
                    Text('チャレンジする練習を選ぼう',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xff9edcff))),
                  ],
                ),
              ),
              MiniGameSelectionFrame(
                surface: MiniGameSelectionSurface.close,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    key: const ValueKey('mini-game-selection-close'),
                    tooltip: '閉じる',
                    padding: EdgeInsets.zero,
                    onPressed: () => _select(null),
                    icon: const Icon(Icons.close,
                        size: 21, color: TrainingHomeStyle.navy),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.type,
    required this.number,
    required this.title,
    required this.category,
    required this.description,
    required this.asset,
    required this.imageSize,
    required this.onSelected,
  });

  final TrainingActionType type;
  final String number;
  final String title;
  final String category;
  final String description;
  final String asset;
  final Size imageSize;
  final ValueChanged<TrainingActionType> onSelected;

  @override
  Widget build(BuildContext context) => MiniGameSelectionFrame(
        child: Material(
          color: Colors.transparent,
          shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('mini-game-selection-${type.name}'),
            onTap: () => onSelected(type),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(children: [
                Container(
                  width: 88,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xffe1f7ff), Color(0xff94d5f4)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(children: [
                    Positioned(
                      top: 4,
                      left: 7,
                      child: ExcludeSemantics(
                          child: Text(number,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xff4d9ac3)))),
                    ),
                    Center(
                        child: Image.asset(asset,
                            width: imageSize.width,
                            height: imageSize.height,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: TrainingHomeStyle.navy),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          color: const Color(0xffe2f3fd),
                          child: Text(category,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff0076bc))),
                        ),
                        const SizedBox(height: 11),
                        Text(description,
                            style: const TextStyle(fontSize: 11, height: 1.6)),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('プレイ', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 17, color: TrainingHomeStyle.navy),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}
