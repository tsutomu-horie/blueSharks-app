import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_dex_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester,
      {bool unlocked = false,
      Size size = const Size(375, 812),
      double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        builder: (_, child) => MediaQuery(
            data: MediaQueryData(
                size: size, textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                    body: TextButton(
                  onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => TrainingDexDialog(
                          registeredCount: unlocked ? 1 : 0,
                          isPositionUnlocked: (name) =>
                              unlocked && name == 'プロップ')),
                  child: const Text('開く'),
                ))),
      ),
    ));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
  }

  testWidgets('未解放10件の説明、最終項目へのスクロール、閉じる', (tester) async {
    await open(tester);
    expect(find.textContaining('0/10 登録'), findsOneWidget);
    expect(find.text('🔒 未解放'), findsNWidgets(10));
    expect(find.text('✅ 登録済み'), findsNothing);
    expect(find.byType(SametarohFrameImage), findsNWidgets(10));
    expect(find.byType(ColorFiltered), findsNWidgets(10));
    await tester.scrollUntilVisible(find.text('フルバック'), 250,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('フルバック').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingDexDialog), findsNothing);
  });

  testWidgets('登録済みだけ支給素材と登録表示になる', (tester) async {
    await open(tester, unlocked: true);
    expect(find.textContaining('1/10 登録'), findsOneWidget);
    expect(find.text('✅ 登録済み'), findsOneWidget);
    expect(find.text('🔒 未解放'), findsNWidgets(9));
    expect(find.byType(SametarohFrameImage), findsNWidgets(10));
    expect(find.byType(ColorFiltered), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('幅320・文字拡大でも閉じる操作と説明を保持', (tester) async {
    await open(tester, size: const Size(320, 568), scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('閉じる').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(find.text('フルバック'), 250,
        scrollable: find.byType(Scrollable).last);
    expect(tester.takeException(), isNull);
  });
  testWidgets('横向きでも全項目へ到達できる', (tester) async {
    await open(tester, size: const Size(812, 375), scale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('フルバック'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('閉じる').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
