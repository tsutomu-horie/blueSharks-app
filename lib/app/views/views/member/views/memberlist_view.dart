import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/data/models/member/views/player_card_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/member/controllers/member.controller.dart';
import 'package:koto_blue_sharks/presentation/register/register_email/register_email.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

class MemberlistView extends GetView {
  const MemberlistView(this.memberController,
      {super.key, required this.isSetWallpaper, this.onSet});

  final MemberController memberController;
  final bool isSetWallpaper;
  final Function(String, String)? onSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: BackgroundColor.primary,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: OutlinedButton(
            onPressed: () {
              showPlayerFilterBottomSheet(memberController, context);
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
                  "assets/vectors/ic_user-search.svg",
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
                      return CustomTextView(
                        memberController.selectedPosition.value,
                        type: TDSFontType.bodyTextMedium,
                        color: TextColor.primary,
                      );
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
        Obx(() {
          List<CategorizedPlayerGroup> groupedPlayers = memberController
              .groupPlayersByCategory(memberController.categoryPlayers);

          if (isSetWallpaper) {
            groupedPlayers = groupedPlayers
                .where((group) => group.categoryTitle != LocaleKeys.staff.tr)
                .toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedPlayers.map((group) {
              return Column(
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
                              playerGroup.title,
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
                                return PlayerCardView(player, playerGroup.title, onSet, memberController.mediaProvider, false, (postImage, position){
                                  memberController.navigateToMemberDetail(player);
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

  void showPlayerFilterBottomSheet(
      MemberController memberController, BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        if (isSetWallpaper) {
          memberController.playerCategory.remove(LocaleKeys.staff.tr);
        }
        return Container(
          padding: EdgeInsets.all(16.w),
          height: isSetWallpaper ? 132.h : 190.h,
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
                        memberController.selectedPosition(item);
                        Get.back();
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
                          if (index !=
                              memberController.playerCategory.length - 1)
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

}
