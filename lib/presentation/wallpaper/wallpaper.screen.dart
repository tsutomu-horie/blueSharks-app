import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/wallpaper.controller.dart';

class WallpaperScreen extends GetView<WallpaperController> {
  const WallpaperScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          width: 56.w,
          height: 56.h,
          'assets/vectors/app_logo.svg', // Replace with your SVG file path
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () {  },
          // child: CustomTextView(LocaleKeys.Ok.tr, color: BrandColor.content,),
          child: CustomTextView(LocaleKeys.ok.tr, color: BrandColor.content,),

        ),

      ),
      body: Container(
        color: BorderColor.primary,
        child: Column(
          children: [
            SizedBox(height: 24.h,),
            CustomTextView(LocaleKeys.wallpaper_information.tr, color: TextColor.tertiary, type: TDSFontType.bodyTextMedium,)
          ],
        ),
      ),
    );
  }
}
