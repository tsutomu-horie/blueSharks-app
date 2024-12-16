import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/year_filter_controller_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/GalleryScreenDetail/gallery_screen_detail.screen.dart';
import 'package:koto_blue_sharks/presentation/mypage/mypage.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';

import 'controllers/gallery.controller.dart';

class GalleryScreen extends GetView<GalleryController> {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GalleryController galleryController = Get.put(GalleryController());

    galleryController.selectedYear.value = "";

    if (Get.isRegistered<YearFilterController>()) {
      Get.find<YearFilterController>().reset();
    }

    galleryController.onSwitch(1, LocaleKeys.game.toUpperCase().tr);
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              DefaultHeaderTitleView(LocaleKeys.gallery.tr,
                  LocaleKeys.gallery_en.tr.toUpperCase()),
              Obx(() {
                if (galleryController.isLoading.value && galleryController.album.isEmpty) {
                  return SizedBox(height: 500.h, child: shimmer());
                } else {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          width: 343.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            // Background color
                            borderRadius: BorderRadius.circular(30),
                            // Rounded container
                            border:
                            Border.all(color: Colors.grey.shade300), // Outer border
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildToggleOption(LocaleKeys.game.tr.toUpperCase(), 1, galleryController),
                              SizedBox(
                                width: 8.w,
                              ),
                              Container(
                                width: 1.w,
                                height: 16.h,
                                color: BorderColor.primary,
                              ),
                              SizedBox(
                                width: 8.w,
                              ),
                              buildToggleOption(
                                  LocaleKeys.event_en.tr.toUpperCase(), 2, galleryController),
                              SizedBox(
                                width: 8.w,
                              ),
                              Container(
                                width: 1.w,
                                height: 16.h,
                                color: BorderColor.primary,
                              ),
                              SizedBox(
                                width: 8.w,
                              ),
                              buildToggleOption(LocaleKeys.other.tr.toUpperCase(), 3, galleryController),
                            ],
                          ),
                        ),
                      ),
                      YearFilter(
                        years: List.generate(DateTime.now().year - 2019 + 1,
                            (index) => DateTime.now().year - index),
                        // Generate year list dynamically
                        initialSelectedYear: 0,
                        selectedColor: BrandColor.main,
                        unselectedColor: Colors.grey.shade200,
                        selectedTextColor: Colors.white,
                        unselectedTextColor: TextColor.secondary,
                        onYearSelected: (selectedYear) {
                          // Handle year selection
                          if (selectedYear == 0) {
                            galleryController.selectedYear.value =
                            "";
                            galleryController.getGalleryList();
                            print("Selected Year: $selectedYear");
                          } else {
                            galleryController.selectedYear.value =
                            "$selectedYear";
                            galleryController.getGalleryList();
                            print("Selected Year: $selectedYear");
                          }
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Obx(() {
                          return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: galleryController.album.length,
                              itemBuilder: (BuildContext context, int index) =>
                                  Column(
                                    children: [
                                      SizedBox(
                                        height: 16.h,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Get.to(() =>
                                              GalleryScreenDetailScreen(
                                                  galleryController.album[index],
                                                  galleryController
                                                      .selectedName.value));
                                        },
                                        child: Stack(
                                          children: [
                                            AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: CustomImageView(
                                                  customFit: BoxFit.fitWidth,
                                                  radius: 12.r,
                                                  image: galleryController
                                                          .album[index].photo ??
                                                      ""),
                                            ),
                                            Positioned(
                                              bottom: 16.w,
                                              left: 16.w,
                                              right: 16.w,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8.w,
                                                                vertical: 4.h),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              BrandColor.main,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      24.r),
                                                        ),
                                                        child: CustomTextView(
                                                          galleryController
                                                              .selectedName
                                                              .value,
                                                          color: Colors.white,
                                                          type: TDSFontType
                                                              .labelMedium,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 8.w,
                                                      ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.r),
                                                            color:
                                                                Colors.white),
                                                        width: 4.w,
                                                        height: 4.w,
                                                      ),
                                                      SizedBox(
                                                        width: 8.w,
                                                      ),
                                                      FutureBuilder<String>(
                                                        future:
                                                            convertToJapaneseFormat(
                                                                galleryController
                                                                        .album[
                                                                            index]
                                                                        .date ??
                                                                    ""),
                                                        builder: (BuildContext
                                                                context,
                                                            AsyncSnapshot<
                                                                    String>
                                                                snapshot) {
                                                          if (snapshot.connectionState ==
                                                                  ConnectionState
                                                                      .waiting ||
                                                              snapshot
                                                                  .hasError) {
                                                            return const SizedBox();
                                                          } else {
                                                            return Row(
                                                              children: [
                                                                CustomTextView(
                                                                  snapshot
                                                                      .data!,
                                                                  color: Colors
                                                                      .white,
                                                                  type: TDSFontType
                                                                      .bodyTextMedium,
                                                                ),
                                                              ],
                                                            ); // Display the formatted date
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 6.h,
                                                  ),
                                                  CustomTextView(
                                                    galleryController.album[index]
                                                            .name ??
                                                        "",
                                                    type:
                                                        TDSFontType.titleLarge,
                                                    color: Colors.white,
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 16.h,
                                      ),
                                    ],
                                  ));
                        }),
                      ),
                    ],
                  );
                }
              }),
              SizedBox(height: 24.h,),
            ],
          ),
        ));
  }

  Widget buildToggleOption(String text, int index, GalleryController galleryController) {
    return GestureDetector(
      onTap: () => galleryController.onSwitch(index, text),
      child: Obx(() {
        bool isSelected = galleryController.selectedIndex.value == index;
        return Container(
          width: 99.67.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: isSelected ? BrandColor.main : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: CustomTextView(
              text,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? TextColor.inverse : TextColor.secondary),
            ),
          ),
          // child: Text(
          //   text,
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.bold,
          //     color: isSelected ? Colors.white : Colors.grey.shade700,
          //   ),
          // ),
        );
      }),
    );
  }
}
