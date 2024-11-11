import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/forgotPassword/forgot_password.screen.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/login.controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen(this.selectedPlayer, this.isFromHome, this.selectedPlayerName, {super.key});

  final String selectedPlayer;
  final String selectedPlayerName;
  final bool isFromHome;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final LoginController loginController = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: isFromHome ? BrandColor.main : Colors.white,
        title: isFromHome ? CustomTextView(LocaleKeys.login.tr, color: Colors.white, type: TDSFontType.titleMedium,) :SvgPicture.asset(
          "assets/vectors/app_logo.svg",
          width: 56.w,
          height: 56.h,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isFromHome ? Colors.white : null,
          ),
          // Change this to your desired icon
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Form(
          key: globalKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24.h,
              ),
              CustomTextView(
                LocaleKeys.login_to_your_account.tr,
                type: TDSFontType.headlineSmall,
                color: BrandColor.main,
              ),
              SizedBox(
                height: 8.h,
              ),
              CustomTextView(
                LocaleKeys.login_to_your_account_desc.tr,
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
              TextFormField(
                validator: (value) {
                  if (value!.isEmpty ||
                      !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                          .hasMatch(value)) {
                    return 'Invalid email';
                  }
                  return null;
                },
                controller: loginController.emailTextFieldController,
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
              SizedBox(
                height: 24.h,
              ),
              Row(
                children: [
                  CustomTextView(
                    LocaleKeys.password.tr,
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
              Obx(
                    () =>
                    TextFormField(
                      obscureText: loginController.isPasswordHidden.value,
                      validator: (value) {
                        // Ensure password is not empty
                        if (value!.isEmpty) {
                          return 'Password is required';
                        }
                        // Ensure password has at least 8 characters
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long';
                        }
                        // Ensure password contains at least one uppercase letter
                        // if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        //   return 'Password must contain at least one uppercase letter';
                        // }
                        // // Ensure password contains at least one lowercase letter
                        // if (!RegExp(r'[a-z]').hasMatch(value)) {
                        //   return 'Password must contain at least one lowercase letter';
                        // }
                        // // Ensure password contains at least one digit
                        // if (!RegExp(r'[0-9]').hasMatch(value)) {
                        //   return 'Password must contain at least one number';
                        // }
                        // // Ensure password contains at least one special character
                        // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        //   return 'Password must contain at least one special character';
                        // }
                        return null;
                      },
                      controller: loginController.passwordTextFieldController,
                      decoration: InputDecoration(
                        errorMaxLines: 1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: BorderColor
                                .secondary, // Border color when not focused
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: TextColor.placeholder, // Custom hint color
                        ),
                        contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                        hintText: LocaleKeys.password_placeholder
                            .trParams({"example": "Your password"}),
                        // Adjust hint text
                        suffixIcon: IconButton(
                          icon: Icon(
                            loginController.isPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: TextColor.placeholder, // Customize the color
                          ),
                          onPressed: loginController.togglePasswordVisibility,
                        ),
                      ),
                    ),
              ),
              SizedBox(
                height: 16.h,
              ),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    children: [
                      TextSpan(
                          style: TextStyle(
                              color: TextColor.secondary,
                              fontSize: 14.sp,
                          ),
                          text: "${LocaleKeys.forgot_password_desc.tr} "),
                      TextSpan(
                        style: TextStyle(
                            color: BrandColor.main,
                            fontSize: 14.sp,
                            decoration: TextDecoration.underline,
                        ),
                        text: LocaleKeys.forgot_password_navigation.tr,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => ForgotPasswordScreen(selectedPlayer, selectedPlayerName));
                          },
                      ),
                      TextSpan(
                        style: TextStyle(
                            color: TextColor.secondary,
                            fontSize: 14.sp,
                        ),
                        text: " ${LocaleKeys.forgot_password_desc2.tr}",
                      ),

                    ],
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
                loginController.login(context, selectedPlayer, selectedPlayerName);
              }
            },
            child: loginController.isLoadingLogin.value
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: Colors.white, // Spinner color
              ),
            )
                : CustomTextView(
              LocaleKeys.login.tr,
              color: BrandColor.content,
            ),
          );
        }),
      ),
    );
  }
}
