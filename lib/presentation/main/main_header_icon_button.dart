import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/app/views/views/supplied_ui_icon.dart';

class MainHeaderBar extends StatelessWidget {
  const MainHeaderBar(
      {super.key,
      required this.onNews,
      required this.onFanClub,
      required this.onTicket,
      required this.onGoods,
      this.unreadCount = 0});
  final VoidCallback onNews;
  final VoidCallback onFanClub;
  final VoidCallback onTicket;
  final VoidCallback onGoods;
  final int unreadCount;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            flex: 4,
            child: Semantics(
                label: 'KOTO BLUE SHARKS',
                image: true,
                child: Row(children: [
                  SvgPicture.asset('assets/vectors/app_logo.svg',
                      width: 24.w, height: 32.h),
                  SizedBox(width: 4.w),
                  Expanded(
                      child: SvgPicture.asset(
                          'assets/vectors/app_logo_label.svg',
                          fit: BoxFit.contain)),
                ]))),
        SizedBox(width: 8.w),
        Expanded(
            flex: 6,
            child: Row(children: [
              Expanded(
                  child: Stack(clipBehavior: Clip.none, children: [
                _button('news', 'NEWS', onNews),
                if (unreadCount > 0)
                  Positioned(
                      right: 0,
                      top: 0,
                      child: Semantics(
                          label: '未読 $unreadCount 件',
                          child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10))))),
              ])),
              Expanded(child: _button('fanclub', 'FAN CLUB', onFanClub)),
              Expanded(child: _button('ticket', 'TICKET', onTicket)),
              Expanded(child: _button('goods', 'GOODS', onGoods)),
            ])),
      ]);

  Widget _button(String icon, String text, VoidCallback onTap) =>
      MainHeaderIconButton(
          icon: SuppliedUiIcon(
              fileName: '${icon}_icon.png',
              color: const Color(0xff002b6d),
              width: 24.w,
              height: 24.h),
          text: text,
          onPressed: onTap);
}

class MainHeaderIconButton extends StatelessWidget {
  const MainHeaderIconButton(
      {required this.icon,
      required this.text,
      required this.onPressed,
      super.key});
  final Widget icon;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: text,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          minimumSize: Size(40.w, 48.h),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          icon,
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  maxLines: 1,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff002b6d)))),
        ]),
      ));
}
