import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/html_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:koto_blue_sharks/utils/map_id_to_categories.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/detail_info.controller.dart';

class DetailInfoScreen extends GetView<DetailInfoController> {
  const DetailInfoScreen(this.onOpenDetail, this.selectedPost, {super.key});

  final Function() onOpenDetail;
  final Post? selectedPost; // Track the selected topic ID

  @override
  Widget build(BuildContext context) {
    final DetailInfoController controller = Get.put(DetailInfoController());

    if (selectedPost != null) {
      final categoryData = mapCategoryIdsToNames(selectedPost!.categories);

      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFAFAFA),
                child: DefaultHeaderTitleView(
                  LocaleKeys.topics.tr,
                  LocaleKeys.topics_en.tr.toUpperCase(),
                  onBack: () {
                    onOpenDetail();
                  },
                ),
              ),
              Container(
                height: 1,
                color: BorderColor.primary,
              ),
              Container(
                color: BackgroundColor.primary,
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                child: Column(
                  children: [
                    Column(
                      children: [
                        FutureBuilder<String>(
                          future: convertToJapaneseFormat(selectedPost!.date),
                          // Call the async function
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                snapshot.hasError) {
                              return const SizedBox();
                            } else {
                              return Row(
                                children: [
                                  CustomTextView(snapshot.data!),
                                ],
                              ); // Display the formatted date
                            }
                          },
                        ),
                        SizedBox(
                          height: 8.h,
                        ),
                        Row(
                          children: categoryData.map((element) {
                            return Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.h, horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: BrandColor.background,
                                    borderRadius: BorderRadius.circular(6.r),
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
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        SizedBox(
                          height: 8.h,
                        ),
                        CustomTextView(
                          selectedPost!.title.rendered,
                          type: TDSFontType.titleMedium,
                          color: TextColor.primary,
                        ),
                      ],
                    ),
                    // SizedBox(
                    //   height: 24.h,
                    // ),
                    // FutureBuilder<String>(
                    //   future: controller.getNewsImage("${selectedPost!.id}"),
                    //   builder: (context, snapshot) {
                    //     if (snapshot.connectionState ==
                    //         ConnectionState.waiting) {
                    //       return Padding(
                    //         padding: EdgeInsets.only(right: 12.w),
                    //         child: shimmer(),
                    //       );
                    //     } else if (snapshot.hasError) {
                    //       return const SizedBox();
                    //     } else {
                    //       final postImage = snapshot.data ??
                    //           'https://example.com/placeholder.png'; // Fallback in case of null
                    //
                    //       return Row(
                    //         children: [
                    //           Flexible(
                    //             child: AspectRatio(
                    //               aspectRatio: 1.7,
                    //               child: SizedBox(
                    //                 width: double.infinity,
                    //                 child: CustomImageView(
                    //                   image: postImage,
                    //                   radius: 12.r,
                    //                 ),
                    //               ),
                    //             ),
                    //           ),
                    //         ],
                    //       );
                    //     }
                    //   },
                    // ),
                    SizedBox(
                      height: 24.h,
                    ),
                    HtmlWidget(
                      selectedPost!.content.rendered,
                      customStylesBuilder: (element) {
                        if (element.localName == 'figure' ||
                            element.localName == 'div') {
                          return {
                            'margin': '0',
                            'padding': '0',
                          };
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h,),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.all(BorderSide(
                                  color: BrandColor
                                      .main) // Set your desired color here
                              ),
                        ),
                        onPressed: () {
                          onOpenDetail();
                        },
                        child: CustomTextView(
                          LocaleKeys.back_to_list.tr,
                          type: TDSFontType.titleSmall,
                          color: BrandColor.main,
                        ),
                      ),
                    )
                    // ElevatedButton(onPressed: (){
                    // },
                    //     style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    //     child: CustomTextView(LocaleKeys.back_to_list.tr))
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox();
    }
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: BorderColor.disabled,
      highlightColor: BorderColor.subtle,
      child: Container(
        width: 320.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: BorderColor.disabled,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }
}
