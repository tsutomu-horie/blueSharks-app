import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_app_bar_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/forgot_password_home.controller.dart';

class ForgotPasswordHomeScreen extends GetView<ForgotPasswordHomeController> {
  const ForgotPasswordHomeScreen(this.selectedPlayer, this.selectedPlayerName,
      {super.key});

  final String selectedPlayer;
  final String selectedPlayerName;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();

    final ForgotPasswordHomeController controller = Get.put(
        ForgotPasswordHomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: BrandColor.main,
        title: CustomTextView(LocaleKeys.forgot_password_header_home.tr, color: Colors.white, type: TDSFontType.titleMedium,),
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h,),
              CustomTextView(LocaleKeys.email_field_desc.tr,
                type: TDSFontType.bodyTextMedium, color: TextColor.secondary,),
              SizedBox(
                height: 24.h,
              ),
              Row(
                children: [
                  CustomTextView(
                    LocaleKeys.email.tr,
                    type: TDSFontType.labelLarge,
                    color: TextColor.secondary,
                  ),
                  CustomTextView(
                    " *",
                    type: TDSFontType.labelLarge,
                    color: TextColor.error,
                  ),
                ],
              ),
              SizedBox(
                height: 4.h,
              ),
              Form(
                key: globalKey,
                child: TextFormField(
                  validator: (value) {
                    if (value!.isEmpty ||
                        !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                            .hasMatch(value)) {
                      return LocaleKeys.error_email_invalid.tr;
                    }
                    return null;
                  },
                  controller: controller.emailTextFieldController,
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Obx(() {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColor.main,
            ),
            onPressed: () {
              if (globalKey.currentState!.validate()) {
                controller.sendOtp(context, selectedPlayer, selectedPlayerName);
              }
            },
            child: controller.isLoadingLogin.value
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white, // Spinner color
              ),
            )
                : CustomTextView(
              LocaleKeys.forgot_password_btn_home.tr,
              color: BrandColor.content,
            ),
          );
        }),
      ),
    );
  }
}
