import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/member.controller.dart';

class MemberScreen extends GetView<MemberController> {
  const MemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MemberController memberController = Get.put(MemberController());

    return Scaffold(
        body: Column(
      children: [
        Container(
          color: const Color(0xfffafafa),
          child: DefaultHeaderTitleView(
            LocaleKeys.member.tr,
            LocaleKeys.member_en.tr.toUpperCase(),
          ),
        ),
        Container(height: 1.h, color: BorderColor.primary, ),
        Container(
          color: BackgroundColor.primary,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: OutlinedButton(
            onPressed: () {
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 12.w,),
                SvgPicture.asset(
                  "assets/vectors/calendar-search.svg",
                  width: 20.w,
                  height: 20.h,
                ),
                SizedBox(
                  width: 8.w,
                ),
                Flexible(
                  child: SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      return CustomTextView(
                        memberController.selectedPosition.value,
                        type: TDSFontType.bodyTextMedium,
                        color: TextColor.primary,
                      );
                    }),
                  ),
                ),
                SizedBox(
                  width: 8.w,
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.w,
                ),
                SizedBox(width: 12.w,),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.red,
          width: double.infinity,
          height: 20,
        )
      ],
    ));
  }
}
