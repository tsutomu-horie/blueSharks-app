import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/views/set_walpaper_list_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/mypage/mypage.screen.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/register_email.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/wallpaper_set_player.controller.dart';

class WallpaperSetPlayerScreen extends GetView<WallpaperSetPlayerController> {
  const WallpaperSetPlayerScreen(this.onSet, {super.key});

  final Function(String, String)? onSet;

  @override
  Widget build(BuildContext context) {
    final WallpaperSetPlayerController memberController =
    Get.put(WallpaperSetPlayerController());

    return Scaffold(
      backgroundColor: BackgroundColor.primary,
      appBar: AppBar(
        backgroundColor: BackgroundColor.primary,
        title: SvgPicture.asset(
          "assets/vectors/app_logo.svg",
          width: 46.w,
          height: 46.h,
        ),
        centerTitle: true,
        actions: [
          if (onSet == null)
            Row(
              children: [
                CustomTextView(
                  "${LocaleKeys.step.tr} : ",
                  type: TDSFontType.bodyTextMedium,
                  color: TextColor.secondary,
                ),
                SizedBox(
                  width: 6.w,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: BrandColor.surface,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: CustomTextView(
                    "1/3",
                    type: TDSFontType.labelLarge,
                    color: BrandColor.main,
                  ),
                ),
                SizedBox(
                  width: 16.w,
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 12.w,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 16.w,
                    ),
                    Flexible(
                        child: CustomTextView(
                          LocaleKeys.set_wallpaper_title.tr,
                          type: TDSFontType.headlineSmall,
                          color: BrandColor.main,
                        )),
                    SizedBox(
                      width: 16.w,
                    ),
                  ],
                ),
                SizedBox(
                  height: 8.w,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 16.w,
                    ),
                    Flexible(
                        child: CustomTextView(
                          LocaleKeys.set_wallpaper_desc3.tr,
                          type: TDSFontType.bodyTextMedium,
                          color: TextColor.secondary,
                        )),
                    SizedBox(
                      width: 16.w,
                    ),
                  ],
                ),
                SizedBox(
                  height: 30.w,
                ),
                Obx(() {
                  return !memberController.isLoading.value
                      ? SetWalpaperListView(
                    memberController,
                    isSetWallpaper: true,
                    onSet: onSet,
                  )
                      : Column(
                    children: [shimmer(), shimmer(), shimmer()],
                  );
                })

              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:  onSet == null ? Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        width: double.infinity,
        child: OutlinedButton(
          style: ButtonStyle(
            side: WidgetStateProperty.all(BorderSide(
                color: BrandColor.main) // Set your desired color here
            ),
          ),
          onPressed: () {
            Get.to(() => const RegisterEmailScreen("", ""));
            // Get.offAll(() => const MainScreen());
          },
          child: CustomTextView(
            LocaleKeys.jump_to.tr,
            color: BrandColor.main,
          ),
        ),
      )  : null,
    );
  }
}

