import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_switch_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/FanClubConfirmation/controllers/fan_club_confirmation.controller.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

void editProfileBottomSheet(
    FanClubConfirmationController fanclubController, BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.h),
        height: 524.h, // Fixed height for the bottom sheet
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            Center(
                child: Container(
              width: 48.w,
              height: 4.h,
              color: BorderColor.primary,
            )),
            SizedBox(height: 10.h),
            CustomTextView(
              LocaleKeys.edit_information_title.tr,
              type: TDSFontType.titleMedium,
              color: TextColor.secondary,
            ),
            SizedBox(height: 10.h),
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
            SizedBox(
              height: 40.h,
              child: TextFormField(
                validator: (value) {
                  if (value!.isEmpty ||
                      !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                          .hasMatch(value)) {
                    return 'Invalid email';
                  }
                  return null;
                },
                controller: fanclubController.emailController,
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
            ),
            SizedBox(
              height: 4.h,
            ),
            CustomTextView(
              LocaleKeys.edit_information_email_warning.tr,
              type: TDSFontType.bodyTextMedium,
              color: TextColor.secondary,
            ),
            SizedBox(
              height: 12.h,
            ),
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
              validator: (value) {
                if (value!.isEmpty) {
                  return 'ID cannot empty';
                }
                return null;
              },
              controller: fanclubController.idController,
              decoration: InputDecoration(
                errorMaxLines: 1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  // Custom border radius
                  borderSide: BorderSide(
                    color:
                        BorderColor.secondary, // Border color when not focused
                  ),
                ),
                hintStyle: TextStyle(
                  color: TextColor.placeholder, // Custom hint color
                ),
                contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
                hintText: "**ここにIDを入力してください",
              ),
            ),
            SizedBox(
              height: 12.h,
            ),
            Row(
              children: [
                CustomTextView(
                  LocaleKeys.wallpaper_setting.tr,
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
            OutlinedButton(
              onPressed: () {},
              style: ButtonStyle(
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12.w,
                  ),
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomTextView(
                        fanclubController.playerNameController.text,
                        type: TDSFontType.bodyTextMedium,
                        color: TextColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20.w,
                  ),
                  SizedBox(
                    width: 12.w,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 12.h,
            ),
            Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: BorderColor.primary)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTextView(LocaleKeys.notice.tr),
                  SizedBox(
                      height: 20.h,
                      child: Obx(() {
                        return CustomSwitch(
                            value: fanclubController.isSelectNotificaiton.value,
                            onChanged: (value) {
                              print("value $value");
                              fanclubController.isSelectNotificaiton.value =
                                  value;
                            });
                      }))
                ],
              ),
            ),
            SizedBox(
              height: 12.h,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
                onPressed: () {
                  fanclubController.updateProfile();
                },
                child: CustomTextView(
                  LocaleKeys.next.tr,
                  color: BrandColor.content,
                ),
              ),
            ),
            SizedBox(
              height: 16.h,
            ),
          ],
        ),
      );
    },
  );
}
