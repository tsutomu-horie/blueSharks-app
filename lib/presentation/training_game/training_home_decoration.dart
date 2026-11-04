import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'training_ocean_decoration.dart';

const _navy = Color(0xff06374f);
const _cyan = Color(0xff57d5e0);

/// 育成ホーム専用の斜めカットと深海の光を表現する枠。
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
          ..lineTo(rect.right, rect.top + cut)
          ..lineTo(rect.right, rect.bottom - cut)
          ..lineTo(rect.right - cut, rect.bottom)
          ..lineTo(rect.left + cut, rect.bottom)
          ..lineTo(rect.left, rect.bottom - cut)
          ..lineTo(rect.left, rect.top + cut)
          ..close());
    canvas.drawShadow(path, _navy.withValues(alpha: .5), 3, false);
    canvas.save();
    canvas.clipPath(path);
    paintTrainingOceanSurface(canvas, rect, dark: false);
    if (header) {
      canvas.drawPath(
          Path()
            ..moveTo(12, 2)
            ..lineTo(size.width * .29, 2)
            ..lineTo(size.width * .25, 9)
            ..lineTo(8, 9)
            ..close(),
          Paint()..color = _navy);
    }
    canvas.restore();
    canvas.drawPath(
        path,
        Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    if (!hexagon) {
      canvas.drawLine(
          Offset(cut + 2, 2),
          Offset(size.width - cut - 2, 2),
          Paint()
            ..color = _cyan
            ..strokeWidth = 1.5);
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
    paintTrainingOceanSurface(canvas, rect, dark: true);
    if (footer) {
      canvas.drawLine(
          const Offset(0, 2),
          Offset(size.width, 2),
          Paint()
            ..color = _cyan.withValues(alpha: .7)
            ..strokeWidth = 1.5);
      canvas.drawLine(
          const Offset(0, 5),
          Offset(size.width, 5),
          Paint()
            ..color = Colors.white.withValues(alpha: .08)
            ..strokeWidth = .7);
    }
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
