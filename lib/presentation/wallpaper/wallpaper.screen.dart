import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/home/home.screen.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/wallpaper.controller.dart';

class WallpaperScreen extends GetView<WallpaperController> {
  const WallpaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor.primary,
      appBar: AppBar(
        backgroundColor: BackgroundColor.primary,
        toolbarHeight: 92.h,
        title: Column(
          children: [
            SizedBox(
              height: 16.h,
            ),
            SvgPicture.asset(
              width: 56.w,
              height: 56.h,
              'assets/vectors/app_logo.svg', // Replace with your SVG file path
            ),
            SizedBox(
              height: 20.h,
            )
          ],
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () {
            controller.onNext();
          },
          child: CustomTextView(
            LocaleKeys.next.tr,
            color: BrandColor.content,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: RGBA.rgba(250, 250, 250, 1),
          child: Column(
            children: [
              CustomTextView(
                LocaleKeys.set_wallpaper_header.tr,
                color: BrandColor.main,
                type: TDSFontType.subtitleLarge,
              ),
              SizedBox(
                height: 24.h,
              ),
              CustomTextView(
                LocaleKeys.step_en.trParams({'step': '1'}).toUpperCase(),
                color: BrandColor.main,
                type: TDSFontType.titleSmall,
              ),
              SizedBox(
                height: 4.h,
              ),
              CustomTextView(
                LocaleKeys.set_wallpaper_title.tr,
                color: BrandColor.main,
                type: TDSFontType.subtitleLarge,
              ),
              SizedBox(
                height: 24.h,
              ),
              Stack(
                children: [
                  SizedBox(
                    height: 240.h,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16.w,
                        ),
                        Flexible(
                            child: Image.asset(
                          "assets/images/wellcome_image.png",
                          width: double.infinity,
                          height: 240.h,
                        )),
                        SizedBox(
                          width: 16.w,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16.w,
                        ),
                        Image.asset(
                          "assets/images/white_shadow.png",
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 16.w,
                  ),
                  Flexible(
                      child: CustomTextView(
                    LocaleKeys.set_wallpaper_desc.tr,
                    color: TextColor.secondary,
                    type: TDSFontType.bodyTextMedium,
                  )),
                  SizedBox(
                    width: 16.w,
                  ),
                ],
              ),
              SizedBox(
                height: 24.h,
              ),
              Container(
                color: BorderColor.primary,
                height: 1.h,
              ),
              SizedBox(
                height: 24.h,
              ),
              CustomTextView(
                LocaleKeys.step_en.trParams({'step': '2'}).toUpperCase(),
                color: BrandColor.main,
                type: TDSFontType.titleSmall,
              ),
              SizedBox(
                height: 4.h,
              ),
              CustomTextView(
                LocaleKeys.set_wallpaper_title2.tr,
                color: BrandColor.main,
                type: TDSFontType.subtitleLarge,
              ),
              SizedBox(
                height: 24.h,
              ),
              Stack(
                children: [
                  SizedBox(
                    height: 240.h,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16.w,
                        ),
                        Flexible(
                            child: Image.asset(
                          "assets/images/wellcome_image.png",
                          width: double.infinity,
                          height: 240.h,
                        )),
                        SizedBox(
                          width: 16.w,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16.w,
                        ),
                        Image.asset(
                          "assets/images/white_shadow.png",
                        ),
                        SizedBox(
                          width: 16.w,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16.h,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 16.w,
                  ),
                  Flexible(
                      child: CustomTextView(
                    LocaleKeys.set_wallpaper_desc2.tr,
                    color: TextColor.secondary,
                    type: TDSFontType.bodyTextMedium,
                  )),
                  SizedBox(
                    width: 16.w,
                  ),
                ],
              ),
              Container(
                color: BorderColor.primary,
                height: 1.h,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget descriptionSection(String title, String description) {
    return Column(
      children: [
        SizedBox(
          height: 16.h,
        ),
        Row(
          children: [
            SizedBox(
              width: 16.w,
            ),
            Flexible(
                child: CustomTextView(
              title,
              type: TDSFontType.titleMedium,
              color: TextColor.primary,
            )),
            SizedBox(
              width: 16.w,
            ),
          ],
        ),
        SizedBox(
          height: 8.h,
        ),
        Row(
          children: [
            SizedBox(
              width: 16.w,
            ),
            Flexible(
                child: CustomTextView(
              description,
              type: TDSFontType.bodyTextSmall,
              color: TextColor.primary,
            )),
            SizedBox(
              width: 16.w,
            ),
          ],
        ),
        SizedBox(
          height: 24.h,
        ),
      ],
    );
  }
}
