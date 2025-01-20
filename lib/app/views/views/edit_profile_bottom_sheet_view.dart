import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_switch_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/register/fan_club_confirmation/controllers/fan_club_confirmation.controller.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:lottie/lottie.dart';

void editProfileBottomSheet(FanClubConfirmationController fanclubController,
    BuildContext context,
    Function(String, String, String, String, bool) onSuccess,
    String oldEmail) {
  final formKey = GlobalKey<FormState>();
  final originalPlayerName = fanclubController.playerNameController.value;
  final originalPlayerLink = fanclubController.playerLinkController.value;

  showModalBottomSheet(
    backgroundColor: Colors.white,
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) {
      return PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          // Revert values when dismissed
          fanclubController.playerNameController.value = originalPlayerName;
          fanclubController.playerLinkController.value = originalPlayerLink;
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom,
            left: 16.w,
            right: 16.w,
            top: 16.w,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                CustomTextView(
                  LocaleKeys.edit_information_title.tr,
                  type: TDSFontType.titleMedium,
                  color: TextColor.secondary,
                ),
                SizedBox(height: 10.h),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        SizedBox(height: 4.h),
                        TextFormField(
                          controller: fanclubController.emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return LocaleKeys.error_email_required.tr;
                            }
                            if (!RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                                .hasMatch(value)) {
                              return LocaleKeys.error_email_invalid.tr;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            errorStyle: TextStyle(
                              color: TextColor.error,
                              fontSize: 12.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                  color: BorderColor.secondary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: TextColor.error),
                            ),
                            contentPadding: EdgeInsets.only(
                                top: 2.h, left: 16.w),
                            hintText: LocaleKeys.email_placeholder.trParams(
                                {"example": "jack@email.com"}),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        CustomTextView(
                          LocaleKeys.edit_information_email_warning.tr,
                          type: TDSFontType.bodyTextMedium,
                          color: TextColor.secondary,
                        ),
                        SizedBox(height: 12.h),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ],
                          controller: fanclubController.idController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return LocaleKeys.error_id_required.tr;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            errorStyle: TextStyle(
                              color: TextColor.error,
                              fontSize: 12.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                  color: BorderColor.secondary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(color: TextColor.error),
                            ),
                            contentPadding: EdgeInsets.only(
                                top: 2.h, left: 16.w),
                            hintText: LocaleKeys.user_id_placeholder.tr,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            CustomTextView(
                              LocaleKeys.wallpaper_setting.tr,
                              type: TDSFontType.bodyTextSmall,
                              color: TextColor.secondary,
                            ),
                            // CustomTextView(
                            //   " *",
                            //   type: TDSFontType.bodyTextMedium,
                            //   color: DangerColor.main,
                            // ),
                          ],
                        ),
                        FormField<String>(
                          // validator: (value) {
                          //   if (fanclubController.playerNameController.value.isEmpty) {
                          //     return LocaleKeys.error_wallpaper_required.tr;
                          //   }
                          //   return null;
                          // },
                          builder: (FormFieldState<String> state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    print(
                                        "button set wallpaper ${fanclubController
                                            .playerLinkController.value}");
                                    Get.to(() =>
                                        UpdateWallpaperScreen((value, link) {
                                          print("valuenya ${fanclubController
                                              .playerLinkController.value}");
                                          fanclubController.playerNameController
                                              .value = value;
                                          fanclubController.playerLinkController
                                              .value = link;
                                          state.didChange(value);
                                          Get.back();
                                        }, fanclubController
                                            .playerLinkController.value),
                                        preventDuplicates: false);
                                  },
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                        EdgeInsets.zero),
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.r),
                                      ),
                                    ),
                                    side: MaterialStateProperty.all(
                                      BorderSide(
                                        color: state.hasError
                                            ? TextColor.error
                                            : BorderColor.secondary,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 12.w),
                                      Flexible(
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Obx(() {
                                            return CustomTextView(
                                              fanclubController
                                                  .playerNameController.value
                                                  .isEmpty
                                                  ? LocaleKeys
                                                  .wallpaper_placeholder.tr
                                                  : fanclubController
                                                  .playerNameController.value,
                                              type: TDSFontType.bodyTextMedium,
                                              color: fanclubController
                                                  .playerNameController.value
                                                  .isEmpty
                                                  ? TextColor.placeholder
                                                  : TextColor.primary,
                                            );
                                          }),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(Icons.keyboard_arrow_down,
                                          size: 20.w),
                                      SizedBox(width: 12.w),
                                    ],
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 4.h, left: 16.w),
                                    child: CustomTextView(
                                      state.errorText!,
                                      type: TDSFontType.bodyTextSmall,
                                      color: TextColor.error,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          height: 48.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: BorderColor.primary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomTextView(LocaleKeys.notice.tr),
                              SizedBox(
                                height: 20.h,
                                child: Obx(() {
                                  return CustomSwitch(
                                    value: fanclubController
                                        .isSelectNotificaiton.value,
                                    onChanged: (value) {
                                      print("value $value");
                                      fanclubController.isSelectNotificaiton
                                          .value = value;
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColor.main,
                            ),
                            onPressed: () {
                              print("trigger button ${formKey.currentState!
                                  .validate()}");
                              if (formKey.currentState!.validate()) {
                                if (fanclubController.emailController.text ==
                                    oldEmail) {
                                  fanclubController.updateProfile(onSuccess);
                                } else {
                                  fanclubController.sendOtp((id) {
                                    showEmailDialog(
                                      fanclubController,
                                      context,
                                      "$id",
                                          () {
                                        fanclubController.updateProfile(
                                              (email, id, playerlink,
                                              playername, notification) {
                                            onSuccess(email, id, playerlink,
                                                playername, notification);
                                          },
                                        );
                                      },
                                    );
                                  }, true, context);
                                }
                              }
                            },
                            child: CustomTextView(
                              LocaleKeys.save.tr,
                              color: BrandColor.content,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showEmailDialog(FanClubConfirmationController registerEmailController,
    BuildContext context, String? otpId, Function onSuccess) {
  showDialog(
    context: context,
    barrierDismissible: false, // Dismiss when tapped outside
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
              // SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.main,
                  ),
                  onPressed: () {
                    print("dialog tapped");
                    Get.back();
                    Get.to(() =>
                        RegisterOtpScreen(
                            isRegister: true,
                            email: registerEmailController.emailController.text,
                            fromScreen: "editProfile",
                            otpId: otpId,
                            selectedPlayer:
                            registerEmailController.playerNameController.value,
                            selectedPlayerName: registerEmailController
                                .playerLinkController.value,
                            onSuccess: onSuccess), preventDuplicates: false);
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
