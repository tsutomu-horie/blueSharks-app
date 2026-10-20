import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/menu.controller.dart';


class MenuScreen extends GetView<MenuListController> {
  const MenuScreen(this.onOpenDetail, {super.key});

  final Function(Post) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final MenuListController controller = Get.put(MenuListController());

    controller.onInit();

    final List<String> tabs = [
      'Topics',
      'Game Info',
      'Player',
      'Gallery',
      'Team',
      'Partner',
      "",
      ""
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: PrimaryColor.hover,
        // Replace with your BrandColor.hover
        toolbarHeight: 44.h,
        titleSpacing: 0,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (index) {
              if (index == 6) {
                return IconButton(
                  icon: Icon(IconsaxPlusLinear.instagram, color: BrandColor.border, size: 20.w,), onPressed: () { controller.launchInstagram(); },
                );
              } else if (index == 7) {
                return IconButton(
                  icon: SvgPicture.asset("assets/vectors/ic_x_twitter.svg"), onPressed: () { controller.launchTwitter(); },
                );
              } else {
                return InkWell(
                  onTap: () => {
                    if (index == 5) {
                      controller.launchPartner()
                    } else if (index == 4) {
                      controller.launchTeam()
                    } else
                      {
                        controller.changeTab(index)
                      }
                  },
                  child: Obx(() {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: controller.selectedIndex.value == index
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.0, // Underline thickness
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: controller.selectedIndex.value == index
                                  ? Colors.white
                                  : PrimaryColor
                                  .border, // Selected/Unselected Color
                            ),
                          ),
                          if (index == 5 || index == 4)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: SvgPicture.asset("assets/vectors/ic_external_link.svg", width: 16.w, height: 16.h,),
                            )
                        ],
                      ),
                    );
                  }),
                );
              }
            }),
          ),
        ),
      ),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged, // Sync tab with page
        children: [
          TopicListScreen(
            onOpenDetail: (value) {
              onOpenDetail(value);
            },
          ),
          const MatchListScreen(),
          const PlayerListScreen(null),
          const GalleryScreen(),
        ],
      ),
    );
  }
}
