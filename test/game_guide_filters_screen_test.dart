import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/app/providers/game_guide/game_guide_provider.dart';
import 'package:koto_blue_sharks/presentation/game_guide/controllers/game_guide.controller.dart';
import 'package:koto_blue_sharks/presentation/game_guide/game_guide_list.screen.dart';

class Articles extends GameGuideProvider {
  final pages = <int>[];
  @override
  void onInit() {}
  @override
  Future<List<GameGuidePost>> fetchGuides(
      {required int page, int perPage = 10}) async {
    pages.add(page);
    return List.generate(
        page == 1 ? 10 : 4,
        (i) => GameGuidePost(
              id: page * 10 + i,
              title: '記事$page-$i',
              publishedAt: null,
              detailUrl: 'https://blue-sharks.donati.jp/game-guide/$page-$i/',
              season: page == 1 ? '2025 – 2026 シーズン' : '2024 – 2025 シーズン',
              location: '夢の島競技場',
              status: '試合終了',
            ));
  }
}

void main() {
  testWidgets('右上だけに絞り込みを置き、全ページの選択肢を取得して条件を適用・解除できる', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    final provider = Articles();
    final controller = Get.put(GameGuideController(provider: provider));
    addTearDown(Get.reset);
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const GetMaterialApp(home: GameGuideListScreen())));
    await tester.pumpAndSettle();
    expect(controller.guides, hasLength(10));
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.text('条件あり'), findsNothing);
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    expect(provider.pages, [1, 2]);
    expect(controller.guides, hasLength(14));
    expect(find.textContaining('仮実装'), findsNothing);
    expect(find.textContaining('WordPress'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(provider.pages, [1, 2], reason: '条件の編集中は復帰更新で選択肢を変えない');
    await tester.tap(find.byType(DropdownButtonFormField<String?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024 – 2025 シーズン').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('この条件で表示'));
    await tester.pumpAndSettle();
    expect(controller.visibleGuides, hasLength(4));
    await controller.refreshGuides();
    await tester.pumpAndSettle();
    expect(controller.visibleGuides, hasLength(4));
    expect(provider.pages, [1, 2, 1, 2, 1, 2]);
    expect(find.text('条件あり'), findsNothing);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('条件をクリア'));
    await tester.pumpAndSettle();
    expect(controller.visibleGuides, hasLength(14));
    controller.applyFilters(season: '現在はないシーズン');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この条件で表示'));
    await tester.pumpAndSettle();
    expect(controller.selectedSeason.value, isNull);
    expect(controller.visibleGuides, hasLength(14));
    expect(tester.takeException(), isNull);
  });
  testWidgets('幅320・高さ568・文字2倍でもシーズンを選択して適用できる', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    Get.put(GameGuideController(provider: Articles()));
    addTearDown(Get.reset);
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => GetMaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!),
            home: const GameGuideListScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dropdown = find.byType(DropdownButtonFormField<String?>).first;
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025 – 2026 シーズン').last);
    await tester.pumpAndSettle();
    final apply = find.text('この条件で表示');
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(Get.find<GameGuideController>().visibleGuides, hasLength(10));
  });
  testWidgets('全記事が終了済みでも開催予定を選択でき、0件の案内から条件解除で戻れる', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    final c = Get.put(GameGuideController(provider: Articles()));
    addTearDown(Get.reset);
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const GetMaterialApp(home: GameGuideListScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('絞り込み'));
    await tester.pumpAndSettle();
    expect(c.guides.every((p) => p.status == '試合終了'), isTrue);
    await tester.tap(find.byType(DropdownButtonFormField<String?>).last);
    await tester.pumpAndSettle();
    expect(find.text('開催予定'), findsOneWidget);
    expect(find.text('試合終了'), findsOneWidget);
    await tester.tap(find.text('開催予定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この条件で表示'));
    await tester.pumpAndSettle();
    expect(c.selectedStatus.value, '開催予定');
    expect(c.visibleGuides, isEmpty);
    expect(find.text('条件に一致する記事がありません'), findsOneWidget);
    await tester.tap(find.text('条件をクリア'));
    await tester.pumpAndSettle();
    expect(c.visibleGuides, hasLength(14));
    expect(c.selectedStatus.value, isNull);
    expect(tester.takeException(), isNull);
  });
}
