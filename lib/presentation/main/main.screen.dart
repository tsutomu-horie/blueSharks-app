import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/app_bottom_navigation_bar.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/main.controller.dart';

class MainScreen extends StatefulWidget {
  final int? initialTab;

  const MainScreen({this.initialTab, super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MainController controller = Get.put(MainController());

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      controller.selectedIndex.value = widget.initialTab!;
    }
  }

  void selectTopic(Post? data) {
    print("selectTopic ${data?.id}");
    controller.selectedTopicId.value = data?.id;
    if (data?.id != null) {
      controller.selectedIndex.value =
          1; // Set the bottom nav index to 1 (Topics tab)
      controller.selectedPost.value = data;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      controller.selectedTopicId.value = null;
      controller.selectedIndex.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    controller.refreshUnreadMessageCount();
    final List<Widget> _pages = [
      HomeScreen((value) {
        selectTopic(value);
      }, () {
        controller.selectedIndex.value = 1;
      }, () {
        controller.selectedTopicId.value = null;
        controller.selectedIndex.value = 5;
      }), // Home page
      MenuScreen((value) {
        selectTopic(value);
      }),
      const MypageScreen(),
      const StadiumScreen(),
      CalendarScreen(),
      const GameGuideListScreen(),
    ];

    print("onOpen ${controller.selectedTopicId}");

    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) async {
        // If we're not on the home tab, go to home tab
        if (controller.selectedTopicId.value != null) {
          controller.selectedTopicId.value = null;
          return;
        }

        if (controller.selectedIndex.value != 0) {
          controller.selectedIndex.value = 0;
          return;
        }

        // If we're on home tab, exit app directly
        SystemNavigator.pop();
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: BackgroundColor.primary,
          appBar: AppBar(
            backgroundColor: BrandColor.hover,
            toolbarHeight: 64.h,
            title: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 30.w,
                  child: SvgPicture.asset(
                    width: 93.w,
                    height: 64.h,
                    'assets/vectors/background_toolbar.svg', // Replace with your SVG file path
                  ),
                ),
                Row(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 9.5.w,
                        ),
                        Column(
                          children: [
                            SizedBox(
                              height: 10.h,
                            ),
                            SvgPicture.asset(
                              width: 44.w,
                              height: 44.h,
                              fit: BoxFit.fitHeight,
                              'assets/vectors/app_logo.svg', // Replace with your SVG file path
                            ),
                            SizedBox(
                              height: 10.h,
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 9.5.w,
                        ),
                      ],
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Obx(() {
                            final unreadMessageCount =
                                controller.unreadMessage.value;
                            return Stack(
                              children: [
                                toolbarButton(
                                  SvgPicture.asset(
                                    'assets/vectors/ic_notification.svg',
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                  LocaleKeys.news_title.tr,
                                  () {
                                    controller.navigateToNotification();
                                  },
                                ),
                                if (unreadMessageCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius:
                                            BorderRadius.circular(12.w),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 24.w,
                                        minHeight: 24.h,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadMessageCount > 9
                                              ? '9+'
                                              : "$unreadMessageCount",
                                          // Replace with dynamic count if needed
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        toolbarButton(
                            SvgPicture.asset(
                              'assets/vectors/ic_fanclub.svg',
                              width: 24.w,
                              height: 24.h,
                            ),
                            LocaleKeys.fan_club.tr, () {
                          // Get.to(() => const FanclubScreen());
                          controller.launchFanClub();
                        }),
                        SizedBox(
                          width: 8.w,
                        ),
                        toolbarButton(
                            SvgPicture.asset(
                              'assets/vectors/ic_ticket.svg',
                              width: 24.w,
                              height: 24.h,
                            ),
                            LocaleKeys.ticket.tr, () {
                          controller.launchTicket();
                        }),
                        SizedBox(
                          width: 8.w,
                        ),
                        toolbarButton(
                            SvgPicture.asset(
                              'assets/vectors/ic_goods.svg',
                              width: 24.w,
                              height: 24.h,
                            ),
                            LocaleKeys.goods.tr, () {
                          controller.launchGood();
                        }),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          body: controller.selectedTopicId.value == null
              ? _pages[controller.selectedIndex.value]
              : InfoDetailScreen(() {
                  selectTopic(null);
                }, controller.selectedPost.value),
          // Display the selected page
          bottomNavigationBar: AppBottomNavigationBar(
            selectedIndex: controller.selectedIndex.value,
            onTap: _onItemTapped,
          ),
        );
      }),
    );
  }

  Widget toolbarButton(SvgPicture icon, String text, Function onPress) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40.w, 48.h),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        onPress();
      },
      //     () {
      //   if (text == LocaleKeys.fan_club.tr) {
      //     Get.to(FanclubScreen());
      //   }
      //
      // },
      child: Column(
        children: [
          icon,
          CustomTextView(
            text,
            style: TextStyle(fontSize: 10.sp, color: Colors.white),
          )
        ],
      ),
    );
  }
}
