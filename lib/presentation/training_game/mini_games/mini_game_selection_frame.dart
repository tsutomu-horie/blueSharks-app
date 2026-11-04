import 'package:flutter/material.dart';

import '../training_ocean_decoration.dart';

enum MiniGameSelectionSurface { window, card, close }

/// 選択・案内ウィンドウの斜めカットと深海の装飾です。
class MiniGameSelectionFrame extends StatelessWidget {
  const MiniGameSelectionFrame({
    super.key,
    required this.child,
    this.surface = MiniGameSelectionSurface.card,
    this.padding = EdgeInsets.zero,
    this.clipContent = false,
    this.pattern = TrainingWindowPattern.standard,
  });

  final Widget child;
  final MiniGameSelectionSurface surface;
  final EdgeInsetsGeometry padding;
  final bool clipContent;
  final TrainingWindowPattern pattern;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SelectionFramePainter(surface, pattern),
        child: clipContent
            ? ClipPath(
                clipper: const _SelectionFrameClipper(),
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      );
}

Path _framePath(Size size, double inset) {
  final rect = (Offset.zero & size).deflate(inset);
  final cut = 12.0.clamp(0.0, rect.shortestSide / 2);
  return Path()
    ..moveTo(rect.left + cut, rect.top)
    ..lineTo(rect.right - cut, rect.top)
    ..lineTo(rect.right, rect.top + cut)
    ..lineTo(rect.right, rect.bottom - cut)
    ..lineTo(rect.right - cut, rect.bottom)
    ..lineTo(rect.left + cut, rect.bottom)
    ..lineTo(rect.left, rect.bottom - cut)
    ..lineTo(rect.left, rect.top + cut)
    ..close();
}

class _SelectionFrameClipper extends CustomClipper<Path> {
  const _SelectionFrameClipper();
  @override
  Path getClip(Size size) => _framePath(size, 3);
  @override
  bool shouldReclip(_SelectionFrameClipper oldClipper) => false;
}

class _SelectionFramePainter extends CustomPainter {
  const _SelectionFramePainter(this.surface, this.pattern);
  final MiniGameSelectionSurface surface;
  final TrainingWindowPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final path = _framePath(size, 2);
    final dark = surface == MiniGameSelectionSurface.window;
    canvas.drawShadow(
        path, const Color(0xff031a2e).withValues(alpha: .6), 4, false);
    canvas.save();
    canvas.clipPath(path);
    paintTrainingOceanSurface(canvas, rect, dark: dark, pattern: pattern);
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff06374f)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    if (surface != MiniGameSelectionSurface.close) {
      canvas.drawLine(
          Offset(14, 2),
          Offset(size.width - 14, 2),
          Paint()
            ..shader = const LinearGradient(
                    colors: [Color(0xff79e6eb), Color(0xff1594b4)])
                .createShader(rect)
            ..strokeWidth = 2);
      // 上辺にだけ入る短い反射。左下の縁は濃紺のまま。
      canvas.drawLine(
          Offset(18, 5),
          Offset(size.width * .31, 5),
          Paint()
            ..color = const Color(0xffbceef3).withValues(alpha: dark ? .4 : .6)
            ..strokeWidth = .7);
    }
  }

  @override
  bool shouldRepaint(_SelectionFramePainter oldDelegate) =>
      surface != oldDelegate.surface || pattern != oldDelegate.pattern;
}
