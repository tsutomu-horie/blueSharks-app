import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:pinput/pinput.dart';

import 'controllers/register_otp.controller.dart';

class RegisterOtpScreen extends GetView<RegisterOtpController> {
  const RegisterOtpScreen(
      {super.key, required this.email, required this.otpId, required this.fromScreen, required this.selectedPlayer, this.onSuccess, required this.selectedPlayerName, required this.isRegister});

  final String email;
  final String? otpId;
  final String fromScreen;
  final String selectedPlayer;
  final String selectedPlayerName;
  final Function? onSuccess;
  final bool isRegister;


  @override
  Widget build(BuildContext context) {
    final RegisterOtpController registerOtpController =
    Get.put(RegisterOtpController());

    if (otpId != null) {
      registerOtpController.otp_id.value = otpId!;
    }
    final defaultPinTheme = PinTheme(
      width: 40.w,
      height: 40.h,
      textStyle: TextStyle(
          fontSize: 20,
          color: TextColor.secondary,
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
          border: registerOtpController.hasError.value ? Border.all(
              color: BorderColor.error) : Border.all(
              color: BorderColor.secondary),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyDecorationWith();
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
          color: Colors.white,
          border: Border.all(color: BrandColor.main)
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: fromScreen == "forgotPasswordHome" || fromScreen == "register_home" ?
      AppBar(
        backgroundColor: BrandColor.main,
        title: CustomTextView(
          LocaleKeys.forgot_password_header_home.tr, color: Colors.white,
          type: TDSFontType.titleMedium,),
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
      )
          : AppBar(
        backgroundColor: Colors.white,
        title: SvgPicture.asset(
          "assets/vectors/app_logo.svg",
          width: 46.w,
          height: 46.h,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              // Allow Column to wrap its content
              children: [
                SizedBox(
                  height: 20.h,
                ),
                if (fromScreen != "forgotPasswordHome" && fromScreen != "register_home")
                  Column(
                    children: [
                      CustomTextView(
                        LocaleKeys.otp_title.tr,
                        type: TDSFontType.headlineSmall,
                        color: BrandColor.main,
                      ),
                      SizedBox(
                        height: 8.h,
                      ),
                    ],
                  ),
                CustomTextView(
                  fromScreen == "forgotPasswordHome" || fromScreen == "register_home"
                      ? LocaleKeys.forgot_password_desc_from_home.tr
                      : LocaleKeys.otp_message.tr,
                  type: TDSFontType.bodyTextMedium,
                  color: TextColor.secondary,
                ),
                SizedBox(
                  height: 16.h,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: BorderColor.primary, width: 1.w),
                  ),
                  child: CustomTextView(
                    LocaleKeys.registered_email.trParams({"email": email}),
                    type: TDSFontType.bodyTextSmall,
                    color: TextColor.secondary,
                  ),
                ),
                SizedBox(
                  height: 44.h,
                ),
                Obx(() {
                  return Pinput(
                    length: 5,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    onChanged: (data) {
                      registerOtpController.hasError.value = false;
                      controller.otp.value = data;
                    },
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    pinAnimationType: PinAnimationType.none,
                    showCursor: true,
                    onCompleted: (pin) => print(pin),
                    errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: TextColor.error),
                      ),
                    ),
                    forceErrorState: controller.hasError.value,
                  );
                }),
                SizedBox(
                  height: 20.h,
                ),
                // if (fromScreen != "forgotPasswordHome")
                  Row(
                    children: [
                      CustomTextView(
                        LocaleKeys.request_resend_otp.tr,
                        style: TextStyle(
                          color: TextColor.secondary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Obx(() {
                        if (!controller.canResend.value) {
                          return CustomTextView(
                            controller.formattedTime,
                            style: TextStyle(
                              color: BrandColor.main,
                            ),
                          );
                        } else {
                          return InkWell(
                            onTap: () {
                              controller.handleResendOtp(
                                  email, context, otpId, isRegister);
                            },
                            child: CustomTextView(
                              LocaleKeys.resend.tr,
                              style: TextStyle(
                                color: BrandColor.main,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                      }),
                    ],
                  )
                // else
                //   Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     mainAxisSize: MainAxisSize.min,
                //     // Ensure wrapping of content
                //     children: [
                //       RichText(
                //         textAlign: TextAlign.start,
                //         text: TextSpan(
                //           children: [
                //             TextSpan(
                //               style: TextStyle(
                //                 color: TextColor.secondary,
                //                 fontSize: 14.sp,
                //
                //               ),
                //               text: "${LocaleKeys.not_receive_otp.tr} ",
                //             ),
                //             TextSpan(
                //               style: TextStyle(
                //                 color: BrandColor.main,
                //                 fontSize: 14.sp,
                //                 decoration: TextDecoration.underline,
                //
                //               ),
                //               text: LocaleKeys.resend.tr,
                //               recognizer: TapGestureRecognizer()
                //                 ..onTap = () {
                //                   controller.resendOtp(
                //                       email, context, otpId, isRegister);
                //                 },
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   )
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () {
            controller.onSubmitOtp(
                email,
                context,
                fromScreen,
                otpId,
                selectedPlayer,
                selectedPlayerName,
                onSuccess,
                isRegister);
          },
          child: CustomTextView(
            LocaleKeys.send.tr,
            color: BrandColor.content,
          ),
        ),
      ),
    );
  }

  // void showLimitDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20.r),
  //         ),
  //         child: Padding(
  //           padding: EdgeInsets.all(16.w),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(
  //                 Icon
  //                 color: WarningColor.main,
  //                 size: 48.w,
  //               ),
  //               SizedBox(height: 16.h),
  //               CustomTextView(
  //                 LocaleKeys.otp_limit_title.tr,
  //                 type: TDSFontType.titleMedium,
  //                 align: TextAlign.center,
  //               ),
  //               SizedBox(height: 8.h),
  //               CustomTextView(
  //                 LocaleKeys.otp_limit_message.tr,
  //                 type: TDSFontType.bodyTextMedium,
  //                 color: TextColor.secondary,
  //                 align: TextAlign.center,
  //               ),
  //               SizedBox(height: 24.h),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: BrandColor.main,
  //                   ),
  //                   onPressed: () => Get.back(),
  //                   child: CustomTextView(
  //                     LocaleKeys.close.tr,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
