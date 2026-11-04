import 'package:flutter/material.dart';

enum TrainingWindowPattern {
  standard,
  plain,
  care,
  result,
  selectionWindow,
  selectionCard,
  start,
  pause,
}

/// 共通フレーム内の深海の光・水流・ヒレの装飾を描画します。
void paintTrainingOceanSurface(Canvas canvas, Rect rect,
    {required bool dark,
    TrainingWindowPattern pattern = TrainingWindowPattern.standard}) {
  canvas.save();
  canvas.clipRect(rect);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xff04192e), Color(0xff074660), Color(0xff087b91)]
            : const [Color(0xffffffff), Color(0xfff0fafb), Color(0xffdcedf3)],
        stops: const [0, .64, 1],
      ).createShader(rect),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(.95, -.85),
        radius: 1.5,
        colors: dark
            ? const [Color(0x4837cbd9), Color(0x000ba2c0)]
            : const [Color(0x88ffffff), Color(0x00ffffff)],
      ).createShader(rect),
  );
  final w = rect.width, h = rect.height;
  canvas.save();
  canvas.translate(rect.left, rect.top);
  if (pattern != TrainingWindowPattern.standard) {
    _paintWindowPattern(canvas, rect.size, dark: dark, pattern: pattern);
    canvas.restore();
    canvas.restore();
    return;
  }
  // 潮流の層。文字を避け、下辺と右辺へ流します。
  final flow = Path()
    ..moveTo(0, h * .89)
    ..cubicTo(w * .32, h * .99, w * .65, h * .64, w, h * .73)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
  canvas.drawPath(flow, Paint()..color = Color(dark ? 0x1604d8e4 : 0x1057aab8));
  for (var i = 0; i < 4; i++) {
    final y = h * (.84 + i * .055);
    canvas.drawPath(
      Path()
        ..moveTo(w * .48, h + 10 + i * 10)
        ..cubicTo(w * .66, y, w * .83, y + h * .11, w + 4, y - h * .1),
      Paint()
        ..color = Color(dark ? 0x2758dbe8 : 0x2472aeba)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.4 : .65,
    );
  }
  // ヒレの輪郭を抽象化した、控えめな反射光。
  canvas.drawPath(
    Path()
      ..moveTo(w * .77, h)
      ..quadraticBezierTo(w * .96, h * .80, w * .91, h * .55)
      ..quadraticBezierTo(w * .98, h * .67, w * .995, h * .82)
      ..lineTo(w, h)
      ..close(),
    Paint()..color = Color(dark ? 0x0effffff : 0x0a087b91),
  );
  canvas.restore();
  canvas.restore();
}

