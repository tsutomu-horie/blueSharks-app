import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

void errorDialogView(BuildContext context, String title, String? message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Dialog can't be dismissed by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              SvgPicture.asset("assets/vectors/ic_error.svg"),
              SizedBox(height: 16.h),
              // Error Message
              CustomTextView(
                title,
                type: TDSFontType.titleMedium,
                color: TextColor.primary,
                align: TextAlign.center,
              ),
              if (message != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: Colors.red,
                      child: CustomTextView(
                        title,
                        type: TDSFontType.titleMedium,
                        color: TextColor.primary,
                        align: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 8.h,)
                  ],
                ),
              SizedBox(height: 24.h),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColor.main, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: CustomTextView(
                    LocaleKeys.close_dialog.tr,
                    type: TDSFontType.titleSmall,
                    color: Colors.white,
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
