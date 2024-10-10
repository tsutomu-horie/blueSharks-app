import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/team.controller.dart';

class TeamScreen extends GetView<TeamController> {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor.primary,
        body: SingleChildScrollView(
      child: Column(
        children: [
          DefaultHeaderTitleView(
              LocaleKeys.team.tr, LocaleKeys.team_en.tr.toUpperCase()),
          SizedBox(
            height: 16.h,
          ),
          SvgPicture.asset(
            "assets/vectors/app_logo.svg",
            width: 38.w,
            height: 38.w,
          ),
          SizedBox(
            height: 11.h,
          ),
          SvgPicture.asset(
            "assets/vectors/app_logo_label.svg",
            width: 100.w,
            height: 17.w,
          ),
          SizedBox(
            height: 11.h,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 16.w,
              ),
              Image.asset(
                "assets/images/jrugby_logo.png",
                width: 48.w,
                height: 48.w,
              ),
              SizedBox(
                width: 16.w,
              ),
              const Flexible(
                  child: CustomTextView(
                Constants.leagueTitle,
                type: TDSFontType.headlineSmall,
              ))
            ],
          ),
          SizedBox(
            height: 16.h,
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.h),
                color: DangerColor.main,
                child: CustomTextView(
                  Constants.division.toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TextColor.inverse,
                      fontSize: 14.sp),
                ),
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  color: BackgroundColor.secondary,
                  height: 52.h,
                  child: Center(
                    child: Row(
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      children: [
                        CustomTextView(
                          LocaleKeys.rank.tr,
                          type: TDSFontType.bodyTextMedium,
                          color: TextColor.secondary,
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        CustomTextView(
                          Constants.rank,
                          type: TDSFontType.headlineMedium,
                          color: BrandColor.main,
                        ),
                        SizedBox(
                          width: 4.w,
                        ),
                        CustomTextView(
                          "/",
                          type: TDSFontType.bodyTextMedium,
                          color: BrandColor.main,
                        ),
                        SizedBox(
                          width: 4.w,
                        ),
                        CustomTextView(
                          Constants.totalRank,
                          type: TDSFontType.bodyTextMedium,
                          color: BrandColor.pressed,
                        ),
                        SizedBox(
                          width: 16.w,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28.h,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                CustomTextView(
                  LocaleKeys.about_us.tr,
                  type: TDSFontType.titleSmall,
                ),
                SizedBox(
                  height: 12.h,
                ),
                const CustomTextView(
                  Constants.teamHistory,
                  type: TDSFontType.bodyTextMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32.h,
          ),
          DefaultHeaderTitleView(
              LocaleKeys.host_stadium.tr, LocaleKeys.host_stadium_en.tr),
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      "assets/images/image_stadium.png",
                      fit: BoxFit.cover,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomTextView(
                            Constants.stadiumName,
                            type: TDSFontType.headlineSmall,
                            color: TextColor.inverse,
                          ),
                          SizedBox(
                            height: 8.h,
                          ),
                          CustomTextView(
                            Constants.stadiumAddress,
                            type: TDSFontType.bodyTextLarge,
                            color: TextColor.inverse,
                          ),
                          SizedBox(
                            height: 33.h,
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: CustomTextView(
                              LocaleKeys.see_detail.tr,
                              type: TDSFontType.labelLarge,
                              color: BrandColor.main,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          )
        ],
      ),
    ));
  }
}
