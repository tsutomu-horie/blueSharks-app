import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';

import '../../../utils/app_color.dart';
import 'custom_text_view.dart';

class DefaultHeaderTitleView extends GetView {
  const DefaultHeaderTitleView(this.title, this.description,
      {super.key, this.onBack,});

  final String title;
  final String description;
  final Function? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          SizedBox(
            height: 24.h,
          ),
          Row(
            children: [
              SizedBox(
                width: 16.w,
              ),
              Flexible(
                  child: Center(
                      child: CustomTextView(
                title,
                color: TextColor.tertiary,
                type: TDSFontType.bodyTextMedium,
                align: TextAlign.center,
              ))),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          SizedBox(
            height: 4.h,
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16.w,
              ),
              Container(
                height: 1,
                width: 15.w,
                color: BrandColor.main,
              ),
              SizedBox(
                width: 16.w,
              ),
              //todo:: custom font
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                      fontSize: 20.sp,
                      color: BrandColor.main,
                      fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 16.w,
              ),
              Container(
                height: 1,
                width: 15.w,
                color: BrandColor.main,
              ),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          if (onBack != null)
            Column(
              children: [
                SizedBox(
                  height: 12.h,
                ),
                TextButton(
                  onPressed: () {
                    onBack!();
                  },
                  child: CustomTextView(
                    LocaleKeys.back_to_list.tr,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: BrandColor.main, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          SizedBox(
            height: 24.h,
          ),
          Divider(color: BorderColor.primary,  height: 0,),
        ],
      ),
    );
  }
}
