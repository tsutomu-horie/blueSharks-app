import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/edit_profile_bottom_sheet_view.dart';
import 'package:koto_blue_sharks/app/views/views/member_card_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/DeleteAccountConfirmation/delete_account_confirmation.screen.dart';
import 'package:koto_blue_sharks/presentation/EditPassword/edit_password.screen.dart';
import 'package:koto_blue_sharks/presentation/RegisterEmailFromHome/register_email_from_home.screen.dart';
import 'package:koto_blue_sharks/presentation/login/login.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/mypage.controller.dart';

class MypageScreen extends GetView<MypageController> {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MypageController controller = Get.put(MypageController());

    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Obx(() {
            return Column(
              children: [
                // QrImageView(
                //   data: '1234567890',
                //   version: QrVersions.auto,
                //   size: 200.0,
                // ),
                Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: (controller.isLogin.value &&
                        controller.profileData.value?.isVerified != 0
                        ? Column(
                      children: [
                        !controller.isLoading.value
                            ? Obx(() {
                          return MemberCardView(
                              controller.profileData.value?.customerLevel ?? "",
                              controller.profileData.value?.accountId ??
                                  "");
                        })
                            : SizedBox(
                            width: 343.w,
                            height: 218.h,
                            child: shimmer()),
                        SizedBox(height: 16.h,),
                        Row(
                          children: [
                            SizedBox(
                              width: 16.w,
                            ),
                            Flexible(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                    onPressed: () {
                                      controller.getToken();
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                        WidgetStateProperty.all(
                                            BrandColor.main)),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          IconsaxPlusLinear.refresh_2,
                                          color: Colors.white,
                                          size: 18.w,
                                        ),
                                        SizedBox(
                                          width: 8.w,
                                        ),
                                        CustomTextView(
                                          LocaleKeys
                                              .membership_renewal.tr,
                                          type: TDSFontType.labelLarge,
                                          color: Colors.white,
                                        ),
                                      ],
                                    )),
                              ),
                            ),
                            SizedBox(
                              width: 16.w,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 24.h,
                        ),
                      ],
                    )
                        : AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            color: WarningColor.surface,
                            border: Border.all(color: WarningColor.main)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(IconsaxPlusLinear.info_circle),
                            SizedBox(
                              height: 16.h,
                            ),
                            CustomTextView(
                              LocaleKeys.your_not_login.tr,
                              style:
                              const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            CustomTextView(
                              LocaleKeys.not_login_desc.tr,
                              type: TDSFontType.bodyTextMedium,
                              color: TextColor.secondary,
                              align: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ))),
                if (controller.isLogin.value == true)
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        width: double.infinity,
                        color: BrandColor.main,
                        child: CustomTextView(
                          LocaleKeys.your_register_information.tr,
                          type: TDSFontType.titleSmall,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        children: [
                          Row(children: [
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
                                  child: Obx(() {
                                    return CustomTextView(
                                      controller.profileData.value?.email ?? "",
                                      align: TextAlign.start,
                                      color: TextColor.primary,
                                      type: TDSFontType.bodyTextMedium,
                                    );
                                  })),
                            ),
                          ]),
                          Container(
                            color: BorderColor.primary,
                            height: 1.h,
                            width: double.infinity,
                          ),
                          Row(children: [
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
                                  child: Obx(() {
                                    return CustomTextView(
                                      controller.profileData.value?.accountId ??
                                          "",
                                      align: TextAlign.start,
                                      color: TextColor.primary,
                                      type: TDSFontType.bodyTextMedium,
                                    );
                                  })),
                            ),
                          ]),
                          Container(
                            color: BorderColor.primary,
                            height: 1.h,
                            width: double.infinity,
                          ),
                          Row(children: [
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
                                    controller.playerNameController.value != "" ? controller.playerNameController.value : LocaleKeys.default_jp.tr,
                                    align: TextAlign.start,
                                    color: TextColor.primary,
                                    type: TDSFontType.bodyTextMedium,
                                  );
                                }),
                              ),
                            ),
                          ]),
                          Container(
                            color: BorderColor.primary,
                            height: 1.h,
                            width: double.infinity,
                          ),
                          Row(children: [
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
                                  child: Obx(() {
                                    return CustomTextView(
                                      controller.isSelectNotificaiton.value
                                          ? LocaleKeys.active.tr
                                          : LocaleKeys.inactive.tr,
                                      align: TextAlign.start,
                                      color: TextColor.primary,
                                      type: TDSFontType.bodyTextMedium,
                                    );
                                  })),
                            ),
                            SizedBox(
                              height: 16.h,
                            )
                          ]),
                          Container(
                            color: BorderColor.primary,
                            height: 1.h,
                            width: double.infinity,
                          ),
                          SizedBox(
                            height: 16.h,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            width: double.infinity,
                            height: 48.h,
                            child: OutlinedButton(
                              onPressed: () async {
                                controller.emailController.text =
                                    controller.profileData.value?.email ?? "";

                                controller.idController.text = await controller
                                    .profileData.value?.accountId ??
                                    "";
                                editProfileBottomSheet(controller, context,
                                        (email, id, wallpaper, wallpaperName,
                                        isNotifActive) async {
                                      print("get name ${wallpaperName}");
                                      controller.playerNameController.value =
                                          wallpaperName;
                                      controller.playerLinkController.value =
                                          wallpaper;
                                      controller.emailController.text = email;
                                      controller.idController.text = id;
                                      controller.isSelectNotificaiton.value =
                                          isNotifActive;

                                      await Future.delayed(
                                          const Duration(seconds: 1));
                                      controller.getToken();
                                      controller.update();
                                    },
                                    controller.profileData.value?.email ?? "");
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    IconsaxPlusLinear.grid_edit,
                                    color: BrandColor.main,
                                  ),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  CustomTextView(LocaleKeys.edit.tr,
                                      type: TDSFontType.titleSmall,
                                      color: BrandColor.main)
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 16.h,
                          ),
                        ],
                      ),
                    ],
                  ),
                SizedBox(
                  height: 20.h,
                ),
                Container(
                  color: BackgroundColor.fafafa,
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16.w,
                          ),
                          Container(
                            height: 1,
                            width: 15.w,
                            color: BrandColor.main,
                          ),
                          SizedBox(
                            width: 16.w,
                          ),
                          Flexible(
                            child: Text(
                              LocaleKeys.menu.tr,
                              style: TextStyle(
                                  fontSize: 20.sp,
                                  color: BrandColor.main,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            width: 16.w,
                          ),
                          Container(
                            height: 1,
                            width: 15.w,
                            color: BrandColor.main,
                          ),
                          SizedBox(
                            width: 16.w,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 24.h,
                      ),
                      Column(
                        children: [
                          controller.isLogin.value
                              ? SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: OutlinedButton(
                              onPressed: () {
                                Get.to(() => const EditPasswordScreen());
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(BorderSide(
                                    color: BrandColor
                                        .main) // Set your desired color here
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    size: 18.w,
                                    IconsaxPlusLinear.security_safe,
                                    color: BrandColor.main,
                                  ),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  CustomTextView(
                                      LocaleKeys.change_password.tr,
                                      type: TDSFontType.titleSmall,
                                      color: BrandColor.main),
                                ],
                              ),
                            ),
                          )
                              : SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: OutlinedButton(
                              onPressed: () async {
                                Get.to(LoginScreen(
                                    controller.playerLinkController.value,
                                    true,
                                    controller
                                        .playerNameController.value));
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(BorderSide(
                                    color: BrandColor
                                        .main) // Set your desired color here
                                ),
                              ),
                              child: CustomTextView(LocaleKeys.login.tr,
                                  type: TDSFontType.titleSmall,
                                  color: BrandColor.main),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 19.h,
                      ),
                      Column(
                        children: [
                          controller.isLogin.value
                              ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Get
                                        .to(() => const DeleteAccountConfirmationScreen());
                                  },
                                  style: ButtonStyle(
                                    side: WidgetStateProperty.all(BorderSide(
                                        color: DangerColor
                                            .main) // Set your desired color here
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        size: 18.w,
                                        IconsaxPlusLinear.profile_delete,
                                        color: DangerColor.main,
                                      ),
                                      SizedBox(
                                        width: 8.w,
                                      ),
                                      CustomTextView(
                                          LocaleKeys.delete_account.tr,
                                          type: TDSFontType.titleSmall,
                                          color: DangerColor.main)
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 19.h,),
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: OutlinedButton(
                                  onPressed: () {
                                    showLogoutConfirmation(
                                      context,
                                          () => controller.logout(),
                                    );
                                  },
                                  style: ButtonStyle(
                                    side: WidgetStateProperty.all(BorderSide(
                                        color: DangerColor
                                            .main) // Set your desired color here
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        size: 18.w,
                                        IconsaxPlusLinear.logout,
                                        color: DangerColor.main,
                                      ),
                                      SizedBox(
                                        width: 8.w,
                                      ),
                                      CustomTextView(
                                          LocaleKeys.logout.tr,
                                          type: TDSFontType.titleSmall,
                                          color: DangerColor.main)
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                              : SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: OutlinedButton(
                              onPressed: () async {
                                Get.to(RegisterEmailFromHomeScreen(
                                    controller.playerLinkController.value,
                                    controller
                                        .playerNameController.value));
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(BorderSide(
                                    color: BrandColor
                                        .main) // Set your desired color here
                                ),
                              ),
                              child: CustomTextView(
                                  LocaleKeys.register.tr,
                                  type: TDSFontType.titleSmall,
                                  color: BrandColor.main),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 8.h,
                ),
                const Divider(),
                SizedBox(
                  height: 8.h,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 16.w,
                    ),
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
                                ..onTap = () {},
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
                                ..onTap = () {},
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
                    SizedBox(
                      width: 16.w,
                    ),
                  ],
                ),
                SizedBox(height: 75.h,),
              ],
            );
          }),
        ));
  }

  // Add this function at the bottom of the file
  void showLogoutConfirmation(BuildContext context, VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: WarningColor.main,
                size: 24.w,
              ),
              SizedBox(height: 16.h),
              CustomTextView(
                LocaleKeys.logout_confirmation_title.tr,
                type: TDSFontType.titleMedium,
                color: TextColor.primary,
                align: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              CustomTextView(
                LocaleKeys.logout_confirmation_desc.tr,
                type: TDSFontType.bodyTextMedium,
                color: TextColor.secondary,
                align: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: BorderColor.primary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: CustomTextView(
                        LocaleKeys.cancel.tr,
                        type: TDSFontType.labelLarge,
                        color: TextColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColor.main,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: CustomTextView(
                        LocaleKeys.confirm.tr,
                        type: TDSFontType.labelLarge,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget shimmer() {
  return Shimmer.fromColors(
    baseColor: BorderColor.disabled,
    highlightColor: BorderColor.subtle,
    child: Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: BorderColor.disabled,
        borderRadius: BorderRadius.all(Radius.circular(4.r)),
      ),
    ),
  );
}
