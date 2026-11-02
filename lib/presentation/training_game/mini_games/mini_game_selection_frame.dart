import 'package:flutter/material.dart';

import '../training_home_controls.dart';

enum MiniGameSelectionSurface { window, card, close }

/// 選択ウィンドウ専用の斜めカットとグラデーションです。
class MiniGameSelectionFrame extends StatelessWidget {
  const MiniGameSelectionFrame({
    super.key,
    required this.child,
    this.surface = MiniGameSelectionSurface.card,
    this.padding = EdgeInsets.zero,
    this.clipContent = false,
  });

  final Widget child;
  final MiniGameSelectionSurface surface;
  final EdgeInsetsGeometry padding;
  final bool clipContent;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SelectionFramePainter(surface),
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
  const _SelectionFramePainter(this.surface);
  final MiniGameSelectionSurface surface;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final cut = 12.0.clamp(0.0, rect.shortestSide / 2);
    final path = _framePath(size, 2);
    final colors = switch (surface) {
      MiniGameSelectionSurface.window => const [
          Color(0xff001e51),
          Color(0xff003f86),
          Color(0xff006cba),
          Color(0xff159bd2),
        ],
      MiniGameSelectionSurface.card => const [
          Colors.white,
          Color(0xfff4fbff),
          Color(0xffe3f2fd),
        ],
      MiniGameSelectionSurface.close => const [
          Colors.white,
          Color(0xfff5f9fc),
        ],
    };
    canvas.drawShadow(
        path, TrainingHomeStyle.navy.withValues(alpha: .7), 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    if (surface == MiniGameSelectionSurface.window) {
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(
        Path()
          ..moveTo(0, size.height * .86)
          ..lineTo(size.width, size.height * .72)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
        Paint()..color = const Color(0xff00428b).withValues(alpha: .5),
      );
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .55, size.height)
          ..lineTo(size.width, size.height * .9)
          ..lineTo(size.width, size.height)
          ..close(),
        Paint()..color = const Color(0xff008acb),
      );
      canvas.restore();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = TrainingHomeStyle.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (surface != MiniGameSelectionSurface.close) {
      canvas.drawLine(
        Offset(rect.left + cut, rect.top),
        Offset(rect.right - cut, rect.top),
        Paint()
          ..color = const Color(0xff39bdf5)
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionFramePainter oldDelegate) =>
      surface != oldDelegate.surface;
}
