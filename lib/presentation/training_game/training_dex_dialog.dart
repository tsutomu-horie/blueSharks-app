import 'package:flutter/material.dart';

import 'sametaroh_asset.dart';
import 'training_game_theme.dart';
import 'training_home_controls.dart';
import 'mini_games/mini_game_selection_frame.dart';

/// 表示とスクロールだけを担当し、取得・保存・解放判定は呼び出し元で管理します。
class TrainingDexDialog extends StatelessWidget {
  const TrainingDexDialog({
    required this.registeredCount,
    required this.isPositionUnlocked,
    super.key,
  });

  final int registeredCount;
  final bool Function(String positionName) isPositionUnlocked;

  @override
  Widget build(BuildContext context) => TrainingGameTheme(
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * .84),
            child: MiniGameSelectionFrame(
              surface: MiniGameSelectionSurface.window,
              padding: const EdgeInsets.all(4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipPath(
                      clipper: const ShapeBorderClipper(
                          shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12)))),
                      child: ColoredBox(
                        color: TrainingHomeStyle.navy,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(children: [
                            const Icon(Icons.menu_book,
                                color: Colors.white, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('ずかん（$registeredCount/10 登録）',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white))),
                          ]),
                        ),
                      ),
                    ),
                    Container(height: 3, color: const Color(0xff39bdf5)),
                    Expanded(
                        child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._dexPositions.map((position) => _buildDexCard(
                                position, isPositionUnlocked(position.name))),
                          ]),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: MiniGameSelectionFrame(
                        surface: MiniGameSelectionSurface.close,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: TrainingHomeStyle.navy,
                              shape: const BeveledRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)))),
                          child: const Text('閉じる',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      );

  Widget _buildDexCard(_DexPosition position, bool unlocked) {
    final frame = SametarohAssets.positionFrameFor(position.name);
    final statusColor =
        unlocked ? const Color(0xff0076bc) : const Color(0xff667b96);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MiniGameSelectionFrame(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: TrainingHomeStyle.navy),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const ShapeDecoration(
                        color: TrainingHomeStyle.navy,
                        shape: BeveledRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(4)))),
                    child: Text(position.number,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Text(position.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: unlocked
                        ? const Color(0xffe0f2fd)
                        : const Color(0xffe9eef4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(unlocked ? Icons.check_circle : Icons.lock_outline,
                          size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(unlocked ? '登録済み' : '未解放',
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
            if (frame != null)
              Align(
                alignment: Alignment.center,
                child: unlocked
                    ? SametarohFrameImage(
                        frame: frame,
                        width: 84,
                        height: 112,
                        alignment: Alignment.bottomCenter)
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                            Color(0xff8c9db6), BlendMode.srcIn),
                        child: SametarohFrameImage(
                            frame: frame,
                            width: 84,
                            height: 112,
                            alignment: Alignment.bottomCenter)),
              ),
            const SizedBox(height: 5),
            _buildDexDetail('役割', position.role),
            _buildDexDetail('資質', position.talent),
          ]),
        ),
      ),
    );
  }

  Widget _buildDexDetail(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$label  ',
                  style: const TextStyle(color: Color(0xff0076bc))),
              TextSpan(text: value),
            ]),
            style: const TextStyle(fontSize: 13, height: 1.65)),
      );
}

/// 図鑑に表示するポジション説明です。
class _DexPosition {
  const _DexPosition({
    required this.number,
    required this.name,
    required this.role,
    required this.talent,
  });

  final String number;
  final String name;
  final String role;
  final String talent;
}

/// シミュレータHTMLの10ポジション定義を図鑑表示用に整理します。
const _dexPositions = <_DexPosition>[
  _DexPosition(
    number: '1・3',
    name: 'プロップ',
    role: 'スクラム最前列。組み合いを支える土台',
    talent: '体重と押す力',
  ),
  _DexPosition(
    number: '2',
    name: 'フッカー',
    role: '最前列の中央。ボールを掻き出す',
    talent: '正確性と技術',
  ),
  _DexPosition(
    number: '4・5',
    name: 'ロック',
    role: '第2列。スクラムとラインアウトを支える',
    talent: '上背とパワー',
  ),
  _DexPosition(
    number: '6・7',
    name: 'フランカー',
    role: '第3列の両サイド。接点へ最速で到達',
    talent: '運動量・タックル・スピード',
  ),
  _DexPosition(
    number: '8',
    name: 'ナンバーエイト',
    role: '第3列の中央。ボールを持ち出す',
    talent: 'パワーと判断力',
  ),
  _DexPosition(
    number: '9',
    name: 'スクラムハーフ',
    role: 'フォワードとバックスの接続点',
    talent: 'テンポ・展開の速さ',
  ),
  _DexPosition(
    number: '10',
    name: 'スタンドオフ',
    role: '攻撃の司令塔。陣形とテンポを決める',
    talent: '判断力・状況把握',
  ),
  _DexPosition(
    number: '12・13',
    name: 'センター',
    role: '中央で突破し、防御では相手を止める',
    talent: '突進力とコンタクト耐性',
  ),
  _DexPosition(
    number: '11・14',
    name: 'ウイング',
    role: '最外側のフィニッシャー',
    talent: '純粋なスピード',
  ),
  _DexPosition(
    number: '15',
    name: 'フルバック',
    role: '最後尾。攻撃の起点になる',
    talent: '空中戦・キック処理・広い視野',
  ),
];
