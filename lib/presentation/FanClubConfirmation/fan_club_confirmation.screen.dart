
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/edit_profile_bottom_sheet_view.dart';
import 'package:koto_blue_sharks/app/views/views/member_card_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/PrivacyPolicyScreen/privacy_policy_screen.screen.dart';
import 'package:koto_blue_sharks/presentation/forgotPassword/forgot_password.screen.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/mypage/mypage.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/fcm_helper.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';

import 'controllers/fan_club_confirmation.controller.dart';

class FanClubConfirmationScreen extends GetView<FanClubConfirmationController> {
  const FanClubConfirmationScreen(
      {super.key, required this.email, required this.id, required this.playerSelected, required this.isNotification, required this.playerSelectedName, required this.isFromHome});

  final String email;
  final String id;
  final String playerSelected;
  final String playerSelectedName;
  final bool isNotification;
  final bool isFromHome;

  @override
  Widget build(BuildContext context) {
    final FanClubConfirmationController controller = Get.put(
        FanClubConfirmationController());

    controller.isSelectNotificaiton.value = isNotification;
    controller.emailController.text = email;
    controller.idController.text = id;
    controller.playerNameController.value = playerSelectedName;
    controller.playerLinkController.value = playerSelected;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: SvgPicture.asset(
          "assets/vectors/app_logo.svg",
          width: 46.w,
          height: 46.h,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h,),

            Obx(() {
              final isEitherMatched = controller.profileData.value?.isEitherMatched == true;

              if (isEitherMatched) {
                return Column(
                  children: [
                    !controller.isLoading.value
                        ? Obx(() {
                      return MemberCardView(
                          controller.profileData.value
                              ?.customerLevel ??
                              "",
                          controller.profileData.value
                              ?.accountId ??
                              "");
                    })
                        : SizedBox(
                        width: 343.w,
                        height: 218.h,
                        child: shimmer()),
                    SizedBox(
                      height: 16.h,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextView(LocaleKeys.fanclub_title.tr,
                              type: TDSFontType.headlineSmall, color: BrandColor
                                  .main,),
                            SizedBox(height: 30.h,),
                            DottedBorder(
                              color: Colors.blue,
                              // Border color
                              strokeWidth: 1.w,
                              // Border thickness
                              dashPattern: const [6, 3],
                              // Dash and gap lengths
                              borderType: BorderType.RRect,
                              // Rounded Rectangular border
                              radius: Radius.circular(12.r),
                              // Corner radius for rounded rectangle
                              child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 26.h),
                                  width: double.infinity,
                                  color: BrandColor.surface,
                                  child: Column(
                                    children: [
                                      CustomTextView(
                                        LocaleKeys.membership_card_display
                                            .tr, style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: TextColor.primary),),
                                      SizedBox(height: 4.h,),
                                      CustomTextView(LocaleKeys
                                          .membership_card_display_desc.tr,
                                        type: TDSFontType.bodyTextMedium,
                                        align: TextAlign.center,
                                        color: TextColor.secondary,),
                                      SizedBox(height: 16.h,),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            border:
                                            Border.all(color: BrandColor.main),
                                            borderRadius:
                                            BorderRadius.circular(24.r)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24.w, vertical: 8.h),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              IconsaxPlusLinear.tick_circle,
                                              color: BrandColor.main,
                                            ),
                                            SizedBox(
                                              width: 8.w,
                                            ),
                                            CustomTextView(
                                              LocaleKeys.membership_information
                                                  .tr,
                                              color: BrandColor.main,
                                              type: TDSFontType.labelMedium,
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ),
                            ),
                            SizedBox(height: 24.h,),
                            CustomTextView(
                              LocaleKeys.membership_information_desc
                                  .tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 14.sp),
                              align: TextAlign.center,),
                            SizedBox(height: 16.h,),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(onPressed: () {
                                  controller.launchFanClub();
                                }, child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CustomTextView(
                                          LocaleKeys.fan_club_site.tr,
                                          color: BrandColor.main,),
                                        SizedBox(width: 8.w,),
                                        Icon(
                                          IconsaxPlusLinear.export_2,
                                          size: 16.w,
                                          color: BrandColor.main,),
                                      ],
                                    ),
                                    Container(color: BrandColor.main,
                                      height: 1.h,
                                      width: 150.w,)
                                  ],
                                ),),
                              ],
                            ),
                            SizedBox(height: 24.h,),
                          ],
                        )),
                  ],
                );
              }
            }),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: BrandColor.main,
              child: CustomTextView(
                LocaleKeys.your_register_information.tr, color: Colors.white,),
            ),
            Row(
                children: [
                  Container(
                      width: 152.w,
                      height: 64.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 16.w),
                      child: CustomTextView(
                        LocaleKeys.email_address.tr,
                        align: TextAlign.start,
                        color: TextColor.secondary,
                        type: TDSFontType.bodyTextMedium,
                      )),

                  Flexible(
                    child: Container(
                        width: double.infinity,
                        height: 64.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 22.h, horizontal: 16.w),
                        child: CustomTextView(
                          email,
                          align: TextAlign.start,
                          color: TextColor.primary,
                          type: TDSFontType.bodyTextMedium,
                        )),
                  ),
                ]),
            Container(
              color: BorderColor.primary, height: 1.h, width: double.infinity,),
            Row(
                children: [
                  Container(
                      width: 152.w,
                      height: 44.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 16.w),
                      child: CustomTextView(
                        LocaleKeys.fan_club_id.tr,
                        align: TextAlign.start,
                        color: TextColor.secondary,
                        type: TDSFontType.bodyTextMedium,
                      )),

                  Flexible(
                    child: Container(
                        width: double.infinity,
                        height: 44.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 16.w),
                        child: CustomTextView(
                          id,
                          align: TextAlign.start,
                          color: TextColor.primary,
                          type: TDSFontType.bodyTextMedium,
                        )),
                  ),
                ]),
            Container(
              color: BorderColor.primary, height: 1.h, width: double.infinity,),
            Row(
                children: [
                  Container(
                      width: 152.w,
                      height: 44.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 16.w),
                      child: CustomTextView(
                        LocaleKeys.wallpaper_setting.tr,
                        align: TextAlign.start,
                        color: TextColor.secondary,
                        type: TDSFontType.bodyTextMedium,
                      )),

                  Flexible(
                    child: Container(
                        width: double.infinity,
                        height: 44.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 16.w),
                        child: Obx(() {
                          return CustomTextView(
                            controller.playerNameController.value != ""
                                ? controller.playerNameController.value
                                : LocaleKeys.default_jp.tr,
                            align: TextAlign.start,
                            color: TextColor.primary,
                            type: TDSFontType.bodyTextMedium,
                          );
                        })),
                  ),
                ]),
            Container(
              color: BorderColor.primary, height: 1.h, width: double.infinity,),
            Row(
                children: [
                  Container(
                      width: 152.w,
                      height: 44.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 16.w),
                      child: CustomTextView(
                        LocaleKeys.notice.tr,
                        align: TextAlign.start,
                        color: TextColor.secondary,
                        type: TDSFontType.bodyTextMedium,
                      )),

                  Flexible(
                    child: Container(
                        width: double.infinity,
                        height: 44.h,
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 16.w),
                        child: CustomTextView(
                          isNotification ? LocaleKeys.on.tr : LocaleKeys
                              .off.tr,
                          align: TextAlign.start,
                          color: TextColor.primary,
                          type: TDSFontType.bodyTextMedium,
                        )),
                  ),

                  SizedBox(height: 16.h,)
                ]),

            Container(
              color: BorderColor.primary, height: 1.h, width: double.infinity,),

            SizedBox(height: 16.h,),

            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    editProfileBottomSheet(
                        controller, context, (email, id, wallpaper,
                        wallpaperName, isNotifActive) {
                      Get.back();
                      controller.playerNameController.value = wallpaperName;
                    }, email);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconsaxPlusLinear.grid_edit, color: BrandColor.main,),
                      SizedBox(width: 8.w,),
                      CustomTextView(LocaleKeys.edit_information.tr,
                          type: TDSFontType.titleSmall, color: BrandColor.main)
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h,),

            Row(
              children: [
                SizedBox(width: 16.w,),
                Flexible(child: const Divider()),
                SizedBox(width: 16.w,),

              ],
            ),

            Row(
              children: [
                SizedBox(width: 16.w,),
                Flexible(
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                            style: TextStyle(
                              color: TextColor.secondary,
                              fontSize: 14.sp,
                            ),
                            text: "${LocaleKeys.privacy_policy_desc.tr} "),
                        TextSpan(
                          style: TextStyle(
                            color: BrandColor.main,
                            fontSize: 14.sp,
                            decoration: TextDecoration.underline,
                          ),
                          text: LocaleKeys.privacy_policy.tr,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(() => const PrivacyPolicyScreen());
                            },
                        ),
                        TextSpan(
                          style: TextStyle(
                            color: TextColor.secondary,
                            fontSize: 14.sp,
                          ),
                          text: " ${LocaleKeys.and.tr}",
                        ),
                        TextSpan(
                          style: TextStyle(
                            color: BrandColor.main,
                            fontSize: 14.sp,
                            decoration: TextDecoration.underline,
                          ),
                          text: LocaleKeys.term_of_use.tr,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(() =>
                                  ForgotPasswordScreen(
                                      playerSelected, playerSelectedName));
                            },
                        ),
                        TextSpan(
                          style: TextStyle(
                            color: TextColor.secondary,
                            fontSize: 14.sp,
                          ),
                          text: " ${LocaleKeys.privacy_policy_desc2.tr}",
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w,),
              ],
            ),
            SizedBox(height: 28.h,),

          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () async {
            await FcmHelper.initFcm();
            MySharedPref.setFirstOpen("alreadyOpen");
            if (!isFromHome) {
              Get.offAll(() => const MainScreen());
            } else {
              Get.offAll(() => const MainScreen(initialTab: 2));
            }
          },
          child: CustomTextView(
            LocaleKeys.jump_to.tr,
            color: BrandColor.content,
          ),
        ),
      ),
    );
  }
}