import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/presentation/ListTopics/list_topics.screen.dart';
import 'package:koto_blue_sharks/presentation/gameInfo/game_info.screen.dart';
import 'package:koto_blue_sharks/presentation/member/member.screen.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/info.controller.dart';

class InfoScreen extends GetView<InfoController> {
  const InfoScreen(this.onOpenDetail, {super.key});

  final Function(Post) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final InfoController controller = Get.put(InfoController());

    final List<String> tabs = [
      'Topics',
      'Game Info',
      'Player',
      'Team',
      'Gallery',
      'Partner'
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
              return InkWell(
                onTap: () => controller.changeTab(index),
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
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: controller.selectedIndex.value == index
                            ? Colors.white
                            : PrimaryColor.border, // Selected/Unselected Color
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged, // Sync tab with page
        children: [
          ListTopicsScreen(
            onOpenDetail: (value) {
              onOpenDetail(value);
            },
          ),
          const GameInfoScreen(),
          const MemberScreen(null),
          const WebviewScreen(WebviewType.team),
         const GalleryScreen(),
          const WebviewScreen(WebviewType.partner),
        ],
      ),
    );
  }
}
