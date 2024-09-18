import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/html_text_view.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class MatchItemView extends GetView {
  const MatchItemView({super.key, required this.title, required this.location, required this.date, required this.day, required this.time, required this.isHome, required this.opponentLogo, required this.opponentName});

  final bool isHome;
  final String title;
  final String location;
  final String date;
  final String day;
  final String time;
  final String opponentLogo;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    print("get lodo ${opponentLogo}");
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.r),
            border: Border.all(color: BorderColor.primary)),
        width: 320.w,
        height: 200.h,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                    decoration: BoxDecoration(
                      color: DangerColor.main,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2.r),
                      ),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                    child: CustomTextView(
                      "Home",
                      color: TextColor.inverse,
                    )),
                Flexible(
                    child: Container(
                        decoration: BoxDecoration(
                          color: PrimaryColor.hover,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(2.r),
                          ),
                        ),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              "assets/vectors/ic_stadium.svg",
                              width: 20.w,
                              height: 20.w,
                            ),
                            SizedBox(
                              width: 10.w,
                            ),
                            CustomTextView(formatLocation(location),
                                color: TextColor.inverse),
                          ],
                        )))
              ],
            ),
            Padding(padding: EdgeInsets.all(16.w), child: Column(
              children: [
                CustomTextView(title, type: TDSFontType.bodyTextLarge, color: TextColor.primary, maxLine: 1,),
                SizedBox(height: 4.h,),
                Container(
                  height: 28.h,
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //todo:: change font same as design
                      CustomTextView(date, style: TextStyle(fontWeight: FontWeight.w600, color: PrimaryColor.pressed, fontSize: 16.sp),),
                      SizedBox(width: 6.w,),
                      CustomTextView(day, style: TextStyle(fontWeight: FontWeight.w500, color: TextColor.secondary, fontSize: 12.sp),),
                      SizedBox(width: 4.w,),
                      CustomTextView(time, style: TextStyle(fontWeight: FontWeight.w600, color: PrimaryColor.pressed, fontSize: 16.sp),)
                    ],
                  ),
                ),
                SizedBox(height: 12.h,),
                Row(
                  children: [
                    CustomTextView("VS", style: TextStyle(fontWeight: FontWeight.w600, color: PrimaryColor.pressed, fontSize: 28.sp, fontStyle: FontStyle.italic,),),
                    SizedBox(width: 8.w,),
                    SizedBox(width: 62.w, height: 62.w, child: CustomImageView(image: opponentLogo)),
                    SizedBox(width: 7.w,),
                    Flexible(child: HtmlTextView(opponentName, style: Style(fontSize: FontSize(16.sp), color: PrimaryColor.pressed, fontWeight: FontWeight.w700)))
                  ],
                )
              ],
            ),)
          ],
        ),
      ),
    );
  }

  String formatLocation(String title) {
    print(title);
    final formattedTitle = title.replaceAll("／", "・");
    return formattedTitle;
  }

}
