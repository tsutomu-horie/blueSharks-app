import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';

import 'controllers/splash.controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController controller = Get.put(SplashController());

    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            width: double.infinity,
            height: double.infinity,
            'assets/vectors/bg_splash.svg', // Replace with your SVG file path
            fit: BoxFit.cover, // Adjust fit as needed
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/vectors/app_logo.svg'),
                  SizedBox(
                    height: 24.h,
                  ),
                  SvgPicture.asset('assets/vectors/app_logo_label.svg'),
                  SizedBox(
                    height: 130.h,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 16.w,
            child: SafeArea(
              child: Obx(() {
                return CustomTextView("V ${controller.version.value}", type: TDSFontType.titleSmall,);
              }),
            ),
          ),
          Positioned(
            right: 0,
            left: 0,
            bottom: -32.h,
            child: SvgPicture.asset(
              width: 210.w,
              height: 300.h,
              'assets/vectors/mascot.svg', // Replace with your SVG file path
              fit: BoxFit.contain, // Adjust fit as needed
            ),
          )
        ],
      ),
    );
  }
}
