import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 承認された参考図のライン構成を90度回し、ホームの配色で描くコートです。
class TacklePitchPainter extends CustomPainter {
  TacklePitchPainter(
      {this.zoom = 1, this.quarterTurns = 0, this.longitudinalOffsetMeters = 0})
      : assert(zoom > 0);
  final double zoom;
  final int quarterTurns;
  final double longitudinalOffsetMeters;

  @override
  void paint(Canvas canvas, Size size) {
    final offset =
        longitudinalOffsetMeters * size.height * .86 / 552 * 394 / 100;
    // 横幅の広い画面でも、中央線と拡大される中央マークが表示端に残らない倍率にします。
    const edgeClearance = 10.0;
    const centerMarkHalfStroke = 1.75;
    final centerMarkHalfLengthPerZoom = size.height * .86 / 552;
    final offsetClearancePerZoom = offset.abs() - centerMarkHalfLengthPerZoom;
    final paintZoom =
        zoom > 1 && quarterTurns.isOdd && offsetClearancePerZoom > 0
            ? math
                .max(
                  zoom,
                  (size.width / 2 + edgeClearance + centerMarkHalfStroke) /
                      offsetClearancePerZoom,
                )
                .toDouble()
            : zoom;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (paintZoom > 1) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xff73b33c),
                  Color(0xff83bd42),
                  Color(0xff83bd42),
                  Color(0xff73b33c)
                ],
                stops: [
                  0,
                  .25,
                  .75,
                  1
                ]).createShader(Offset.zero & size));
    }
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(paintZoom);
    canvas.rotate(quarterTurns * math.pi / 2);
    canvas.translate(-size.width / 2, -size.height / 2 - offset);
    // 全景はホームの色帯、近距離は左右対称の明暗。ライン配置は参考図を維持。
    const greens = [
      Color(0xffa6ca37),
      Color(0xff94c33d),
      Color(0xff83bd42),
      Color(0xff70b543),
      Color(0xff5bad42)
    ];
    if (paintZoom <= 1) {
      for (var i = 0; i < 5; i++) {
        canvas.drawRect(
            Rect.fromLTWH(
                0, size.height * i / 5, size.width, size.height / 5 + 1),
            Paint()..color = greens[i]);
      }
    }
    final left = size.width * .075,
        top = size.height * .07,
        width = size.width * .85,
        height = size.height * .86;
    // 参考図のコート矩形(24,24)-(576,366)を90度回して縦画面へ写像。
    Offset portrait(double x, double y) =>
        Offset(left + (366 - y) / 342 * width, top + (x - 24) / 552 * height);
    final solid = Paint()
      ..color = const Color(0xfff6f8de)
      ..strokeWidth = (paintZoom > 1 ? 3.5 : 1.8) / paintZoom
      ..strokeCap = StrokeCap.butt;
    final dashed = Paint()
      ..color = const Color(0xfff6f8de)
      ..strokeWidth = (paintZoom > 1 ? 3 : 1.2) / paintZoom
      ..strokeCap = StrokeCap.butt;
    void line(double x1, double y1, double x2, double y2, Paint paint) =>
        canvas.drawLine(portrait(x1, y1), portrait(x2, y2), paint);
    // 外周、トライライン、22mライン、ハーフウェーライン。
    line(24, 24, 576, 24, solid);
    line(576, 24, 576, 366, solid);
    line(576, 366, 24, 366, solid);
    line(24, 366, 24, 24, solid);
    for (final x in [102.0, 190.0, 300.0, 410.0, 496.0]) {
      line(x, 24, x, 366, solid);
    }
    // 中央から左右10mの破線。
    final dashY = paintZoom > 1 ? 342 / 70 * 5 : 6.2;
    final periodY = paintZoom > 1 ? dashY * 2 : 12.2;
    final dashX = paintZoom > 1 ? 394 / 100 * 5 : 6.2;
    final periodX = paintZoom > 1 ? dashX * 2 : 12.2;
    for (final x in [260.0, 340.0]) {
      for (var y = 30.0; y < 360; y += periodY) {
        line(x, y, x, (y + dashY).clamp(30, 360), dashed);
      }
    }
    // タッチラインから5m/15mの4本。インゴール内へ延長しない。
    for (final y in [48.0, 97.0, 293.0, 342.0]) {
      for (var x = 138.0; x < 462; x += periodX) {
        line(x, y, (x + dashX).clamp(138, 462), y, dashed);
      }
    }
    // 両トライラインから5mの短いマークを、参考図と同じ6位置へ置く。
    for (final x in [123.0, 476.0]) {
      for (final y in [48.0, 96.0, 160.0, 229.0, 293.0, 341.0]) {
        line(x, y - 9, x, y + 9, solid);
      }
    }
    // 15m線端の短い取り合いとセンターマーク。
    for (final y in [97.0, 293.0]) {
      line(102, y, 123, y, solid);
      line(476, y, 496, y, solid);
    }
    if (paintZoom > 1) {
      line(299, 195, 301, 195, solid);
    } else {
      line(292, 195, 307, 195, solid);
    }
    // インゴール内の俯瞰ゴール記号。参考の配置関係を同じ写像で回転。
    final goal = Paint()
      ..color = const Color(0xfff6f8de)
      ..strokeWidth = 3 / paintZoom
      ..strokeCap = StrokeCap.round;
    for (final x in [70.0, 530.0]) {
      line(x - 25, 172, x + 25, 172, goal);
      line(x - 25, 219, x + 25, 219, goal);
      line(x, 172, x, 219, goal);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TacklePitchPainter old) =>
      old.zoom != zoom ||
      old.quarterTurns != quarterTurns ||
      old.longitudinalOffsetMeters != longitudinalOffsetMeters;
}
