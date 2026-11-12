import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/menu/menu_list/controllers/menu.controller.dart';
import 'package:koto_blue_sharks/presentation/home/home.screen.dart';
import 'package:koto_blue_sharks/presentation/menu/info/list_info/list_info.dart';
import 'package:koto_blue_sharks/presentation/menu/info/list_info/controllers/list_info.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/controllers/player_list.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/player_list.screen.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_list/controllers/match_list_screen.dart';

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

class _TopicListControllerFixture extends TopicListController {
  @override
  void onInit() {}
}

class _PlayerListControllerFixture extends PlayerListController {
  @override
  void onInit() {
    isLoading.value = false;
  }
}

class _MatchListControllerFixture extends MatchListController {
  @override
  void onInit() {
    isLoading.value = false;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<MainController>(_MainControllerFixture());
    Get.put<HomeController>(_HomeControllerFixture());
    Get.put<MenuListController>(_MenuListControllerFixture());
    Get.put<TopicListController>(_TopicListControllerFixture());
    Get.put<PlayerListController>(_PlayerListControllerFixture());
    Get.put<MatchListController>(_MatchListControllerFixture());
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
    Finder banner(String asset) => find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == asset);
    expect(
        tester.getTopLeft(banner('assets/images/renewal/guide_banner.jpg')).dy,
        lessThan(tester
            .getTopLeft(banner('assets/images/renewal/training_banner.jpg'))
            .dy));
    await tester.tap(find.text('MENU'));
    await tester.pump();

    expect(find.text('TOPICS'), findsWidgets);
    expect(tester.widget<Text>(find.text('TOPICS').first).style?.color,
        Colors.white);
    final topicsContainer = tester.widget<AnimatedContainer>(find.ancestor(
      of: find.text('TOPICS').first,
      matching: find.byType(AnimatedContainer),
    ));
    expect(
      (topicsContainer.decoration! as BoxDecoration).border!.bottom.color,
      Colors.white,
    );
    expect(find.text('GAME INFO'), findsOneWidget);
    expect(find.text('MEMBER'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.byType(TopicListScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    // Leave a different MENU section selected, then enter MENU again.
    Get.find<MenuListController>().pageController.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerListScreen), findsOneWidget);
    expect(Get.find<MenuListController>().selectedIndex.value, 2);
    await tester.tap(find.text('HOME'));
    await tester.pump();
    await tester.tap(find.text('MENU'));
    await tester.pump();
    await tester.pump();
    expect(Get.find<MenuListController>().selectedIndex.value, 0);
    expect(find.byType(TopicListScreen), findsOneWidget);
    expect(find.byType(PlayerListScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
