import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/supplied_ui_icon.dart';

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

  int get _activeIndex =>
      selectedIndex >= 0 && selectedIndex < 5 ? selectedIndex : 0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xff002b6d),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          currentIndex: _activeIndex,
          onTap: onTap,
          items: [
            _imageItem('home', 'HOME', 0),
            _imageItem('menu', 'MENU', 1),
            _imageItem('mypage', 'MY PAGE', 2),
            _imageItem('stdium', 'STADIUM', 3),
            _imageItem('calendar', 'CALENDAR', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _imageItem(String name, String label, int index) {
    return BottomNavigationBarItem(
      icon: _itemContent(
        SuppliedUiIcon(
          fileName: '${name}_icon_${_activeIndex == index ? "on" : "off"}.png',
          width: 20.w,
          height: 20.w,
          color: _activeIndex == index ? Colors.white : const Color(0xff2c66bf),
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
            fontSize: 9.sp,
            fontWeight: FontWeight.w800,
            color:
                _activeIndex == index ? Colors.white : const Color(0xff2c66bf),
          ),
        ),
      ],
    );
  }
}
