import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/register_member_fanclub.controller.dart';

class RegisterMemberFanclubScreen
    extends GetView<RegisterMemberFanclubController> {
  const RegisterMemberFanclubScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();

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
                    validator: (value) {
                      if (value!.isEmpty ||
                          !RegExp(r'\b[\w.-]+@[\w.-]+\.\w{2,4}\b')
                              .hasMatch(value)) {
                        return 'Invalid email';
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
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}