/// 図形はウィンドウの役割ごとに描き分け、中央の表示領域を空けます。
void _paintWindowPattern(Canvas canvas, Size size,
    {required bool dark, required TrainingWindowPattern pattern}) {
  final w = size.width, h = size.height;
  final line = Paint()
    ..color = Color(dark ? 0x3674ccdc : 0x3674adbf)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .7;
  final shade = Paint()..color = Color(dark ? 0x1842bfd5 : 0x1464afc4);
  switch (pattern) {
    case TrainingWindowPattern.standard:
    case TrainingWindowPattern.plain:
      return;
    case TrainingWindowPattern.result:
      // 結果窓：承認済みの流れる帯と、周辺の泡。
      final edge = Path()
        ..moveTo(-5, h * .98)
        ..cubicTo(w * .32, h * .69, w * .66, h * .96, w + 5, h * .64);
      canvas.drawPath(
          Path.from(edge)
            ..lineTo(w + 5, h + 5)
            ..lineTo(-5, h + 5)
            ..close(),
          shade);
      canvas.drawPath(edge, line);
      canvas.drawPath(
          edge.shift(const Offset(0, 7)),
          Paint()
            ..color = const Color(0x2374ccdc)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .5);
      // 文字・数値・ボタンの外側へ泡を散らします。
      for (final (x, y, r) in [
        (.13, .09, 3.5),
        (.92, .19, 6.0),
        (.065, .43, 5.0),
        (.95, .55, 2.8),
        (.10, .84, 7.0),
        (.92, .91, 4.0),
        (.40, .975, 2.5)
      ]) {
        final center = Offset(w * x, h * y);
        canvas.drawCircle(center, r, Paint()..color = const Color(0x0d8dd9e3));
        canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = const Color(0x4a7ac8d9)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .65);
        if (r >= 3.5) {
          canvas.drawArc(
              Rect.fromCircle(center: center, radius: r - 1.4),
              3.6,
              1.4,
              false,
              Paint()
                ..color = const Color(0x8acfeff6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .75);
        }
      }

      return;
    case TrainingWindowPattern.care:
      // お世話窓：大きく薄いさざ波と、周辺に分散した泡。
      final edge = Path()
        ..moveTo(-4, h * .92)
        ..cubicTo(w * .20, h * .63, w * .45, h * .93, w * .68, h * .83)
        ..quadraticBezierTo(w * .90, h * .70, w + 4, h * .82);
      canvas.drawPath(
          Path.from(edge)
            ..lineTo(w + 4, h + 4)
            ..lineTo(-4, h + 4)
            ..close(),
          Paint()..color = const Color(0x0c64afc4));
      canvas.drawPath(
          edge,
          Paint()
            ..color = const Color(0x2874adbf)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .55);
      canvas.drawPath(
          edge.shift(const Offset(0, 5)),
          Paint()
            ..color = const Color(0x1674adbf)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .45);
      for (final (x, y, r) in [
        (.07, .16, 5.0),
        (.04, .80, 7.0),
        (.96, .20, 6.0),
        (.98, .57, 3.0),
        (.91, .90, 4.0),
        (.66, .06, 2.5),
        (.23, .94, 2.5)
      ]) {
        final center = Offset(w * x, h * y);
        canvas.drawCircle(center, r, Paint()..color = const Color(0x1076adbf));
        canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = const Color(0x4876adbf)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .6);
        if (r >= 4) {
          canvas.drawArc(
              Rect.fromCircle(center: center, radius: r - 1.4),
              3.6,
              1.4,
              false,
              Paint()
                ..color = const Color(0xddffffff)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .8);
        }
      }

      return;
    case TrainingWindowPattern.selectionWindow:
      // 選択の外窓：下隅だけに置く幅広い層。
      canvas.drawPath(
          Path()
            ..moveTo(0, h)
            ..lineTo(w, h * .78)
            ..lineTo(w, h)
            ..close(),
          shade);
      canvas.drawLine(Offset(w * .35, h), Offset(w, h * .84), line);

      return;
    case TrainingWindowPattern.selectionCard:
      // 選択カード：右端をなぞる三本の細い曲線。
      for (var i = 0; i < 3; i++) {
        canvas.drawPath(
            Path()
              ..moveTo(w * (.83 + i * .06), h + 5)
              ..quadraticBezierTo(
                  w * (.99 + i * .02), h * .63, w * (.97 + i * .06), h * .18),
            Paint()
              ..color = Color(i == 0 ? 0x3874adbf : 0x1d74adbf)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .65);
      }

      return;
    case TrainingWindowPattern.start:
      // 開始ルール：左上の短い光の帯。
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(w * .42, 0)
            ..lineTo(w * .30, 8)
            ..lineTo(0, 8)
            ..close(),
          shade);
      canvas.drawLine(const Offset(16, 11), Offset(w * .21, 11), line);

      return;
    case TrainingWindowPattern.pause:
      // 一時停止：右下へ落ちる柔らかな折面。
      canvas.drawPath(
          Path()
            ..moveTo(w * .67, h)
            ..lineTo(w, h * .51)
            ..lineTo(w, h)
            ..close(),
          shade);
      canvas.drawLine(Offset(w * .76, h), Offset(w, h * .65), line);

      return;
  }
}
