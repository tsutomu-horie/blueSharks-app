import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/home/home.screen.dart';
import 'package:koto_blue_sharks/presentation/info/info.screen.dart';
import 'package:koto_blue_sharks/presentation/mypage/mypage.screen.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

import 'controllers/main.controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _pages = [
    const HomeScreen(), // Home page
    const InfoScreen(),
    const MypageScreen(),
    const StadiumScreen(),
    const CalendarScreen(),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                if (_selectedIndex == 0)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: SvgPicture.asset(
                            'assets/vectors/ic_notification.svg',
                            width: 24.w,
                            height: 24.h,
                          )),
                    ],
                  ),
                ),
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
                if (_selectedIndex != 0)
                const Flexible(child: SizedBox(width: double.infinity,)),
                Row(
                  children: [
                    toolbarButton(
                        SvgPicture.asset(
                          'assets/vectors/ic_fanclub.svg',
                          width: 24.w,
                          height: 24.h,
                        ),
                        LocaleKeys.fan_club.tr),
                    SizedBox(
                      width: 8.w,
                    ),
                    toolbarButton(
                        SvgPicture.asset(
                          'assets/vectors/ic_ticket.svg',
                          width: 24.w,
                          height: 24.h,
                        ),
                        LocaleKeys.ticket.tr),
                    SizedBox(
                      width: 8.w,
                    ),
                    toolbarButton(
                        SvgPicture.asset(
                          'assets/vectors/ic_goods.svg',
                          width: 24.w,
                          height: 24.h,
                        ),
                        LocaleKeys.goods.tr),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _customBottomNavItem("assets/vectors/ic_home_${_selectedIndex == 0 ? "enabled" : "default"}.svg", LocaleKeys.home.tr, 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _customBottomNavItem("assets/vectors/ic_info_${_selectedIndex == 1 ? "enabled" : "default"}.svg", LocaleKeys.info.tr, 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _customBottomNavItem("assets/vectors/ic_member_${_selectedIndex == 2 ? "enabled" : "default"}.svg", LocaleKeys.my_page.tr, 2),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _customBottomNavItem("assets/vectors/ic_stadium_${_selectedIndex == 3 ? "enabled" : "default"}.svg", LocaleKeys.stadium.tr, 3),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _customBottomNavItem("assets/vectors/ic_calendar_${_selectedIndex == 4 ? "enabled" : "default"}.svg", LocaleKeys.calendar.tr, 4),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget toolbarButton(SvgPicture icon, String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40.w, 48.h),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {},
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
        SvgPicture.asset(icon, width: 20, height: 20,),
        SizedBox(height: 4.h), // Space between icon and label
        Text(
          label,
          style: TextStyle(
            fontSize: 12, // Customize label font size here
            color: _selectedIndex == index
                ? BrandColor.main
                : TextColor.disabled,
          ),
        ),
      ],
    );
  }
}