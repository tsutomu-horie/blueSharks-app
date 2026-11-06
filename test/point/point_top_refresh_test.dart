import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';
import 'package:koto_blue_sharks/presentation/point/point_screens.dart';

class _RefreshController extends PointController {
  int refreshes = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> loadOverview() async {
    refreshes++;
    account.value = account.value!.copyWith(balance: 4663);
  }
}

void main() {
  testWidgets('内容が画面より短くても下へ引いて最新残高を取得できる', (tester) async {
    tester.view.physicalSize = const Size(375, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final controller = _RefreshController()
      ..isAuthenticated.value = true
      ..account.value = const PointAccount(
          balance: 4661, lifetimeEarned: 4663, lifetimeSpent: 2);
    Get.put<PointController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const GetMaterialApp(home: PointTopScreen()),
    ));
    await tester.pumpAndSettle();
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.maxScrollExtent, 0, reason: 'スクロール不要な表示で再現する');
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(controller.refreshes, 1);
    expect(controller.account.value!.balance, 4663);
    expect(tester.takeException(), isNull);
  });
}
