import 'package:flutter/material.dart';

/// 共通フレーム内の深海の光・水流・ヒレの装飾を描画します。
void paintTrainingOceanSurface(Canvas canvas, Rect rect, {required bool dark}) {
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
