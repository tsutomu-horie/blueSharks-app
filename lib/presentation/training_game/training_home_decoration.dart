import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _navy = Color(0xff002b6d);
const _cyan = Color(0xff39bdf5);

/// 育成ホーム専用の斜めカットと青い二重枠。
class TrainingHomeFrame extends StatelessWidget {
  const TrainingHomeFrame({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.header = false,
    this.hexagon = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool header;
  final bool hexagon;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _FramePainter(header: header, hexagon: hexagon),
        child: Padding(padding: padding, child: child),
      );
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.header, required this.hexagon});
  final bool header;
  final bool hexagon;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final cut = (size.shortestSide * .2).clamp(7.0, 14.0);
    final path = hexagon
        ? (Path()
          ..moveTo(size.width / 2, 2)
          ..lineTo(size.width - 2, size.height * .25)
          ..lineTo(size.width - 2, size.height * .75)
          ..lineTo(size.width / 2, size.height - 2)
          ..lineTo(2, size.height * .75)
          ..lineTo(2, size.height * .25)
          ..close())
        : (Path()
          ..moveTo(rect.left + cut, rect.top)
          ..lineTo(rect.right - cut, rect.top)
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + cut)
          ..lineTo(rect.right, rect.bottom - cut)
          ..lineTo(rect.right - cut, rect.bottom)
          ..lineTo(rect.left + cut, rect.bottom)
          ..quadraticBezierTo(
              rect.left, rect.bottom, rect.left, rect.bottom - cut)
          ..lineTo(rect.left, rect.top + cut)
          ..close());
    canvas.drawShadow(path, _navy.withValues(alpha: .7), 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white, Color(0xffedf1f5)],
          stops: [0, .65, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(path);
    if (header) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width - 12, 7)
          ..lineTo(86, 7)
          ..lineTo(76, 16)
          ..lineTo(0, 16)
          ..close(),
        Paint()..color = _navy,
      );
      canvas.drawLine(
          Offset(12, 5),
          Offset(size.width - 12, 5),
          Paint()
            ..color = _cyan
            ..strokeWidth = 2);
    } else {
      for (final offset in [0.0, 8.0]) {
        canvas.drawLine(
          Offset(size.width * .72 + offset, size.height),
          Offset(size.width * .9 + offset, 0),
          Paint()
            ..color = const Color(0xffdfe9fa)
            ..strokeWidth = 3,
        );
      }
    }
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..color = _cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    if (!hexagon) {
      canvas.drawPath(
        Path()
          ..moveTo(rect.right - cut, rect.top)
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + cut)
          ..lineTo(rect.right, rect.bottom - cut)
          ..lineTo(rect.right - cut, rect.bottom)
          ..lineTo(rect.left + cut, rect.bottom)
          ..quadraticBezierTo(
              rect.left, rect.bottom, rect.left, rect.bottom - cut)
          ..lineTo(rect.left, rect.top + cut)
          ..lineTo(rect.left + cut, rect.top),
        Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      header != oldDelegate.header || hexagon != oldDelegate.hexagon;
}

/// 画像素材に依存せず、画面幅に追従するチームカラーの装飾。
class TrainingHomeRibbon extends StatelessWidget {
  const TrainingHomeRibbon({super.key, this.footer = false, this.child});
  final bool footer;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _RibbonPainter(footer: footer),
        child: child,
      );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.footer});
  final bool footer;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = footer
        ? (Path()..addRect(rect))
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width * .63, 0)
          ..lineTo(size.width * .46, size.height * .7)
          ..lineTo(0, size.height)
          ..close());
    canvas.drawPath(
        base,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff003d89), Color(0xff001b49)],
          ).createShader(rect));
    if (footer) {
      canvas.drawLine(
          const Offset(0, 2),
          Offset(size.width, 2),
          Paint()
            ..color = _cyan
            ..strokeWidth = 3);
      for (final (points, color) in [
        (
          [
            const Offset(0, .92),
            const Offset(1, .7),
            const Offset(.83, .88),
            const Offset(.45, 1),
            const Offset(0, 1)
          ],
          const Color(0xff00479a)
        ),
        (
          [
            const Offset(.38, 1),
            const Offset(1, .82),
            const Offset(1, .91),
            const Offset(.72, 1)
          ],
          const Color(0xff009de4)
        ),
        (
          [const Offset(.76, 1), const Offset(1, .86), const Offset(1, 1)],
          _cyan
        ),
        (
          [const Offset(0, .05), const Offset(.23, .03), const Offset(0, .18)],
          const Color(0xff007ec8)
        ),
        (
          [const Offset(.89, .05), const Offset(1, .03), const Offset(1, .21)],
          const Color(0xff0056b7)
        ),
      ]) {
        final path = Path()
          ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
        for (final p in points.skip(1)) {
          path.lineTo(p.dx * size.width, p.dy * size.height);
        }
        canvas.drawPath(path..close(), Paint()..color = color);
      }
      return;
    }
    canvas.save();
    for (final (points, color) in [
      (
        [
          const Offset(0, 1),
          const Offset(.47, .7),
          const Offset(.64, 0),
          const Offset(.59, 0),
          const Offset(.46, .64),
          const Offset(0, .92)
        ],
        _cyan
      ),
      (
        [
          const Offset(0, .9),
          const Offset(.45, .65),
          const Offset(.56, 0),
          const Offset(.52, 0),
          const Offset(.43, .58),
          const Offset(0, .74)
        ],
        const Color(0xff0069c9)
      ),
      (
        [const Offset(.48, .65), const Offset(.72, 0), const Offset(.86, 0)],
        const Color(0xff148de1)
      ),
      (
        [const Offset(.53, .5), const Offset(.85, 0), const Offset(1, 0)],
        _cyan
      ),
      (
        [
          const Offset(0, .4),
          const Offset(.46, 0),
          const Offset(.33, 0),
          const Offset(0, .58)
        ],
        const Color(0xff00377e)
      ),
    ]) {
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path..close(), Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) =>
      footer != oldDelegate.footer;
}

class TrainingHomeBrand extends StatelessWidget {
  const TrainingHomeBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.sizeOf(context).width * .38).clamp(0.0, 144.0).toDouble();
    return Semantics(
      label: 'KOTO BLUE SHARKS',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: width * 33 / 205,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SvgPicture.asset(
              'assets/vectors/app_logo_label.svg',
              width: 205,
              height: 33,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
