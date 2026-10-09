import 'package:flutter/material.dart';

/// Keeps the supplied PNG's aspect ratio and alpha inside the existing frame.
/// The surrounding button or tab owns the accessible label.
class SuppliedUiIcon extends StatelessWidget {
  const SuppliedUiIcon({
    required this.fileName,
    required this.width,
    required this.height,
    required this.color,
    super.key,
  });

  final String fileName;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ui_icons/$fileName',
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
    );
  }
}
