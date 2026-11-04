import 'package:flutter/material.dart';

class TackleRankBadge extends StatelessWidget {
  const TackleRankBadge({super.key, required this.rank, required this.color});

  final String rank;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 132,
        height: 132,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .1),
          border: Border.all(color: color, width: 3),
        ),
        child: Transform.translate(
          // LINESeedJP Bold・88pxの文字の上下端を円の中央へ合わせ、
          // D/B/Cが左寄りに見える左右の描画量の偏りも補正します。
          offset: switch (rank) {
            'S' => const Offset(-.25, -2.25),
            'A' => const Offset(0, -2.25),
            'B' => const Offset(1.25, -2.25),
            'C' => const Offset(2.75, -2.25),
            'D' => const Offset(2, -2.25),
            _ => Offset.zero,
          },
          child: Text(
            rank,
            // アイコンと同じ固定サイズのバッジ内で、評価文字を収めます。
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: 'LINESeedJP',
              color: color,
              fontSize: 88,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ),
      );
}
