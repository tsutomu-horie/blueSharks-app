import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/main.controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MainController controller = Get.put(MainController());

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
    final List<Widget> _pages = [
      HomeScreen((value) {
        selectTopic(value);
      },(){
        controller.selectedIndex.value =
        1;
      }), // Home page
      InfoScreen((value) {
        selectTopic(value);
      }),
      const MypageScreen(),
      const StadiumScreen(),
      CalendarScreen(),
    ];

    print("onOpen ${controller.selectedTopicId}");

    return Obx(() {
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
                        toolbarButton(
                            SvgPicture.asset(
                              'assets/vectors/ic_notification.svg',
                              width: 24.w,
                              height: 24.h,
                            ),
                            LocaleKeys.new_title.tr, (){
                              controller.navigateToNotification();
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
                          LocaleKeys.fan_club.tr, (){
                        Get.to(() => const FanclubScreen());
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
                          LocaleKeys.ticket.tr, (){

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
                          LocaleKeys.goods.tr, (){

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
            : DetailInfoScreen(() {
                selectTopic(null);
              }, controller.selectedPost.value),
        // Display the selected page
        bottomNavigationBar: Obx(() {
          return BottomNavigationBar(
            backgroundColor: BackgroundColor.primary,
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _customBottomNavItem(
                    "assets/vectors/ic_home_${controller.selectedIndex.value == 0 ? "enabled" : "default"}.svg",
                    LocaleKeys.home.tr,
                    0),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _customBottomNavItem(
                    "assets/vectors/ic_info_${controller.selectedIndex.value == 1 ? "enabled" : "default"}.svg",
                    LocaleKeys.info.tr,
                    1),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _customBottomNavItem(
                    "assets/vectors/ic_member_${controller.selectedIndex.value == 2 ? "enabled" : "default"}.svg",
                    LocaleKeys.my_page.tr,
                    2),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _customBottomNavItem(
                    "assets/vectors/ic_stadium_${controller.selectedIndex.value == 3 ? "enabled" : "default"}.svg",
                    LocaleKeys.stadium.tr,
                    3),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _customBottomNavItem(
                    "assets/vectors/ic_calendar_${controller.selectedIndex.value == 4 ? "enabled" : "default"}.svg",
                    LocaleKeys.calendar.tr,
                    4),
                label: '',
              ),
            ],
            currentIndex: controller.selectedIndex.value,
            onTap: _onItemTapped,
          );
        }),
      );
    });
  }

  Widget toolbarButton(SvgPicture icon, String text, Function onPress) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40.w, 48.h),
        padding: EdgeInsets.zero,
      ),
      onPressed: (){onPress();},
      //     () {
      //   if (text == LocaleKeys.fan_club.tr) {
      //     Get.to(FanclubScreen());
      //   }
      //
      // },
      child: Column(
        children: [
          icon,
          //todo:: custom font
          CustomTextView(
            text,
            style: TextStyle(fontSize: 10.sp, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _customBottomNavItem(String icon, String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
        ),
        SizedBox(height: 4.h), // Space between icon and label
        Text(
          label,
          style: TextStyle(
            fontSize: 12, // Customize label font size here
            color: controller.selectedIndex.value == index
                ? BrandColor.main
                : TextColor.disabled,
          ),
        ),
      ],
    );
  }
}
