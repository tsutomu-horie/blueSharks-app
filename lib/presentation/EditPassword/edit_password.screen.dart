import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/edit_password.controller.dart';

class EditPasswordScreen extends GetView<EditPasswordController> {
  const EditPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final EditPasswordController forgotPasswordController = EditPasswordController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:  BrandColor.main,
        title: CustomTextView(LocaleKeys.change_password.tr, color: Colors.white, type: TDSFontType.titleMedium,),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Form(
              key: globalKey,
              child: Column(
                children: [
                  SizedBox(height: 24.h,),
                  Row(
                    children: [
                      CustomTextView(LocaleKeys.new_password.tr, type: TDSFontType.labelLarge, color: TextColor.secondary,),
                      CustomTextView(" *", type: TDSFontType.labelLarge, color: TextColor.error,),
                    ],
                  ),

                  SizedBox(height: 4.h,),

                  Obx(
                        () => TextFormField(
                      obscureText: forgotPasswordController.isCurrentPasswordHidden.value,
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
                      controller: forgotPasswordController.currentPassword,
                      decoration: InputDecoration(
                        errorMaxLines: 1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: BorderColor.secondary, // Border color when not focused
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: TextColor.placeholder, // Custom hint color
                        ),
                        contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                        hintText: LocaleKeys.new_password_placeholder.trParams({"example": "Your password"}), // Adjust hint text
                        suffixIcon: IconButton(
                          icon: Icon(
                            forgotPasswordController.isCurrentPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: TextColor.placeholder, // Customize the color
                          ),
                          onPressed: (){
                            forgotPasswordController.isCurrentPasswordHidden.value = !forgotPasswordController.isCurrentPasswordHidden.value;
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h,),

                  Row(
                    children: [
                      CustomTextView(LocaleKeys.new_password.tr, type: TDSFontType.labelLarge, color: TextColor.secondary,),
                      CustomTextView(" *", type: TDSFontType.labelLarge, color: TextColor.error,),
                    ],
                  ),

                  SizedBox(height: 4.h,),

                  Obx(
                        () => TextFormField(
                      obscureText: forgotPasswordController.isOldPasswordHidden.value,
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
                      controller: forgotPasswordController.oldPasswordController,
                      decoration: InputDecoration(
                        errorMaxLines: 1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: BorderColor.secondary, // Border color when not focused
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: TextColor.placeholder, // Custom hint color
                        ),
                        contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                        hintText: LocaleKeys.confirm_new_password_placeholder.trParams({"example": "Your password"}), // Adjust hint text
                        suffixIcon: IconButton(
                          icon: Icon(
                            forgotPasswordController.isOldPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: TextColor.placeholder, // Customize the color
                          ),
                          onPressed: (){
                            forgotPasswordController.isOldPasswordHidden.value = !forgotPasswordController.isOldPasswordHidden.value;
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h,),

                  Row(
                    children: [
                      CustomTextView(LocaleKeys.confirm_new_password.tr, type: TDSFontType.labelLarge, color: TextColor.secondary,),
                      CustomTextView(" *", type: TDSFontType.labelLarge, color: TextColor.error,),
                    ],
                  ),

                  SizedBox(height: 4.h,),

                  Obx(
                        () => TextFormField(
                      obscureText: forgotPasswordController.isNewPasswordHidden.value,
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
                      controller: forgotPasswordController.newPasswordController,
                      decoration: InputDecoration(
                        errorMaxLines: 1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: BorderColor.secondary, // Border color when not focused
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: TextColor.placeholder, // Custom hint color
                        ),
                        contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                        hintText: LocaleKeys.confirm_new_password_placeholder.trParams({"example": "Your password"}), // Adjust hint text
                        suffixIcon: IconButton(
                          icon: Icon(
                            forgotPasswordController.isNewPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: TextColor.placeholder, // Customize the color
                          ),
                          onPressed: (){
                            forgotPasswordController.isNewPasswordHidden.value = !forgotPasswordController.isNewPasswordHidden.value;
                          },
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h,),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
                      onPressed: () {
                        // controller.onNext();
                      },
                      child: CustomTextView(
                        LocaleKeys.next.tr,
                        color: BrandColor.content,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
