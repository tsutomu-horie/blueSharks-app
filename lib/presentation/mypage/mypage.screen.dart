import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/edit_profile_bottom_sheet_view.dart';
import 'package:koto_blue_sharks/app/views/views/member_card_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/DeleteAccountConfirmation/delete_account_confirmation.screen.dart';
import 'package:koto_blue_sharks/presentation/EditPassword/edit_password.screen.dart';
import 'package:koto_blue_sharks/presentation/RegisterEmailFromHome/register_email_from_home.screen.dart';
import 'package:koto_blue_sharks/presentation/login/login.screen.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/mypage.controller.dart';

class MypageScreen extends GetView<MypageController> {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MypageController controller = Get.put(MypageController());

    controller.onInit();
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Obx(() {
            final isEitherMatched = controller.profileData.value?.isEitherMatched == true;
            // final isEitherMatched = true;
            return Column(
              children: [
                Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: (controller.isLogin.value &&
                            controller.profileData.value?.isVerified != false
                        ? Column(
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
                        : Column(
                          children: [
                            controller.isLogin.value ?
                            notVerifiedUserCard(controller)
                            :
                            AspectRatio(
                                aspectRatio: 16 / 10,
                                child: DottedBorder(
                                  borderType: BorderType.RRect,
                                  radius: Radius.circular(12.r),
                                  padding: EdgeInsets.zero,
                                  color: isEitherMatched ? DangerColor.main : WarningColor.main,
                                  strokeWidth: 1,
                                  dashPattern: const [5, 5],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: isEitherMatched ? 16.w : 20.w, vertical: 20.h),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      color: isEitherMatched ? DangerColor.main.withOpacity(0.1) : WarningColor.surface,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset( isEitherMatched ? "assets/vectors/close-circle.svg" : "assets/vectors/info-circle.svg"),
                                        SizedBox(height: 16.h),
                                        CustomTextView(
                                          isEitherMatched ? LocaleKeys.failed_verification_title.tr : LocaleKeys.your_not_login.tr,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        SizedBox(height: 4.h),
                                        CustomTextView(
                                          isEitherMatched ? LocaleKeys.failed_verification_desc.tr : LocaleKeys.not_login_desc.tr,
                                          type: TDSFontType.bodyTextSmall,
                                          color: TextColor.secondary,
                                          align: TextAlign.center,
                                        ),
                                        SizedBox(height: 16.h,),
                                        if (isEitherMatched)
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(24.r),
                                              border: Border.all(color: DangerColor.main)
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(IconsaxPlusLinear.tick_circle, color: DangerColor.main,),
                                                SizedBox(width: 8.w,),
                                                CustomTextView(LocaleKeys.member_authentication.tr,type: TDSFontType.labelMedium,),
                                              ],
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                )
                              ),
                            if (isEitherMatched)
                              Column(
                                children: [
                                  SizedBox(height: 24.h,),
                                  CustomTextView(LocaleKeys.check_website_title.tr, style: TextStyle(fontWeight: FontWeight.w400), color: TextColor.secondary, align: TextAlign.center,),
                                  SizedBox(height: 16.h,),
                                  InkWell(
                                      onTap: (){
                                        launchExternalWeb(Constants.fanClubUrl);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: BrandColor.main,
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Title text
                                            CustomTextView(
                                              LocaleKeys.fan_club_site.tr,  // "Fan Club Site"
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: BrandColor.main,
                                              ),
                                            ),
                                            SizedBox(width: 8.w,),
                                            // External link icon
                                            Icon(IconsaxPlusLinear.export_2, color: BrandColor.main, size: 16.w,)
                                          ],
                                        ),
                                      )
                                  )
                                ],
                              )
                          ],
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
                                    controller.playerNameController.value != ""
                                        ? controller.playerNameController.value
                                        : LocaleKeys.default_jp.tr,
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
                                          ? LocaleKeys.on.tr
                                          : LocaleKeys.off.tr,
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
                                // Get.to(() => FanClubConfirmationScreen(email: '', id: '', playerSelected: '', isNotification: false, playerSelectedName: '', isFromHome: false,));
                                controller.emailController.text =
                                    controller.profileData.value?.email ?? "";

                                controller.idController.text = await controller
                                        .profileData.value?.accountId ?? "";


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
                                }, controller.profileData.value?.email ?? "");
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
                                      Get.to(() => LoginScreen(
                                          controller.playerLinkController.value,
                                          true,
                                          controller.playerNameController
                                              .value))?.then((result) {
                                        if (result == true) {
                                          // Refresh the page when we return
                                          controller.onInit();
                                        }
                                      });
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
                                          Get.to(() =>
                                                  const DeleteAccountConfirmationScreen())
                                              ?.then((result) {
                                            if (result == true) {
                                              controller.logout();
                                              controller.onInit();
                                              print("Thssdksflsjd s");
                                            }
                                          });
                                        },
                                        style: ButtonStyle(
                                          side: WidgetStateProperty.all(
                                              BorderSide(
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
                                    SizedBox(
                                      height: 19.h,
                                    ),
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
                                          side: WidgetStateProperty.all(
                                              BorderSide(
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
                                            CustomTextView(LocaleKeys.logout.tr,
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
                              recognizer: TapGestureRecognizer()..onTap = () {
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
                              recognizer: TapGestureRecognizer()..onTap = () {
                                Get.to(() => const PrivacyPolicyScreen());
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
                    SizedBox(
                      width: 16.w,
                    ),
                  ],
                ),
                SizedBox(
                  height: 75.h,
                ),
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
                        LocaleKeys.yes.tr,
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

void launchExternalWeb(String url) async {
  final Uri webUrl = Uri.parse(url); // Replace with your profile URL
  if (await canLaunchUrl(webUrl)) {
    await launchUrl(webUrl);
  } else {
    throw 'Could not launch $webUrl';
  }
}

Widget notVerifiedUserCard(MypageController controller) {
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