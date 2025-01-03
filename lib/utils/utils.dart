import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/error_dialog_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:lottie/lottie.dart';

class Utils {
  static void showError(BuildContext context, String title, String? message) {
    errorDialogView(context, title, message);
    print("error with ${title} , ${message}");
  }

  static void logScreenView(String screenName, FirebaseAnalytics analytics) {

    analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
      },
    );
  }

  static void showCustomSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Lottie.asset(
            'assets/lottie/success_animation.json',
            // Path to your Lottie animation
            width: 180.w,
            height: 180.h,
            fit: BoxFit.fill,
          ),
          content: CustomTextView(message, type: TDSFontType.bodyTextLarge, align: TextAlign.center,),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.main,
                ),
                onPressed: () {
                  Get.back();
                },
                child: CustomTextView(
                  LocaleKeys.close.tr,
                  color: BrandColor.content,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showCustomSuccessRegisterDialog(BuildContext context, Function onTapsuccess) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 238.h,
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/success_animation.json',
                  // Path to your Lottie animation
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 8.h,),
                CustomTextView(LocaleKeys.register_finish_title.tr, type: TDSFontType.titleMedium, align: TextAlign.center,),
                SizedBox(height: 8.h,),
                CustomTextView(LocaleKeys.register_finish_desc.tr, type: TDSFontType.bodyTextMedium, align: TextAlign.center,),
              ],
            ),
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.main,
                ),
                onPressed: () {
                  onTapsuccess();
                },
                child: CustomTextView(
                  LocaleKeys.next.tr,
                  color: BrandColor.content,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void handleErrorOtp(String error, BuildContext context) {
    if (error == "{user_exist: [メールアドレス]}") {
      Utils.showError(context, "", LocaleKeys.error_email_duplicate.tr);
    } else {
      Utils.showError(context, LocaleKeys.error_login_message.tr, null );
    }
  }

}