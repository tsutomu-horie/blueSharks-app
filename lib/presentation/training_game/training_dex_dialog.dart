import 'package:flutter/material.dart';

import 'sametaroh_asset.dart';

/// 図鑑の表示専用部品。取得・保存と解放判定は呼び出し元が担当します。
/// 呼び出し元の Obx 内で生成し、取得後の登録状態を反映してください。
class TrainingDexDialog extends StatelessWidget {
  const TrainingDexDialog({
    required this.registeredCount,
    required this.isPositionUnlocked,
    super.key,
  });

  final int registeredCount;
  final bool Function(String positionName) isPositionUnlocked;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * .8,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xff1f6feb),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(Icons.menu_book_rounded,
                              color: Color(0xff1f6feb), size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ずかん（$registeredCount/10 登録）',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        registeredCount == 0
                            ? '一軍で待っている10のポジション。\nいまはまだすべて未解放です。育て方しだいで、どれか1つに到達します。'
                            : '一軍で待っている10のポジション。\n解放したポジションは登録済みとして表示されます。',
                        style: TextStyle(
                          color: const Color(0xff5b6672),
                          fontSize: 12.5,
                          height: 1.75,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._dexPositions.map((position) => _buildDexCard(
                          position, isPositionUnlocked(position.name))),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// シミュレータHTMLの図鑑カードと同じ構成でポジションを表示します。
  Widget _buildDexCard(_DexPosition position, bool unlocked) {
    // 未解放の進化先も元の姿をシルエットで示すため、常に同じ素材を使います。
    final frame = SametarohAssets.positionFrameFor(position.name);
    final borderColor =
        unlocked ? const Color(0xff1f6feb) : const Color(0xffdfe4ea);
    final backgroundColor =
        unlocked ? const Color(0xffe8f0fe) : const Color(0xfffafbfc);
    return Opacity(
      opacity: 1,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 3),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? const Color(0xff1554b0)
                        : const Color(0xff5b6672),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    position.number,
                    style: TextStyle(color: Colors.white, fontSize: 10.5),
                  ),
                ),
                Text(
                  position.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  unlocked ? '✅ 登録済み' : '🔒 未解放',
                  style: TextStyle(
                    color: unlocked
                        ? const Color(0xff1554b0)
                        : const Color(0xff5b6672),
                    fontSize: 11,
                    fontWeight: unlocked ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (frame != null)
              Align(
                alignment: Alignment.center,
                child: unlocked
                    ? SametarohFrameImage(
                        alignment: Alignment.bottomCenter,
                        frame: frame,
                        width: 48,
                        height: 64,
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xffc5cbd2),
                          BlendMode.srcIn,
                        ),
                        child: Opacity(
                          opacity: .72,
                          child: SametarohFrameImage(
                            alignment: Alignment.bottomCenter,
                            frame: frame,
                            width: 48,
                            height: 64,
                          ),
                        ),
                      ),
              ),
            SizedBox(height: 5),
            _buildDexDetail('役割', position.role),
            _buildDexDetail('資質', position.talent),
          ],
        ),
      ),
    );
  }

  /// 図鑑カード内の説明行を表示します。
  Widget _buildDexDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: const TextStyle(color: Color(0xff5b6672)),
            ),
            TextSpan(text: value),
          ],
        ),
        style: TextStyle(fontSize: 11.5, height: 1.65),
      ),
    );
  }
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
