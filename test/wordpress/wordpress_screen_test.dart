import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/wordpress/controllers/wordpress.controller.dart';
import 'package:koto_blue_sharks/presentation/wordpress/wordpress.screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontManifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final familyEntry in fontManifest.cast<Map<String, dynamic>>()) {
      final fontLoader = FontLoader(familyEntry['family'] as String);
      for (final fontEntry
          in (familyEntry['fonts'] as List).cast<Map<String, dynamic>>()) {
        fontLoader.addFont(rootBundle.load(fontEntry['asset'] as String));
      }
      await fontLoader.load();
    }
  });

  setUp(() {
    Get.put(WordPressController());
  });
  tearDown(Get.reset);

  testWidgets('keeps the WordPress guide and removes the specification card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['LINESeedJP'],
        ),
        home: const WordPressScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('アプリ連携仕様'), findsNothing);
    expect(find.text('公開済み記事のみ取得'), findsNothing);
    expect(find.text('外部システム'), findsOneWidget);
    expect(find.textContaining('記事の作成・公開・更新・削除は'), findsOneWidget);
    expect(find.text('WordPress管理画面を開く'), findsOneWidget);
    final launchButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'WordPress管理画面を開く'),
    );
    expect(launchButton.onPressed, isNotNull);
    final enabledTextStyle = launchButton.style?.textStyle?.resolve({});
    expect(enabledTextStyle?.fontFamily, 'Inter');
    expect(enabledTextStyle?.fontFamilyFallback, contains('LINESeedJP'));
    expect(find.textContaining('要確認：'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(WordPressScreen),
      matchesGoldenFile('goldens/no87_wordpress_wide.png'),
    );
  });

  testWidgets('fits the compact admin width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['LINESeedJP'],
        ),
        home: const WordPressScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('アプリ連携仕様'), findsNothing);
    expect(find.text('外部システム'), findsOneWidget);
    expect(find.text('WordPress管理画面を開く'), findsOneWidget);
    final button = find.widgetWithText(ElevatedButton, 'WordPress管理画面を開く');
    expect(tester.getSize(button).width, lessThan(322));
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(WordPressScreen),
      matchesGoldenFile('goldens/no87_wordpress_compact.png'),
    );
  });
}
