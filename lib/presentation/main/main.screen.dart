import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'main_header_icon_button.dart';
import 'package:koto_blue_sharks/app/views/views/app_bottom_navigation_bar.dart';
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
  int? _menuSection;
  int _menuVisit = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      controller.selectedIndex.value = widget.initialTab!;
    }
  }

  void selectTopic(Post? data) {
    setState(() {
      if (data != null) _menuSection = 0;
      controller.selectedTopicId.value = data?.id;
      if (data != null) {
        controller.selectedIndex.value = 1;
        controller.selectedPost.value = data;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) {
        _menuSection = null;
        _menuVisit++;
      }
      controller.selectedTopicId.value = null;
      controller.selectedIndex.value = index;
    });
  }

  void _openTopics() {
    setState(() {
      _menuSection = 0;
      controller.selectedTopicId.value = null;
      controller.selectedIndex.value = 1;
    });
  }

  void _openGuide() {
    controller.selectedTopicId.value = null;
    controller.selectedIndex.value = 5;
  }

  @override
  Widget build(BuildContext context) {
    controller.refreshUnreadMessageCount();
    final List<Widget> _pages = [
      HomeScreen(selectTopic, _openTopics, _openGuide),
      MenuScreen(selectTopic,
          key: ValueKey('menu-$_menuSection-$_menuVisit'),
          initialSection: _menuSection,
          overviewBuilder: (showTopics) =>
              HomeScreen(selectTopic, showTopics, _openGuide)),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            toolbarHeight: 60.h,
            titleSpacing: 8.w,
            automaticallyImplyLeading: false,
            title: MainHeaderBar(
                onNews: controller.navigateToNotification,
                onFanClub: controller.launchFanClub,
                onTicket: controller.launchTicket,
                onGoods: controller.launchGood,
                unreadCount: controller.unreadMessage.value),
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
}
