import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/edit_profile_bottom_sheet_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/controllers/register_email.controller.dart';
import 'package:koto_blue_sharks/presentation/register/register_otp/register_otp.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:lottie/lottie.dart';

import 'controllers/register_email_from_home.controller.dart';

class RegisterEmailFromHomeScreen
    extends GetView<RegisterEmailFromHomeController> {
  const RegisterEmailFromHomeScreen(this.selectedPlayer, this.selectedPlayerName, {super.key});

  final String selectedPlayer;
  final String selectedPlayerName;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final RegisterEmailFromHomeController registerEmailController =
        Get.put(RegisterEmailFromHomeController());

    return Scaffold(
      backgroundColor: BackgroundColor.primary,
      appBar: AppBar(
        backgroundColor: BrandColor.main,
        title: CustomTextView(
          LocaleKeys.register.tr,
          color: Colors.white,
          type: TDSFontType.titleMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          // Change this to your desired icon
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Form(
          key: globalKey,
          child: Column(
            children: [
              CustomTextView(
                LocaleKeys.register_from_home_desc.tr,
                type: TDSFontType.bodyTextMedium,
                color: TextColor.secondary,
              ),
              SizedBox(
                height: 24.h,
              ),
              Row(
                children: [
                  CustomTextView(
                    LocaleKeys.email.tr,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.secondary,
                  ),
                  CustomTextView(
                    "*",
                    type: TDSFontType.bodyTextMedium,
                    color: DangerColor.main,
                  ),
                ],
              ),
              SizedBox(
                height: 4.h,
              ),
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty ||
                      !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                          .hasMatch(value)) {
                    return LocaleKeys.error_email_invalid.tr;
                  }
                  return null;
                },
                controller: controller.textFieldController,
                decoration: InputDecoration(
                  errorMaxLines: 1,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    // Custom border radius
                    borderSide: BorderSide(
                      color: BorderColor
                          .secondary, // Border color when not focused
                    ),
                  ),
                  hintStyle: TextStyle(
                    color: TextColor.placeholder, // Custom hint color
                  ),
                  contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                  hintText: LocaleKeys.email_placeholder
                      .trParams({"example": "jack@email.com"}),
                ),
              ),
              SizedBox(height: 4.h,),
              CustomTextView(LocaleKeys.email_warning.tr, color: TextColor.tertiary,)
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 102.h,
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColor.main),
                  onPressed: () {
                    if (globalKey.currentState!.validate()) {
                      registerEmailController.sendOtp((id) {
                        showEmailDialog(
                            registerEmailController, context, "$id");
                      }, context);
                    }
                  },
                  child: CustomTextView(
                    LocaleKeys.send.tr,
                    color: BrandColor.content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showEmailDialog(RegisterEmailController registerEmailController,
      BuildContext context, String? otpId) {
    showDialog(
      context: context,
      barrierDismissible: false, // Dismiss when tapped outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: BackgroundColor.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/mail_animation.json',
                  // Path to your Lottie animation
                  width: 180.w,
                  height: 180.h,
                  fit: BoxFit.fill,
                ),
                CustomTextView(
                  LocaleKeys.email_sent_dialog_title.tr,
                  type: TDSFontType.titleMedium,
                  color: TextColor.primary,
                  align: TextAlign.center,
                ),
                CustomTextView(
                  LocaleKeys.email_sent_dialog_message.tr,
                  type: TDSFontType.bodyTextMedium,
                  color: TextColor.primary,
                  align: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColor.main,
                    ),
                    onPressed: () {
                      Get.back();
                      print("selectedPlayerLink ${selectedPlayer}");
                      Get.to(() => RegisterOtpScreen(
                        isRegister: true,
                        fromScreen: "register_home",
                        otpId: otpId,
                        selectedPlayer: selectedPlayer,
                        selectedPlayerName: selectedPlayerName,
                        email: registerEmailController
                            .textFieldController.text,
                      ));
                    },
                    child: CustomTextView(
                      LocaleKeys.close.tr,
                      color: BrandColor.content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
