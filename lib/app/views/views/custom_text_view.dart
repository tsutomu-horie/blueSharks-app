import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

class CustomTextView extends GetView {
  const CustomTextView(this.text, {super.key, this.type, this.style, this.color, this.maxLine, this.align,});

  final String text;
  final TDSFontType? type;
  final TextStyle? style;
  final Color? color;
  final int? maxLine;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    TextStyle getDefaultTextStyle() => switch (type) {
      TDSFontType.headlineSmall => TDSTypography.headlineSmall,
      TDSFontType.headlineMedium => TDSTypography.headlineMedium,
      TDSFontType.headlineLarge => TDSTypography.headlineLarge,
      TDSFontType.titleSmall => TDSTypography.titleSmall,
      TDSFontType.titleMedium => TDSTypography.titleMedium,
      TDSFontType.titleLarge => TDSTypography.titleLarge,
      TDSFontType.subtitleLarge => TDSTypography.subtitleLarge,
      TDSFontType.labelSmall => TDSTypography.labelSmall,
      TDSFontType.labelMedium => TDSTypography.labelMedium,
      TDSFontType.labelLarge => TDSTypography.labelLarge,
      TDSFontType.bodyTextTiny => TDSTypography.bodyTextTiny,
      TDSFontType.bodyTextSmall => TDSTypography.bodyTextSmall,
      TDSFontType.bodyTextMedium => TDSTypography.bodyTextMedium,
      TDSFontType.bodyTextLarge => TDSTypography.bodyTextLarge,
      null => TDSTypography.bodyTextMedium,
    };

    return style == null
        ? Text(text,
        style: getDefaultTextStyle().copyWith(color: color),
        maxLines: maxLine,
        textAlign: align,
        overflow: maxLine != null ? TextOverflow.ellipsis : null)
        : Text(text,
        style: style,
        maxLines: maxLine,
        textAlign: align,
        overflow: maxLine != null ? TextOverflow.ellipsis : null);
  }
}

enum TDSFontType {
  headlineSmall,
  headlineMedium,
  headlineLarge,
  titleSmall,
  titleMedium,
  titleLarge,
  subtitleLarge,
  labelSmall,
  labelMedium,
  labelLarge,
  bodyTextTiny,
  bodyTextSmall,
  bodyTextMedium,
  bodyTextLarge,
}

class TDSTypography {
  static const Map<TDSFontType, FontWeight> _fontWeight = {
    TDSFontType.headlineSmall: FontWeight.w500,
    TDSFontType.headlineLarge: FontWeight.w500,
    TDSFontType.headlineMedium: FontWeight.w500,
    TDSFontType.titleLarge: FontWeight.w500,
    TDSFontType.titleSmall: FontWeight.w500,
    TDSFontType.titleMedium: FontWeight.w500,
    TDSFontType.labelLarge: FontWeight.w500,
    TDSFontType.subtitleLarge: FontWeight.w700,
    TDSFontType.labelSmall: FontWeight.w500,
    TDSFontType.labelMedium: FontWeight.w500,
    TDSFontType.bodyTextLarge: FontWeight.w400,
    TDSFontType.bodyTextSmall: FontWeight.w400,
    TDSFontType.bodyTextMedium: FontWeight.w400,
    TDSFontType.bodyTextTiny: FontWeight.w400,
  };

  static final Map<TDSFontType, double> fontSize = {
    TDSFontType.headlineLarge: 32.0.sp,
    TDSFontType.headlineMedium: 28.0.sp,
    TDSFontType.headlineSmall: 24.0.sp,
    TDSFontType.titleLarge: 20.0.sp,
    TDSFontType.subtitleLarge: 24.0.sp,
    TDSFontType.titleMedium: 18.0.sp,
    TDSFontType.titleSmall: 16.0.sp,
    TDSFontType.labelLarge: 14.0.sp,
    TDSFontType.labelMedium: 12.0.sp,
    TDSFontType.labelSmall: 10.0.sp,
    TDSFontType.bodyTextLarge: 16.0.sp,
    TDSFontType.bodyTextMedium: 14.0.sp,
    TDSFontType.bodyTextSmall: 12.0.sp,
    TDSFontType.bodyTextTiny: 10.0.sp,
  };

  static final Map<TDSFontType, double> _lineHeight = {
    TDSFontType.headlineLarge: 40.0.h,
    TDSFontType.headlineMedium: 36.0.h,
    TDSFontType.headlineSmall: 32.0.h,
    TDSFontType.subtitleLarge: 32.0.h,
    TDSFontType.titleLarge: 26.0.h,
    TDSFontType.titleMedium: 24.0.h,
    TDSFontType.titleSmall: 24.0.h,
    TDSFontType.labelLarge: 20.0.h + 0.1.h,
    TDSFontType.labelMedium: 16.0.h + 0.1.h,
    TDSFontType.labelSmall: 14.0.h + 0.1.h,
    TDSFontType.bodyTextLarge: 24.0.h,
    TDSFontType.bodyTextMedium: 20.0.h,
    TDSFontType.bodyTextSmall: 16.0.h,
    TDSFontType.bodyTextTiny: 14.0.h,
  };

  static TextStyle _getTextStyle(TDSFontType type) {
    return TextStyle(
      fontWeight: _fontWeight[type]!,
      fontSize: fontSize[type]!,
      height: _lineHeight[type]! / fontSize[type]!,
    );
  }

  static TextStyle get headlineLarge => _getTextStyle(TDSFontType.headlineLarge);
  static TextStyle get headlineMedium => _getTextStyle(TDSFontType.headlineMedium);
  static TextStyle get headlineSmall => _getTextStyle(TDSFontType.headlineSmall);
  static TextStyle get titleLarge => _getTextStyle(TDSFontType.titleLarge);
  static TextStyle get subtitleLarge => _getTextStyle(TDSFontType.subtitleLarge);
  static TextStyle get titleMedium => _getTextStyle(TDSFontType.titleMedium);
  static TextStyle get titleSmall => _getTextStyle(TDSFontType.titleSmall);
  static TextStyle get labelLarge => _getTextStyle(TDSFontType.labelLarge);
  static TextStyle get labelMedium => _getTextStyle(TDSFontType.labelMedium);
  static TextStyle get labelSmall => _getTextStyle(TDSFontType.labelSmall);
  static TextStyle get bodyTextLarge => _getTextStyle(TDSFontType.bodyTextLarge);
  static TextStyle get bodyTextMedium => _getTextStyle(TDSFontType.bodyTextMedium);
  static TextStyle get bodyTextSmall => _getTextStyle(TDSFontType.bodyTextSmall);
  static TextStyle get bodyTextTiny => _getTextStyle(TDSFontType.bodyTextTiny);
}
