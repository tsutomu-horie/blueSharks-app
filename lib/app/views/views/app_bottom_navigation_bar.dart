import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/supplied_ui_icon.dart';
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
            _imageItem('home', LocaleKeys.home.tr, 0),
            _imageItem('menu', LocaleKeys.menu_en.tr, 1),
            _imageItem('mypage', LocaleKeys.my_page.tr, 2),
            _imageItem('stdium', LocaleKeys.stadium.tr, 3),
            _imageItem('calendar', LocaleKeys.calendar.tr, 4),
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

  BottomNavigationBarItem _imageItem(String name, String label, int index) {
    return BottomNavigationBarItem(
      icon: _itemContent(
        SuppliedUiIcon(
          fileName: '${name}_icon_${selectedIndex == index ? "on" : "off"}.png',
          width: 20.w,
          height: 20.w,
          color: selectedIndex == index ? BrandColor.main : TextColor.disabled,
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
