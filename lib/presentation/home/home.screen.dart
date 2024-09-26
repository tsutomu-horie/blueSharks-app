import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/match/views/match_item_view.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/video_thumbnail_view.dart';
import 'package:koto_blue_sharks/app/views/views/topic/views/topic_item_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:koto_blue_sharks/utils/map_id_to_categories.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/home.controller.dart';

class HomeScreen extends GetView<MainController> {
  const HomeScreen(this.onOpenDetail, this.navigateToInfoList, {super.key});

  final Function(Post) onOpenDetail;
  final Function() navigateToInfoList;

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.put(HomeController());

    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
        children: [
          AspectRatio(
            aspectRatio: 9 / 9.3,
            child: Container(
              color: Colors.red,
            ),
          ),
          DefaultHeaderTitleView(
              LocaleKeys.next_match.tr, LocaleKeys.next_match_en.tr),
          Obx(() {
            // Access the observable list value directly
            final nextMatchData = homeController.threeLatestMatch.value;

            if (nextMatchData.isEmpty) {
              return Text(
                  'No match data available'); // Show a message if the list is empty
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Set scrolling direction to horizontal
              child: Padding(
                padding: EdgeInsets.only(left: 12.w, top: 20.h, bottom: 20.h),
                child: Row(
                  children: nextMatchData.map((element) {
                    final gameDate = element.custom_field.gameDate ?? [];
                    final gameTime = element.custom_field.gameTime ?? [];
                    final location = element.custom_field.location ?? [];

                    final matchStatus = homeController.getStatusMatch(element.custom_field);
                    final date = convertJapaneseDate(gameDate.first);


                    // Ensure gameDate and other fields are lists and check their contents
                    if (gameDate.isNotEmpty && gameTime.isNotEmpty && location.isNotEmpty) {
                      return FutureBuilder<String>(
                        future:
                        homeController.getImage(matchStatus["opponentLogo"]),
                        // Wait for the image URL to resolve
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.only(right: 12.w),
                              child: shimmer(),
                            );
                          } else if (snapshot.hasError) {
                            return Padding(
                              padding: EdgeInsets.only(right: 12.w),
                              child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2.r),
                                      color: BorderColor.primary),
                                  width: 320.w,
                                  height: 200.h,
                                  child: const Icon(Icons.warning)),
                            );
                          } else {
                            // Use the actual image URL returned from the Future
                            final opponentLogo = snapshot.data ??
                                'https://example.com/placeholder.png'; // Fallback in case of null

                            return MatchItemView(
                              isHome: matchStatus["isHome"],
                              title: element.title.rendered,
                              location:location.first,
                              // Ensure location is a valid list and access its first item
                              date: date['formattedDate'] ?? "",
                              // Format the date
                              day: date['dayOfWeek'] ?? "",
                              // Get the day of the week
                              time: gameTime.first,
                              // Access the first time element
                              opponentLogo: opponentLogo,
                              // Use the resolved image URL
                              opponentName: matchStatus["opponentName"],
                            );
                          }
                        },
                      );
                    } else {
                      return Text(
                          'Missing match data'); // Handle cases where fields are missing
                    }
                  }).toList(), // Convert the Iterable to a List<Widget>
                ),
              ),
            );
          }),
          SizedBox(
            height: 40.h,
          ),
          Row(
            children: [
              SizedBox(
                width: 16.w,
              ),
              Flexible(
                child: Stack(
                  children: [
                    // The background image with border radius
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.asset(
                          "assets/images/img_banner_ticket.png",
                          fit: BoxFit
                              .cover, // Ensure the image covers the entire container
                        ),
                      ),
                    ),
                    // The overlaying container that also respects the border radius
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      // Apply the same borderRadius here
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 24.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          // Ensure the radius is applied
                          color: Colors.black.withOpacity(
                              0.5), // Optional: add some background overlay color
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 120.h,
                          // Set a fixed height for the Container
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                    "assets/vectors/app_logo_label.svg",
                                    width: 80.w,
                                    height: 13.h,
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    LocaleKeys.ticket_information.tr,
                                    style: TextStyle(
                                      color: TextColor.inverse,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(), // Spacer will push the button down
                              ElevatedButton.icon(
                                onPressed: () {},
                                label: CustomTextView(
                                  LocaleKeys.buy_ticket.tr,
                                  color: TextColor.primary,
                                  type: TDSFontType.labelMedium,
                                ),
                                icon: SvgPicture.asset(
                                  width: 14.w,
                                  "assets/vectors/ic_goods.svg",
                                  colorFilter: ColorFilter.mode(
                                      BrandColor.main, BlendMode.srcIn),
                                ),
                                style: const ButtonStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 16.w,
              ),
            ],
          ),
          DefaultHeaderTitleView(LocaleKeys.featured_topics.tr, LocaleKeys.featured_topics_en.tr),
          Obx(() {
            final data = homeController.topicsData.value;
            return Column(
              children: data.map((element) {
                return FutureBuilder<String>(
                  future: homeController.getNewsImage("${element.id}"),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: shimmer(),
                      );
                    } else if (snapshot.hasError) {
                      return TopicItemView(
                        (){
                          print("open ${element.id}");
                          onOpenDetail(element);
                        },
                        image: null,
                        date: element.date,
                        title: element.title.rendered,
                        categories: mapCategoryIdsToNames(element.categories),
                      );
                    } else {
                      final postImage = snapshot.data ??
                          'https://example.com/placeholder.png'; // Fallback in case of null

                      // Ensure that TopicItemView is returned
                      return TopicItemView(
                        (){
                          onOpenDetail(element);
                        },
                        image: postImage,
                        date: element.date,
                        title: element.title.rendered,
                        categories: mapCategoryIdsToNames(element.categories),
                      );
                    }
                  },
                );
              }).toList(), // Convert the Iterable to a List<Widget>
            );
          }),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Flexible(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    navigateToInfoList();
                  },
                  child: CustomTextView(
                    LocaleKeys.see_more.tr,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.primary,
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1.h, color: BorderColor.primary,),
          DefaultHeaderTitleView(LocaleKeys.promotion_video.tr, LocaleKeys.promotion_video_en.tr),
          const VideoThumbnailView(),

        ],
      )),
    );
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
