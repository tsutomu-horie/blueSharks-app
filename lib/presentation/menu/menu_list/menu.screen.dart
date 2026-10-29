import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/menu.controller.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen(this.onOpenDetail,
      {super.key, this.overviewBuilder, this.initialSection});
  final Function(Post) onOpenDetail;
  final Widget Function(VoidCallback showTopics)? overviewBuilder;
  final int? initialSection;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final MenuListController controller;
  late bool _showOverview;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MenuListController());
    _showOverview =
        widget.overviewBuilder != null && widget.initialSection == null;
    if (widget.initialSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.pageController.hasClients) {
          controller.changeTab(widget.initialSection!);
        }
      });
    }
  }

  void _selectSection(int index) {
    if (_showOverview) {
      setState(() => _showOverview = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.pageController.hasClients) {
          controller.changeTab(index);
        }
      });
    } else {
      controller.changeTab(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = [
      'TOPICS',
      'GAME INFO',
      'MEMBER',
      'GALLERY',
      'TEAM',
      'PARTNER',
      "",
      ""
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff002b6d),
        surfaceTintColor: Colors.transparent,
        // Replace with your BrandColor.hover
        toolbarHeight: 44.h,
        titleSpacing: 0,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (index) {
              if (index == 6) {
                return IconButton(
                  icon: Icon(
                    IconsaxPlusLinear.instagram,
                    color: BrandColor.border,
                    size: 20.w,
                  ),
                  onPressed: () {
                    controller.launchInstagram();
                  },
                );
              } else if (index == 7) {
                return IconButton(
                  icon: SvgPicture.asset("assets/vectors/ic_x_twitter.svg"),
                  onPressed: () {
                    controller.launchTwitter();
                  },
                );
              } else {
                return InkWell(
                  onTap: () => {
                    if (index == 5)
                      {controller.launchPartner()}
                    else if (index == 4)
                      {controller.launchTeam()}
                    else
                      {_selectSection(index)}
                  },
                  child: Obx(() {
                    final selectedIndex = controller.selectedIndex.value;
                    final isSelected = !_showOverview && selectedIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      constraints: BoxConstraints(minHeight: 44.h),
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 2.0, // Underline thickness
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : PrimaryColor.border,
                            ),
                          ),
                          if (index == 5 || index == 4)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: SvgPicture.asset(
                                "assets/vectors/ic_external_link.svg",
                                width: 16.w,
                                height: 16.h,
                              ),
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
      body: _showOverview
          ? widget.overviewBuilder!(() => _selectSection(0))
          : PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged, // Sync tab with page
              children: [
                TopicListScreen(
                  onOpenDetail: (value) {
                    widget.onOpenDetail(value);
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
