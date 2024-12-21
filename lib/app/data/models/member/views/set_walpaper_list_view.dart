import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/data/models/member/views/player_card_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/register_email.screen.dart';
import 'package:koto_blue_sharks/presentation/wallpaper_set_player/controllers/wallpaper_set_player.controller.dart';
import 'package:koto_blue_sharks/utils/String+extensions.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class SetWalpaperListView extends GetView {
  const SetWalpaperListView(this.memberController,
      {super.key, required this.isSetWallpaper, required this.selectedPlayerLink, this.onSet});

  final WallpaperSetPlayerController memberController;
  final bool isSetWallpaper;
  final String selectedPlayerLink;
  final Function(String, String)? onSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          List<CategorizedPlayerGroup> groupedPlayers =
              memberController.wallpaperList;

          for (var group in groupedPlayers) {
            memberController.addGroupKey(group.categoryTitle);
          }

          groupedPlayers = groupedPlayers
              .where((group) => group.categoryTitle != LocaleKeys.staff.tr)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedPlayers.map((group) {
              return Column(
                key: memberController.groupKeys[group.categoryTitle],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: BrandColor.background,
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    child: CustomTextView(
                      group.categoryTitle,
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: TextColor.inverse),
                      align: TextAlign.center,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.playerGroups.length,
                    itemBuilder: (context, index) {
                      final MemberGroup playerGroup = group.playerGroups[index];

                      // Show the position title (e.g. Prop, Scrumhalf, etc.)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: BrandColor.main,
                            padding: EdgeInsets.symmetric(
                                vertical: 12.h, horizontal: 16.w),
                            child: Text(
                              playerGroup.title.toLowerCase() == "number8" ? "No. 8" : playerGroup.title.capitalizeText(),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Grid to show players of the current position group
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 16.h),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                // Number of columns in the grid
                                childAspectRatio: 0.75,
                                // Adjust the aspect ratio of the grid items
                                mainAxisSpacing: 12.w,
                                crossAxisSpacing: 12.w,
                              ),
                              itemCount: playerGroup.players.length,
                              itemBuilder: (context, playerIndex) {
                                final player = playerGroup.players[playerIndex];
                                return PlayerCardView(
                                    player,
                                    playerGroup.title,
                                    onSet,
                                    memberController.mediaProvider,
                                    true, (postImage, position) {
                                  showSetWallpaper(
                                    memberController,
                                    context,
                                    postImage,
                                    player.playerNameKatakana ?? "",
                                    player.title.rendered,
                                    position,
                                    player.link,
                                    selectedPlayerLink,
                                    onSet,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

void showPlayerFilterBottomSheet(
    WallpaperSetPlayerController memberController, BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(16.w),
        height: 142.h,
        // Fixed height for the bottom sheet
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
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: memberController.playerCategory.length,
                itemBuilder: (context, index) {
                  final item = memberController.playerCategory[index];
                  return InkWell(
                    onTap: () {
                      // memberController.onSelectPosition(item);
                      Get.back();
                      memberController.scrollToGroup(
                          memberController.playerCategoryFull[index]);
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          height: 44.h,
                          child: Row(
                            children: [
                              Flexible(
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: CustomTextView(
                                        item,
                                        type: TDSFontType.labelLarge,
                                      ))),
                            ],
                          ),
                        ),
                        if (index != memberController.playerCategory.length - 1)
                          Container(
                            height: 1.h,
                            color: BorderColor.primary,
                          ),
                      ],
                    ),
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

void showSetWallpaper(
    WallpaperSetPlayerController memberController,
    BuildContext context,
    String image,
    String playerNameKatana,
    String playerNameKanji,
    String playerPosition,
    String playerUrl,
    String selectedUrl,
    Function(String, String)? onSet) {
  print("show sheet $playerUrl, $selectedUrl");
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        height: 292.h, // Fixed height for the bottom sheet
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 44.h,
              child: Row(
                children: [
                  Flexible(
                      child: SizedBox(
                          width: double.infinity,
                          child: CustomTextView(
                            LocaleKeys.set_wallpaper_title3.tr,
                            type: TDSFontType.titleMedium,
                          ))),
                ],
              ),
            ),
            SizedBox(
              height: 20.h,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: BorderColor.subtle, width: 1)),
              child: Row(
                children: [
                  image != ''
                      ? SizedBox(
                          width: 81.w,
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: CustomImageView(
                              image: image,
                              radius: 4.r,
                              customFit: BoxFit.fitHeight,
                            ),
                          ))
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                  SizedBox(
                    width: 12.w,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextView(
                            playerNameKatana,
                            type: TDSFontType.labelMedium,
                            color: TextColor.secondary,
                          ),
                          CustomTextView(
                            playerNameKanji,
                            type: TDSFontType.titleSmall,
                            color: TextColor.secondary,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 12.h,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 4.h, horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: BrandColor.surface,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: CustomTextView(playerPosition.capitalizeText(),
                            type: TDSFontType.labelMedium,
                            color: BrandColor.main),
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(
              height: 28.h,
            ),
            Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: 48.h,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(BorderSide(
                                color: BrandColor
                                    .main) // Set your desired color here
                            ),
                      ),
                      onPressed: () {
                        if (selectedUrl == playerUrl) {
                          if (onSet != null) {
                            onSet("", "");
                          }
                          Get.back();
                        } else {
                          Get.back();
                        }
                      },
                      child: CustomTextView(
                        selectedUrl == playerUrl ? LocaleKeys.unselect.tr : LocaleKeys.cancel.tr,
                        color: BrandColor.main,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 16.w,
                ),
                Flexible(
                  child: SizedBox(
                    height: 48.h,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColor.main,
                      ),
                      onPressed: () {
                        if (onSet != null) {
                          onSet(
                              "$playerNameKatana $playerNameKanji", playerUrl);
                          Get.back();
                        } else {
                          Get.to(() => RegisterEmailScreen(
                              playerUrl, "$playerNameKatana $playerNameKanji"));
                        }
                      },
                      child: CustomTextView(
                        LocaleKeys.confirm.tr,
                        color: BrandColor.content,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}

class FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WallpaperSetPlayerController memberController;
  final BuildContext context;

  FilterHeaderDelegate(this.memberController, this.context);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: BackgroundColor.primary,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: OutlinedButton(
        onPressed: () {
          showPlayerFilterBottomSheet(memberController, context);
        },
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 12.w),
            SvgPicture.asset(
              "assets/vectors/ic_user-search.svg",
              width: 20.w,
              height: 20.h,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return CustomTextView(
                    memberController.selectedPosition.value,
                    type: TDSFontType.bodyTextMedium,
                    color: TextColor.primary,
                  );
                }),
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.keyboard_arrow_down, size: 20.w),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 62.3; // Explicit height
  @override
  double get minExtent => 62.3; // Explicit height
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

