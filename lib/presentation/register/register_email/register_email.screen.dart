import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/home/home.screen.dart';
import 'package:koto_blue_sharks/presentation/login/login.screen.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/register/register_otp/register_otp.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:lottie/lottie.dart';

import 'controllers/register_email.controller.dart';

class RegisterEmailScreen extends GetView<RegisterEmailController> {
  const RegisterEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final RegisterEmailController registerEmailController =
        Get.put(RegisterEmailController());

    return Scaffold(
        appBar: AppBar(
          title: SvgPicture.asset(
            "assets/vectors/app_logo.svg",
            width: 56.w,
            height: 56.h,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: IconColor.primary,
            ),
            // Change this to your desired icon
            onPressed: () {
              Get.back();
            },
          ),
          actions: [
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
                    "2/3",
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
        bottomNavigationBar: Container(
          height: 162.h,
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
                        showEmailDialog(registerEmailController, context);
                      }
                    },
                    child: CustomTextView(
                      LocaleKeys.send.tr,
                      color: BrandColor.content,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 12.h,
              ),
              Flexible(
                child: Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(BorderSide(
                              color: BrandColor
                                  .main) // Set your desired color here
                          ),
                    ),
                    onPressed: () {
                      Get.offAll(() => const MainScreen());
                    },
                    child: CustomTextView(
                      LocaleKeys.jump_to.tr,
                      color: BrandColor.main,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Form(
                key: globalKey, // Add this to validate the form
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextView(
                      LocaleKeys.register_email_title.tr,
                      type: TDSFontType.headlineSmall,
                      color: BrandColor.main,
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    CustomTextView(
                      LocaleKeys.register_email_desc.tr,
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
                    Column(
                      children: [
                        TextFormField(
                          validator: (value) {
                            if (value!.isEmpty ||
                                !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                                    .hasMatch(value)) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                          controller: registerEmailController.textFieldController,
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
                    SizedBox(
                      height: 4.h,
                    ),
                    CustomTextView(
                      LocaleKeys.email_warning.tr,
                      type: TDSFontType.bodyTextMedium,
                      color: TextColor.secondary,
                    ),
                    SizedBox(
                      height: 24.h,
                    ),
                    const Divider(),
                    SizedBox(
                      height: 24.h,
                    ),
                    SizedBox(
                        width: double.infinity,
                        child: CustomTextView(
                          LocaleKeys.already_have_account.tr,
                          type: TDSFontType.bodyTextMedium,
                          color: TextColor.secondary,
                          align: TextAlign.center,
                        )),
                    SizedBox(
                      height: 4.h,
                    ),
                    SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Get.to(() => const LoginScreen());
                          },
                          child: CustomTextView(
                            LocaleKeys.login_now.tr,
                            color: BrandColor.main,
                            align: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                decoration: TextDecoration.underline),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  void showEmailDialog(
      RegisterEmailController registerEmailController, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Dismiss when tapped outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/mail_animation.json', // Path to your Lottie animation
                  width: 180.w,
                  height: 180.h,
                  fit: BoxFit.fill,
                ),
                CustomTextView(
                  LocaleKeys.email_sent_dialog_title.tr,
                  type: TDSFontType.titleMedium,
                  color: TextColor.primary,
                ),
                CustomTextView(
                  LocaleKeys.email_sent_dialog_message.tr,
                  type: TDSFontType.bodyTextMedium,
                  color: TextColor.primary,
                ),
                // SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColor.main,
                    ),
                    onPressed: () {
                      Get.back();
                      Get.to(() => RegisterOtpScreen(
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
