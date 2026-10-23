import 'package:flutter/material.dart';

import '../models/training_game_models.dart';
import '../training_home_controls.dart';

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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => const MiniGameSelectionSheet(),
  );
}

/// 承認済みA案の、素材と短い操作説明を並べた選択カードです。
class MiniGameSelectionSheet extends StatefulWidget {
  const MiniGameSelectionSheet({super.key});

  @override
  State<MiniGameSelectionSheet> createState() => _MiniGameSelectionSheetState();
}

class _MiniGameSelectionSheetState extends State<MiniGameSelectionSheet> {
  bool _selected = false;

  void _select(TrainingActionType type) {
    // 閉じるアニメーション中の二度目のタップでHOMEまでpopしません。
    if (_selected || ModalRoute.of(context)?.isCurrent != true) return;
    _selected = true;
    Navigator.of(context).pop(type);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ミニゲームを選ぶ',
              style: TextStyle(
                fontFamily: 'LINESeedJP',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: TrainingHomeStyle.navy,
              ),
            ),
            const SizedBox(height: 24),
            _SelectionCard(
              type: TrainingActionType.tackle,
              title: 'タックル',
              category: '反応・タイミング',
              description: 'フェイントを見抜いて\n相手の動く方向をタップ',
              asset:
                  'assets/images/training_game/minigames/tackle_attack_normal.png',
              imageSize: const Size(66, 94),
              onSelected: _select,
            ),
            const SizedBox(height: 12),
            _SelectionCard(
              type: TrainingActionType.passAndRun,
              title: 'パス＆ラン',
              category: 'フリック・パス',
              description: '仲間をねらってフリック\nパスをつないで走ろう',
              asset: 'assets/images/training_game/selection/pass_run_ball.png',
              imageSize: const Size(70, 58),
              onSelected: _select,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.asset,
    required this.imageSize,
    required this.onSelected,
  });

  final TrainingActionType type;
  final String title;
  final String category;
  final String description;
  final String asset;
  final Size imageSize;
  final ValueChanged<TrainingActionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xfff5f7fa),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xffd1d9e2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('mini-game-selection-${type.name}'),
        onTap: () => onSelected(type),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 108,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffe8f1f8),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Image.asset(
                  asset,
                  width: imageSize.width,
                  height: imageSize.height,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'LINESeedJP',
                    color: TrainingHomeStyle.navy,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 20, color: TrainingHomeStyle.navy),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(category,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xff5e6c7e))),
                      const SizedBox(height: 12),
                      Text(description),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
