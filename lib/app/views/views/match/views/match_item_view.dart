import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

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
      required this.opponentName,
      this.gameResult,
      this.team1Score,
      this.team2Score, required this.onTap});

  final bool isHome;
  final String title;
  final String location;
  final String date;
  final String day;
  final String time;
  final String opponentLogo;
  final String opponentName;

  final String? gameResult;
  final String? team1Score;
  final String? team2Score;

  final Function onTap;


  @override
  Widget build(BuildContext context) {
    print("isHome $isHome");

    return GestureDetector(
      onTap: (){
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: BorderColor.primary)),
          width: 300.w,
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
                    color: isHome ? DangerColor.main : BrandColor.main,
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
              if (gameResult != null && gameResult != "試合前")
                Column(
                  children: [
                    SizedBox(height: 12.h,),
                    Row(
                      children: [
                        SizedBox(width: 16.w,),
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.r), color: BackgroundColor.secondary ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: 12.w,),
                                SvgPicture.asset("assets/vectors/ic_scoreboard.svg", width: 28.w, height: 28.h,),
                                Flexible(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                      CustomTextView(team1Score ?? "0", style: TextStyle(fontWeight: FontWeight.w700, color: BrandColor.main, fontSize: 32.sp),),
                                      SizedBox(width: 8.w,),
                                      CustomTextView("-", style: TextStyle(fontWeight: FontWeight.w700, color: TextColor.primary, fontSize: 32.sp),),
                                      SizedBox(width: 8.w,),
                                      CustomTextView(team2Score ?? "0", style: TextStyle(fontWeight: FontWeight.w700, color: TextColor.primary, fontSize: 32.sp),),
                                    ],),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
                                  color: gameResult! == "WIN" ? BrandColor.background : BackgroundColor.muted,
                                  child: CustomTextView(gameResult!, style: TextStyle(fontSize: 12.sp, color: TextColor.inverse, fontWeight: FontWeight.w500),),
                                ),
                                SizedBox(width: 12.w,),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w,),
                      ],
                    )
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
                    CustomTextView(formatLocation(location),color: TextColor.inverse),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatLocation(String title) {
    // Replace all occurrences of "／" with "・"
    final formattedTitle = title.replaceAll("／", "・");

    // Check if the title contains <br> and split if it does
    if (formattedTitle.contains("<br>")) {
      // Split the string at <br> and return the text before <br>
      return formattedTitle.split("<br>").first.trim();
    }

    // Return the formatted title if <br> is not found
    return formattedTitle;
  }
}
