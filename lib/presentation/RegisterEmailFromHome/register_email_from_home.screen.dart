import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/register/register_otp/register_otp.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/register_email_from_home.controller.dart';

class RegisterEmailFromHomeScreen
    extends GetView<RegisterEmailFromHomeController> {
  const RegisterEmailFromHomeScreen(this.selectedPlayer, {super.key});
  final String selectedPlayer;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final RegisterEmailFromHomeController registerEmailController =
    Get.put(RegisterEmailFromHomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor:  BrandColor.main,
        title: CustomTextView(LocaleKeys.forgot_password_title.tr, color: Colors.white, type: TDSFontType.titleMedium,),
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
              CustomTextView(LocaleKeys.email_field_desc.tr, type: TDSFontType.bodyTextMedium, color: TextColor.secondary,),
              SizedBox(height: 24.h,),
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty ||
                      !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                          .hasMatch(value)) {
                    return 'Invalid email';
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
                      registerEmailController.sendOtp((id){
                        Get.to(RegisterOtpScreen(email: controller.textFieldController.text, otpId: "$id", fromScreen: "home", selectedPlayer: selectedPlayer));
                      });

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
}
