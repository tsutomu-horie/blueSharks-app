import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/FanClubConfirmation/fan_club_confirmation.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

import 'controllers/register_member_fanclub.controller.dart';

class RegisterMemberFanclubScreen
    extends GetView<RegisterMemberFanclubController> {
  const RegisterMemberFanclubScreen({super.key, required this.email, required this.otpId, required this.selectedPlayer});
  final String email;
  final String otpId;
  final String selectedPlayer;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final RegisterMemberFanclubController registerMemberFanclubController = Get.put(RegisterMemberFanclubController());


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h,),
            CustomTextView(LocaleKeys.register_email_title.tr, type: TDSFontType.headlineSmall, color: BrandColor.main,),
            SizedBox(height: 8.h,),
            CustomTextView(LocaleKeys.register_email_desc.tr, type: TDSFontType.bodyTextMedium, color: TextColor.secondary,),
            SizedBox(height: 8.h,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: BorderColor.primary, width: 1.w)),
              child: CustomTextView(
                LocaleKeys.registered_email.trParams({"email": email}),
                type: TDSFontType.bodyTextSmall,
                color: TextColor.secondary,
              ),
            ),
            SizedBox(height: 24.h,),
            Form(
              key: globalKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomTextView(
                        LocaleKeys.fanclub_member_id.tr,
                        type: TDSFontType.bodyTextSmall,
                        color: TextColor.secondary,
                      ),
                      CustomTextView(
                        " *",
                        type: TDSFontType.bodyTextMedium,
                        color: DangerColor.main,
                      ),
                    ],
                  ),

                  TextFormField(
                    controller: controller.idTextFieldController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'ID cannot empty';
                      }
                      return null;
                    },
                    // controller: registerEmailController.textFieldController,
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

                  SizedBox(height: 24.h,),

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
                          obscureText: registerMemberFanclubController.isPasswordHidden.value,
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
                          controller: registerMemberFanclubController.passwordTextFieldController,
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
                                registerMemberFanclubController.isPasswordHidden.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: TextColor.placeholder, // Customize the color
                              ),
                              onPressed: registerMemberFanclubController.togglePasswordVisibility,
                            ),
                          ),
                        ),
                  ),
                  CustomTextView(LocaleKeys.password_desc.tr, type: TDSFontType.bodyTextMedium, color: TextColor.tertiary,)
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        child: Flexible(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColor.main),
              onPressed: () {
                print(globalKey.currentState!.validate());
                if (globalKey.currentState!.validate()) {
                  registerMemberFanclubController.onRegister(otpId, email, (){
                    Utils.showError(context, LocaleKeys.membership_dialog_title, LocaleKeys.membership_dialog_message);
                  }, (){
                    // Get.offAll(() => FanClubConfirmationScreen(email: email, id: ,));
                  }, selectedPlayer);
                }
              },
              child: CustomTextView(
                LocaleKeys.certification.tr,
                color: BrandColor.content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
