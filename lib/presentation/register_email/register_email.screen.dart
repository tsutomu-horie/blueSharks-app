import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/register_email.controller.dart';

class RegisterEmailScreen extends GetView<RegisterEmailController> {
  const RegisterEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
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
        bottomNavigationBar: Container(
          height: 162.h,
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Flexible(
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
                    onPressed: () {
                    },
                    child: CustomTextView(LocaleKeys.send.tr, color: BrandColor.content,),

                  ),
                ),
              ),

              SizedBox(height: 12.h,),
              Flexible(
                child: Container(
                  width: double.infinity,
                  child:OutlinedButton(
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(BorderSide(
                          color: BrandColor
                              .main) // Set your desired color here
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    child: CustomTextView(LocaleKeys.cancel.tr, color: BrandColor.main,),

                  ),
                ),
              ),
            ],
          ),

        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextView(
                    LocaleKeys.register_email_title.tr,
                    type: TDSFontType.headlineSmall,
                    color: BrandColor.main,
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  CustomTextView(
                    LocaleKeys.register_email_desc.tr,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.secondary,
                  ),
                  SizedBox(
                    height: 24.h,
                  ),
                  CustomTextView(
                    LocaleKeys.email.tr,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.secondary,
                  ),
                  SizedBox(
                    height: 4.h,
                  ),
                  SizedBox(
                    height: 40.h,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r), // Custom border radius
                          borderSide: BorderSide(
                            color: BorderColor.secondary, // Border color when not focused
                          ),
                        ),
                        hintStyle: TextStyle(
                          color: TextColor.placeholder, // Custom hint color
                        ),
                        hintText: LocaleKeys.email_placeholder
                            .trParams({"example": "jack@email.com"}),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 4.h,
                  ),
                  CustomTextView(
                    LocaleKeys.email_warning.tr,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.secondary,
                  ),
                  SizedBox(
                    height: 24.h,
                  ),
                  const Divider(),
                  SizedBox(
                    height: 24.h,
                  ),
                  SizedBox(
                      width: double.infinity,
                      child: CustomTextView(
                        LocaleKeys.already_have_account.tr,
                        type: TDSFontType.bodyTextMedium,
                        color: TextColor.secondary,
                        align: TextAlign.center,
                      )),
                  SizedBox(
                    height: 4.h,
                  ),
                  SizedBox(
                      width: double.infinity,
                      child:TextButton(onPressed: () {  },
                      child: CustomTextView(
                        LocaleKeys.login_now.tr,
                        color: BrandColor.main,
                        align: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          decoration: TextDecoration.underline
                        ),
                      ) ,)
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
