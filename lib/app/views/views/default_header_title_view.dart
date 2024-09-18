import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import '../../../utils/app_color.dart';
import 'custom_text_view.dart';

class DefaultHeaderTitleView extends GetView {
  const DefaultHeaderTitleView(this.title, this.description, {super.key});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24.h,),
        Row(
          children: [
            SizedBox(width: 16.w,),
            Flexible(child: Center(child: CustomTextView(title, color: TextColor.tertiary, type: TDSFontType.bodyTextMedium, align: TextAlign.center,))),
            SizedBox(width: 16.w,),
          ],
        ),
        SizedBox(height: 4.h,),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16.w,),
            Container(height: 1, width: 15.w, color: BrandColor.main,),
            SizedBox(width: 16.w,),
            //todo:: custom font
            Flexible(child: Text(description, style: TextStyle(fontSize: 20.sp, color: BrandColor.main, fontWeight: FontWeight.w600),),),
            SizedBox(width: 16.w,),
            Container(height: 1, width: 15.w, color: BrandColor.main,),
            SizedBox(width: 16.w,),
          ],
        ),
        SizedBox(height: 24.h,),
      ],
    );
  }
}
