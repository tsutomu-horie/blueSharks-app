import 'package:flutter/material.dart';

extension RGBA on Color {
  static Color rgba(int r, int g, int b, double opacity) {
    return Color.fromRGBO(r, g, b, opacity);
  }
}

abstract class PrimaryColor {
  static final main = RGBA.rgba(255, 198, 25, 1);
  static final surface = RGBA.rgba(255, 252, 235, 1);
  static final hover = RGBA.rgba(12, 69, 151, 1);
  static final pressed = RGBA.rgba(6, 44, 101, 1);
  static final border = RGBA.rgba(255, 235, 136, 1);
  static final focus = RGBA.rgba(255, 198, 25, 0.3);
  static final content = RGBA.rgba(10, 10, 10, 1);
}

abstract class SecondaryColor {
  static final main = RGBA.rgba(8, 83, 197, 1);
  static final surface = RGBA.rgba(237, 249, 255, 1);
  static final hover = RGBA.rgba(11, 60, 127, 1);
  static final pressed = RGBA.rgba(14, 45, 93, 1);
  static final border = RGBA.rgba(255, 235, 136, 1);
  static final focus = RGBA.rgba(14, 45, 93, 0.3);
  static final content = RGBA.rgba(255, 255, 255, 1);
}

abstract class BackgroundColor {
  static final primary = RGBA.rgba(255, 255, 255, 1);
  static final secondary = RGBA.rgba(245, 245, 245, 1);
  static final inverse = RGBA.rgba(10, 10, 10, 1);
  static final brand = RGBA.rgba(255, 198, 25, 1);
  static final muted = RGBA.rgba(224, 224, 224, 1);
  static final disabled = RGBA.rgba(224, 224, 224, 1);
  static final tertiary = RGBA.rgba(224, 224, 224, 1);
}

abstract class TextColor {
  static final primary = RGBA.rgba(10, 10, 10, 1);
  static final secondary = RGBA.rgba(64, 64, 64, 1);
  static final tertiary = RGBA.rgba(97, 97, 97, 1);
  static final placeholder = RGBA.rgba(97, 97, 97, 1);
  static final error = RGBA.rgba(203, 58, 49, 1);
  static final inverse = RGBA.rgba(255, 255, 255, 1);
  static final onPrimary = RGBA.rgba(255, 255, 255, 1);
  static final disabled = RGBA.rgba(194, 194, 194, 1);
  static final onDisabled = RGBA.rgba(255, 255, 255, 1);
  static final helper = RGBA.rgba(158, 158, 158, 1);
}

abstract class BorderColor {
  static final subtle = RGBA.rgba(245, 245, 245, 1);
  static final primary = RGBA.rgba(237, 237, 237, 1);
  static final secondary = RGBA.rgba(224, 224, 224, 1);
  static final disabled = RGBA.rgba(194, 194, 194, 1);
  static final brand = RGBA.rgba(255, 198, 25, 1);
  static final strong = RGBA.rgba(117, 117, 117, 1);
  static final error = RGBA.rgba(203, 58, 49, 1);
  static final inverse = RGBA.rgba(255, 255, 255, 1);
}

abstract class IconColor {
  static final primary = RGBA.rgba(10, 10, 10, 1);
  static final secondary = RGBA.rgba(117, 117, 117, 1);
  static final onDisabled = RGBA.rgba(255, 255, 255, 1);
  static final disabled = RGBA.rgba(194, 194, 194, 1);
  static final inverse = RGBA.rgba(255, 255, 255, 1);
  static final brand = RGBA.rgba(255, 198, 25, 1);
}

abstract class DangerColor {
  static final main = RGBA.rgba(203, 58, 49, 1);
  static final hover = RGBA.rgba(173, 48, 40, 1);
  static final pressed = RGBA.rgba(119, 42, 37, 1);
  static final surface = RGBA.rgba(253, 244, 243, 1);
  static final border = RGBA.rgba(252, 229, 228, 1);
  static final content = RGBA.rgba(255, 255, 255, 1);
  static final focus = RGBA.rgba(203, 58, 49, 0.3);
}

abstract class SuccessColor {
  static final main = RGBA.rgba(45, 110, 80, 1);
  static final hover = RGBA.rgba(36, 88, 65, 1);
  static final pressed = RGBA.rgba(31, 70, 53, 1);
  static final surface = RGBA.rgba(241, 248, 244, 1);
  static final border = RGBA.rgba(188, 222, 201, 1);
  static final content = RGBA.rgba(255, 255, 255, 1);
  static final focus = RGBA.rgba(45, 110, 80, 0.3);
}

abstract class InfoColor {
  static final main = RGBA.rgba(50, 103, 227, 1);
  static final hover = RGBA.rgba(37, 80, 208, 1);
  static final pressed = RGBA.rgba(35, 59, 133, 1);
  static final surface = RGBA.rgba(240, 246, 254, 1);
  static final border = RGBA.rgba(221, 234, 252, 1);
  static final content = RGBA.rgba(255, 255, 255, 1);
  static final focus = RGBA.rgba(50, 103, 227, 0.3);
}

abstract class WarningColor {
  static final main = RGBA.rgba(184, 96, 39, 1);
  static final hover = RGBA.rgba(153, 70, 36, 1);
  static final pressed = RGBA.rgba(104, 47, 31, 1);
  static final surface = RGBA.rgba(252, 247, 238, 1);
  static final border = RGBA.rgba(245, 233, 208, 1);
  static final content = RGBA.rgba(255, 255, 255, 1);
  static final focus = RGBA.rgba(184, 96, 39, 0.3);
}

abstract class OtherColor {
  static final homeHeader = RGBA.rgba(237, 249, 255, 1);
  static final backgroundTransparent = RGBA.rgba(10, 10, 10, 0.4);
}

abstract class BrandColor {
  static final main = RGBA.rgba(7, 36, 96, 1);
  static final hover = RGBA.rgba(12, 69, 151, 1);
  static final pressed = RGBA.rgba(6, 44, 101, 1);
  static final surface = RGBA.rgba(235, 248, 255, 1);
  static final border = RGBA.rgba(209, 241, 255, 1);
  static final content = RGBA.rgba(255, 255, 255, 1);
}

