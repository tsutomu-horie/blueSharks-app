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
  const RegisterOtpScreen({super.key, required this.email, required this.otpId, required this.fromScreen, required this.selectedPlayer, this.onSuccess, required this.selectedPlayerName});

  final String email;
  final String? otpId;
  final String fromScreen;
  final String selectedPlayer;
  final String selectedPlayerName;
  final Function? onSuccess;

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
          fontSize: 20, color: TextColor.secondary, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: BorderColor.secondary),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20.h,
              ),
              CustomTextView(
                LocaleKeys.otp_title.tr,
                type: TDSFontType.headlineSmall,
                color: BrandColor.main,
              ),
              SizedBox(
                height: 8.h,
              ),
              CustomTextView(
                LocaleKeys.otp_message.tr,
                type: TDSFontType.bodyTextMedium,
                color: TextColor.secondary,
              ),
              SizedBox(
                height: 8.h,
              ),
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
              SizedBox(
                height: 44.h,
              ),
              Pinput(
                length: 5,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                errorPinTheme: submittedPinTheme,
                onChanged: (data) {
                  controller.otp.value = data;
                },
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                pinAnimationType: PinAnimationType.none,
                showCursor: true,
                onCompleted: (pin) => print(pin),
              ),
              SizedBox(
                height: 20.h,
              ),
              InkWell(
                onTap: (){
                  print("resend");
                  controller.resendOtp(email, context, otpId);
                },
                  child: CustomTextView(
                LocaleKeys.resend_otp_email.tr,
                color: BrandColor.main,
                style: const TextStyle(decoration: TextDecoration.underline),
              ))
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () {
            controller.onSubmitOtp(email, context, fromScreen, otpId, selectedPlayer, selectedPlayerName, onSuccess);
          },
          child: CustomTextView(
            LocaleKeys.send.tr,
            color: BrandColor.content,
          ),
        ),
      ),
    );
  }
}
