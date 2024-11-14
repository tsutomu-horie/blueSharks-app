import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/delete_account_confirmation.controller.dart';

class DeleteAccountConfirmationScreen
    extends GetView<DeleteAccountConfirmationController> {
  const DeleteAccountConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeleteAccountConfirmationController deleteAccountConfirmationController = Get
        .put(DeleteAccountConfirmationController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: CustomTextView(
          LocaleKeys.delete_account_title.tr, color: Colors.white,),
        backgroundColor: BrandColor.main,
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
            child: Column(
              children: [
                SizedBox(height: 20.h,),
                CustomTextView(LocaleKeys.delete_account_desc1.tr,
                  type: TDSFontType.bodyTextMedium,
                  color: TextColor.secondary,),
                SizedBox(height: 24.h,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: CustomTextView(
                      LocaleKeys.delete_account_desc2.tr,
                      type: TDSFontType.labelLarge,
                      color: TextColor.secondary,)),
                    CustomTextView("*", type: TDSFontType.labelLarge,
                      color: TextColor.error,),
                  ],
                ),
                TextFormField(
                  controller: deleteAccountConfirmationController
                      .emailTextFieldController,
                  onChanged: (value) {
                    deleteAccountConfirmationController.emailText.value = value;
                  },
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
                    hintText: "",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Obx(() {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: deleteAccountConfirmationController.emailText
                    .value == "消去" ||
                    deleteAccountConfirmationController.emailText.value ==
                        "delete" ? TextColor.error : BackgroundColor.disabled,
              ),
              onPressed: () {
                showDeleteAccountBottomSheet(context, deleteAccountConfirmationController.onDeleteAccount);
              },
              child: CustomTextView(
                LocaleKeys.delete_account_button.tr,
                color: Colors.white,
              ),
            );
          })
      ),

    );
  }

  void showDeleteAccountBottomSheet(BuildContext context, Function onDelete) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle at the top
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24.h),
              SvgPicture.asset("assets/vectors/ic_error.svg", width: 40.w, height: 40.h,),
              SizedBox(height: 16.h),
              // Title
              CustomTextView(
                LocaleKeys.delete_account_confirmation_title.tr,
                style: TDSTypography.titleMedium,
                color: TextColor.primary,
              ),
              SizedBox(height: 8.h),
              // Subtitle
              CustomTextView(
                LocaleKeys.delete_account_confirmation_message.tr,
                style: TDSTypography.bodyTextMedium,
                color: TextColor.tertiary,
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TextColor.error,
                          side: BorderSide(color: TextColor.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        child: CustomTextView(
                          'キャンセル',
                          color: TextColor.error,
                          style: TDSTypography.titleMedium,
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  SizedBox(width: 16.w,),
                  Flexible(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(120.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () {
                          onDelete();
                        },
                        child: CustomTextView(
                          '消去',
                          style: TDSTypography.titleMedium,
                        ),
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
