import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../config.dart';
import '../../presentation/screens.dart';
import 'bindings/controllers/controllers_bindings.dart';
import 'routes.dart';

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  EnvironmentsBadge({required this.child});
  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    return env != Environments.PRODUCTION
        ? Banner(
            location: BannerLocation.topStart,
            message: env!,
            color: env == Environments.QAS ? Colors.blue : Colors.purple,
            child: child,
          )
        : SizedBox(child: child);
  }
}

class Nav {
  static List<GetPage> routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(),
      binding: HomeControllerBinding(),
    ),
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashControllerBinding(),
    ),
    GetPage(
      name: Routes.WALLPAPER,
      page: () => const WallpaperScreen(),
      binding: WallpaperControllerBinding(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => MainScreen(),
      binding: MainControllerBinding(),
    ),
    GetPage(
      name: Routes.INFO,
      page: () => const InfoScreen(),
      binding: InfoControllerBinding(),
    ),
    GetPage(
      name: Routes.MYPAGE,
      page: () => const MypageScreen(),
      binding: MypageControllerBinding(),
    ),
    GetPage(
      name: Routes.STADIUM,
      page: () => const StadiumScreen(),
      binding: StadiumControllerBinding(),
    ),
    GetPage(
      name: Routes.CALENDAR,
      page: () => const CalendarScreen(),
      binding: CalendarControllerBinding(),
    ),
    GetPage(
      name: Routes.LIST_TOPICS,
      page: () => const ListTopicsScreen(),
      binding: ListTopicsControllerBinding(),
    ),
  ];
}
