import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:get/get.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    required this.selectedIndex,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: BottomNavigationBar(
          backgroundColor: BackgroundColor.primary,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: onTap,
          items: [
            _svgItem('home', LocaleKeys.home.tr, 0),
            _svgItem('info', LocaleKeys.menu_en.tr, 1),
            _svgItem('member', LocaleKeys.my_page.tr, 2),
            _svgItem('stadium', LocaleKeys.stadium.tr, 3),
            _svgItem('calendar', LocaleKeys.calendar.tr, 4),
            BottomNavigationBarItem(
              icon: _itemContent(
                Icon(
                  Icons.menu_book_outlined,
                  size: 20.w,
                  color:
                      selectedIndex == 5 ? BrandColor.main : TextColor.disabled,
                ),
                '楽しみ方',
                5,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _svgItem(String name, String label, int index) {
    return BottomNavigationBarItem(
      icon: _itemContent(
        SvgPicture.asset(
          'assets/vectors/ic_${name}_${selectedIndex == index ? "enabled" : "default"}.svg',
          width: 20.w,
          height: 20.w,
        ),
        label,
        index,
      ),
      label: '',
    );
  }

  Widget _itemContent(Widget icon, String label, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color:
                selectedIndex == index ? BrandColor.main : TextColor.disabled,
          ),
        ),
      ],
    );
  }
}
