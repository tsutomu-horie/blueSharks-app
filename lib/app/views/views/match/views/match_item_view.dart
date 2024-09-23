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
  const MatchItemView(
      {super.key,
      required this.title,
      required this.location,
      required this.date,
      required this.day,
      required this.time,
      required this.isHome,
      required this.opponentLogo,
      required this.opponentName});

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
    print("isHome $isHome");

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: BorderColor.primary)),
        width: 300.w,
        height: 202.h,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 16.h,),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4.w, horizontal: 8.h),
                  color: DangerColor.main,
                  child: CustomTextView(isHome ? "HOME" : "VISITOR", style: TextStyle(fontSize: 10.sp, color: BrandColor.content),),
                ),
                SizedBox(width: 8.w,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomTextView(date, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700),),
                    SizedBox(width: 4.w,),
                    CustomTextView(day, type: TDSFontType.labelLarge,),
                  ],
                )


              ],
            ),
            SizedBox(height: 4.h,),
            CustomTextView(time, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),),
            SizedBox(height: 4.h,),
            Row(
              children: [
                SizedBox(width: 16.w,),
                CustomTextView("VS", style: TextStyle(fontWeight: FontWeight.w600, color: PrimaryColor.pressed, fontSize: 28.sp, fontStyle: FontStyle.italic,),),
                SizedBox(width: 8.w,),
                SizedBox(width: 62.w, height: 62.w, child: CustomImageView(image: opponentLogo)),
                SizedBox(width: 7.w,),
                Flexible(child: HtmlTextView(opponentName, style: Style(fontSize: FontSize(16.sp), color: PrimaryColor.pressed, fontWeight: FontWeight.w700, maxLines: 2, textOverflow: TextOverflow.ellipsis,),),),
                SizedBox(width: 16.w,),
              ],
            ),
            SizedBox(height: 16.h,),
            Container(
              decoration: BoxDecoration(
                color: BrandColor.main,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12.r), bottomRight: Radius.circular(12.r),),
              ),
              padding: EdgeInsets.symmetric(vertical: 10.h),
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
              ),
            ),
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
