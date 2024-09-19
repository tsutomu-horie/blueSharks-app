import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/match/views/match_item_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/home.controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

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
            final nextMatchData = controller.threeLatestMatch.value;

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
                    final matchStatus =
                        controller.getStatusMatch(element.custom_field);
                    final date = convertJapaneseDate(
                        element.custom_field.gameDate.first);

                    // Ensure gameDate and other fields are lists and check their contents
                    if (element.custom_field.gameDate.isNotEmpty &&
                        element.custom_field.gameTime.isNotEmpty &&
                        element.custom_field.location.isNotEmpty) {
                      return FutureBuilder<String>(
                        future:
                            controller.getImage(matchStatus["opponentLogo"]),
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
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2.r), color: BorderColor.primary),
                                  width: 320.w,
                                  height: 200.h,
                                  child: const Icon(Icons.warning)
                              ),
                            );
                          } else {
                            // Use the actual image URL returned from the Future
                            final opponentLogo = snapshot.data ??
                                'https://example.com/placeholder.png'; // Fallback in case of null

                            return MatchItemView(
                              isHome: matchStatus["isHome"],
                              title: element.title.rendered,
                              location: element.custom_field.location.first,
                              // Ensure location is a valid list and access its first item
                              date: date['formattedDate'] ?? "",
                              // Format the date
                              day: date['dayOfWeek'] ?? "",
                              // Get the day of the week
                              time: element.custom_field.gameTime.first,
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
          borderRadius:
          BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }
}
