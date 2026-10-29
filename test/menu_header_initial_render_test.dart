import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/menu/menu_list/controllers/menu.controller.dart';

class _MainControllerFixture extends MainController {
  @override
  void onInit() {}

  @override
  void refreshUnreadMessageCount() {}
}

class _HomeControllerFixture extends HomeController {
  @override
  void getWallpaper() {}

  @override
  void screenInit({bool refreshWebsiteContent = false}) {}
}

class _MenuListControllerFixture extends MenuListController {
  @override
  void onInit() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<MainController>(_MainControllerFixture());
    Get.put<HomeController>(_HomeControllerFixture());
    Get.put<MenuListController>(_MenuListControllerFixture());
  });

  tearDown(Get.reset);

  testWidgets('HOMEからMENUを開いた初回フレームにヘッダー項目が表示される', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    ));
    await tester.pump();

    expect(find.text('HOME'), findsOneWidget);
    await tester.tap(find.text('MENU'));
    await tester.pump();

    expect(find.text('TOPICS'), findsOneWidget);
    expect(find.text('GAME INFO'), findsOneWidget);
    expect(find.text('MEMBER'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.text('次の試合'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
