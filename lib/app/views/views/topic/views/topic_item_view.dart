import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/presentation/detailInfo/detail_info.screen.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class TopicItemView extends GetView {
  const TopicItemView(this.onTap,
      {super.key,
      required this.title,
      required this.date,
      required this.categories,
      this.image});

  final String title;
  final String date;
  final String? image;
  final List<String> categories;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        print("tapp TopicItemView ");
        onTap();
        // Get.to(() => DetailInfoScreen());
      },
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16.w,
              ),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: const Color(0xFFFAFAFA),
                      border: Border.all(color: BorderColor.primary)),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.h, horizontal: 12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextView(
                              formatDate(date),
                              type: TDSFontType.labelLarge,
                              color: TextColor.secondary,
                            ),
                            SizedBox(
                              height: 4.h,
                            ),
                            CustomTextView(
                              title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: TextColor.primary,
                                  fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                      image != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12.r),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 2.144,
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: CustomImageView(
                                            image: image!,
                                            radius: 0.r,
                                          ),
                                        ),
                                        Container(
                                            decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.center,
                                          colors: [
                                            Colors.white,
                                            Colors.transparent,
                                          ],
                                        )))
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12.w,
                                  left: 12.w,
                                  child: Row(
                                    children: categories.map((element) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 4.h, horizontal: 8.w),
                                              decoration: BoxDecoration(
                                                color: BrandColor.background,
                                                borderRadius:
                                                    BorderRadius.circular(24.r),
                                              ),
                                              child: CustomTextView(
                                                element,
                                                style: TextStyle(
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 8.w,
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: EdgeInsets.only(
                                  top: 4.h,
                                  bottom: 16.h,
                                  left: 12.w,
                                  right: 12.w),
                              child: SizedBox(
                                height: 22.h,
                                child: Row(
                                  children: categories.map((element) {
                                    return Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 4.h, horizontal: 8.w),
                                          decoration: BoxDecoration(
                                            color: BrandColor.background,
                                            borderRadius:
                                                BorderRadius.circular(24.r),
                                          ),
                                          child: CustomTextView(
                                            element,
                                            style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 8.w,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            )
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
            height: 8.h,
          ),
        ],
      ),
    );
  }

  String formatDate(String dateString) {
    // Parse the incoming date string
    DateTime parsedDate = DateTime.parse(dateString);

    // Format the parsed date to the desired format
    DateFormat formatter = DateFormat('yyyy.MM.dd');
    String formattedDate = formatter.format(parsedDate);

    return formattedDate;
  }
}
