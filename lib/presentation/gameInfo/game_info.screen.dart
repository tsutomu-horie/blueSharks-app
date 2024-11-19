import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/match/views/match_item_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/MatchDetail/match_detail.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';
import 'package:shimmer/shimmer.dart';

import 'controllers/game_info.controller.dart';

class GameInfoScreen extends GetView<GameInfoController> {
  const GameInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameInfoController gameInfoController = Get.put(GameInfoController());

    return Scaffold(
        backgroundColor: BackgroundColor.primary,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  color: const Color(0xFFFAFAFA),
                  child: DefaultHeaderTitleView(LocaleKeys.game_info.tr,
                      LocaleKeys.game_info_en.tr.toUpperCase())),
              Container(
                height: 1.h,
                color: BorderColor.primary,
              ),
              Container(
                color: BackgroundColor.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                child: OutlinedButton(
                  onPressed: () {
                    showYearFilterBottomSheet(context);
                  },
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
                      SvgPicture.asset(
                        "assets/vectors/calendar-search.svg",
                        width: 20.w,
                        height: 20.h,
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      Flexible(
                        child: SizedBox(
                          width: double.infinity,
                          child: Obx(() {
                            if (gameInfoController.isLoading.value) {
                              return SizedBox(
                                height: 20.h,
                                child: shimmer(),
                              );
                            } else {
                              return CustomTextView(
                                gameInfoController.selectedYear.value,
                                type: TDSFontType.bodyTextMedium,
                                color: TextColor.primary,
                              );
                            }
                          }),
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
              ),
              SizedBox(
                height: 20.h,
              ),
              Obx(() {
                if (gameInfoController.isLoading.value) {
                  return Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: BorderColor.disabled,
                        highlightColor: BorderColor.subtle,
                        child: Container(
                          width: 350.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            color: BorderColor.disabled,
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.r)),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 16.h,
                      ),
                      Shimmer.fromColors(
                        baseColor: BorderColor.disabled,
                        highlightColor: BorderColor.subtle,
                        child: Container(
                          width: 350.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            color: BorderColor.disabled,
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.r)),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 16.h,
                      ),
                    ],
                  );
                } else {
                  return ListView.builder(
                      shrinkWrap: true,
                      reverse: true,
                      // Use shrinkWrap for smooth scrolling
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.listMatch.value.length,
                      itemBuilder: (context, index) {
                        final data = controller.listMatch.value[index];
                        final gameDate = data.custom_field.gameDate ?? [];
                        final gameTime = data.custom_field.gameTime ?? [];
                        final location = data.custom_field.location ?? [];

                        print("list ${controller.listMatch.value[index]}");
                        final gameSerial =
                            data.custom_field.game_serial ?? [""];

                        final matchStatus = getStatusMatch(data.custom_field);
                        final date = gameDate.isNotEmpty
                            ? convertJapaneseDate(gameDate.first)
                            : {'formattedDate': "", "dayOfWeek": ""};

                        print("load success ${date['formattedDate']}");

                        if (gameDate.isNotEmpty &&
                            gameTime.isNotEmpty &&
                            location.isNotEmpty) {
                          return FutureBuilder<Map<String, String>>(
                            future: getAdditionalInfo(
                                gameInfoController.mediaProvider,
                                gameInfoController.apiProvider,
                                matchStatus["opponentLogo"],
                                gameSerial.first),
                            // Wait for the image URL to resolve
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  child: shimmer(),
                                );
                              } else if (snapshot.hasError) {
                                return Padding(
                                  padding: EdgeInsets.only(right: 12.w),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(2.r),
                                          color: BorderColor.primary),
                                      width: 320.w,
                                      height: 200.h,
                                      child: const Icon(Icons.warning)),
                                );
                              } else {
                                // Use the actual image URL returned from the Future
                                final opponentLogo = snapshot.data?['image'] ??
                                    'https://example.com/placeholder.png'; // Fallback in case of null

                                return MatchItemView(
                                  matchStatus:
                                      snapshot.data?['matchStatus'] ?? "",
                                  title: data.title.rendered,
                                  location: location.first,
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
                                  gameResult:
                                      data.custom_field.game_result?.first,
                                  team1Score:
                                      data.custom_field.team_score_1?.first,
                                  team2Score:
                                      data.custom_field.team_score_2?.first,
                                  onTap: () {
                                    Get.to(MatchDetailScreen(
                                      data,
                                      homeStatus:
                                          snapshot.data?['matchStatus'] ?? "",
                                    ));
                                  },
                                );
                              }
                            },
                          );
                        } else {
                          return Text(
                              'Missing match data'); // Handle cases where fields are missing
                        }
                      });
                }
              }),
              SizedBox(height: 24.h,),
            ],
          ),
        ));
  }

  void showYearFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          height: 284.h, // Fixed height for the bottom sheet
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              Center(
                  child: Container(
                width: 48.w,
                height: 4.w,
                color: BorderColor.primary,
              )),
              SizedBox(height: 16.h),
              Expanded(
                // Wrap ListView with Expanded to avoid unbounded height
                child: ListView.builder(
                  itemCount: controller.matchCategory.value.length,
                  itemBuilder: (context, index) {
                    final item = controller.matchCategory.value[index];
                    return Column(
                      children: [
                        SizedBox(
                          height: 56.h,
                          child: Row(
                            children: [
                              Flexible(
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: CustomTextView(
                                        item.name,
                                        type: TDSFontType.labelLarge,
                                      ))),
                              SizedBox(
                                width: 8.w,
                              ),
                              OutlinedButton(
                                  onPressed: () {
                                    controller.selectYear(
                                        controller.matchCategory.value[index]);
                                    Get.back();
                                  },
                                  child: CustomTextView(
                                    LocaleKeys.select.tr,
                                    type: TDSFontType.labelLarge,
                                    color: BrandColor.main,
                                  ))
                            ],
                          ),
                        ),
                        Container(
                          height: 1.h,
                          color: BorderColor.primary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
