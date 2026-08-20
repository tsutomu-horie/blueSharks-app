import 'package:flutter/material.dart';

/// ミニゲーム選択カードに表示する操作イメージの種類です。
enum MiniGameSelectionThumbnailType {
  tackle,
  passAndRun,
}

/// 実際のミニゲームに登場するキャラクターと操作を抜粋したサムネイルです。
class MiniGameSelectionThumbnail extends StatelessWidget {
  /// サムネイルを作成します。
  const MiniGameSelectionThumbnail({
    required this.type,
    super.key,
  });

  final MiniGameSelectionThumbnailType type;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: type == MiniGameSelectionThumbnailType.tackle
            ? const _TackleGamePreview()
            : const _PassAndRunGamePreview(),
      ),
    );
  }
}

/// タックル画面から、鮫太朗・相手・上下タップを抜粋したプレビューです。
class _TackleGamePreview extends StatelessWidget {
  const _TackleGamePreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 実ゲームと同じく、上下の入力エリアを色分けします。
        Column(
          children: [
            Expanded(child: Container(color: const Color(0xffb9df9c))),
            Container(height: 2, color: Colors.white70),
            Expanded(child: Container(color: const Color(0xff8fca70))),
          ],
        ),
        const Positioned.fill(child: CustomPaint(painter: _TackleGuidePainter())),
        const Align(
          alignment: Alignment(-.55, 0),
          child: Text('🦈', style: TextStyle(fontSize: 44)),
        ),
        const Align(
          alignment: Alignment(.58, -.18),
          child: Text('🏃', style: TextStyle(fontSize: 38)),
        ),
        const Positioned(
          left: 12,
          bottom: 8,
          child: Text(
            '● 上／下をタップ',
            style: TextStyle(
              color: Color(0xff1d4ed8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// パス＆ラン画面から、2レーン・キャラクター・フリックを抜粋したプレビューです。
class _PassAndRunGamePreview extends StatelessWidget {
  const _PassAndRunGamePreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: const Color(0xff79ba63))),
        const Positioned.fill(child: CustomPaint(painter: _PassAndRunGuidePainter())),
        const Align(
          alignment: Alignment(-.3, .36),
          child: Text('🦈', style: TextStyle(fontSize: 44)),
        ),
        const Align(
          alignment: Alignment(.42, -.28),
          child: Text('🏃', style: TextStyle(fontSize: 36)),
        ),
        const Align(
          alignment: Alignment(-.08, .18),
          child: Text('🏉', style: TextStyle(fontSize: 18)),
        ),
        const Positioned(
          left: 12,
          bottom: 8,
          child: Text(
            '● 仲間の方向へフリック',
            style: TextStyle(
              color: Color(0xffdbeafe),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// タックルの接近と、上下の入力方向を描画します。
class _TackleGuidePainter extends CustomPainter {
  const _TackleGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final approachStart = Offset(size.width * .82, size.height * .38);
    final approachEnd = Offset(size.width * .58, size.height * .38);
    final inputOrigin = Offset(size.width * .48, size.height * .5);
    final inputUp = Offset(size.width * .48, size.height * .16);
    final inputDown = Offset(size.width * .48, size.height * .84);
    final inputPaint = _arrowPaint(const Color(0xff8f2fd0));

    // 本編の接近演出に合わせ、相手が右から左へ進む水平矢印を描きます。
    _drawArrow(
      canvas,
      approachStart,
      approachEnd,
      _arrowPaint(const Color(0xff94a3b8)),
    );
    // 相手のフェイント後に選択する上下2方向を、同じ始点から描きます。
    _drawArrow(canvas, inputOrigin, inputUp, inputPaint);
    _drawArrow(canvas, inputOrigin, inputDown, inputPaint);
  }

  @override
  bool shouldRepaint(covariant _TackleGuidePainter oldDelegate) => false;
}

/// パス＆ランの縦レーンと、仲間へ向かうパス・フリックを描画します。
class _PassAndRunGuidePainter extends CustomPainter {
  const _PassAndRunGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.2;
    final leftLane = size.width * .35;
    final rightLane = size.width * .7;
    _drawDashedLine(
      canvas,
      Offset(leftLane, 8),
      Offset(leftLane, size.height - 8),
      lanePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(rightLane, 8),
      Offset(rightLane, size.height - 8),
      lanePaint,
    );
    _drawArrow(
      canvas,
      Offset(size.width * .43, size.height * .62),
      Offset(size.width * .65, size.height * .34),
      _arrowPaint(const Color(0xff8f2fd0)),
    );
    _drawArrow(
      canvas,
      Offset(size.width * .16, size.height * .72),
      Offset(size.width * .28, size.height * .6),
      _arrowPaint(const Color(0xff2563eb)),
    );
  }

  @override
  bool shouldRepaint(covariant _PassAndRunGuidePainter oldDelegate) => false;
}

/// 矢印共通の線スタイルを返します。
Paint _arrowPaint(Color color) {
  return Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
}

/// 線の終点へ矢印を描画します。
void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
  canvas.drawLine(start, end, paint);
  final direction = end - start;
  if (direction.distance == 0) return;
  final normalized = direction / direction.distance;
  final perpendicular = Offset(-normalized.dy, normalized.dx);
  final arrowBase = end - normalized * 10;
  canvas.drawLine(end, arrowBase + perpendicular * 5, paint);
  canvas.drawLine(end, arrowBase - perpendicular * 5, paint);
}

/// 縦レーン用の破線を描画します。
void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  final direction = end - start;
  final length = direction.distance;
  if (length == 0) return;
  final normalized = direction / length;
  for (var offset = 0.0; offset < length; offset += 8) {
    final segmentEnd = (offset + 4).clamp(0, length).toDouble();
    canvas.drawLine(
      start + normalized * offset,
      start + normalized * segmentEnd,
      paint,
    );
  }
}
