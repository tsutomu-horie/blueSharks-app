import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/app_bottom_navigation_bar.dart';
import 'package:koto_blue_sharks/app/views/views/supplied_ui_icon.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/main/main_header_icon_button.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class _Translations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => AppTranslation.translations;
}

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    child: GetMaterialApp(
      theme: ThemeData(brightness: brightness),
      translations: _Translations(),
      locale: const Locale('ja', 'JP'),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _screen(WidgetTester tester, Widget child,
    {Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(child, brightness: brightness));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test(
      'bundled originals decode with their recorded dimensions and transparency',
      () async {
    const originalDimensions = <String, List<int>>{
      'home_icon_off.png': [415, 320],
      'home_icon_on.png': [415, 320],
      'menu_icon_off.png': [301, 280],
      'menu_icon_on.png': [301, 280],
      'mypage_icon_off.png': [219, 320],
      'mypage_icon_on.png': [219, 320],
      'stdium_icon_off.png': [321, 320],
      'stdium_icon_on.png': [321, 320],
      'calendar_icon_off.png': [313, 320],
      'calendar_icon_on.png': [313, 320],
      'news_icon.png': [284, 280],
      'fanclub_icon.png': [337, 281],
      'ticket_icon.png': [407, 222],
      'goods_icon.png': [349, 281],
    };
    expect(originalDimensions, hasLength(14));
    for (final original in originalDimensions.entries) {
      final data =
          await rootBundle.load('assets/images/ui_icons/${original.key}');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      expect([image.width, image.height], original.value);
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final alpha = [for (var i = 3; i < rgba.length; i += 4) rgba[i]];
      expect(alpha, contains(0), reason: original.key);
      expect(alpha, contains(255), reason: original.key);
      image.dispose();
      codec.dispose();
    }
  });

  for (var selected = 0; selected < 6; selected++) {
    testWidgets('footer index $selected preserves states, labels and all taps',
        (tester) async {
      final taps = <int>[];
      final semantics = tester.ensureSemantics();
      await _screen(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: AppBottomNavigationBar(
            selectedIndex: selected,
            onTap: taps.add,
          ),
        ),
      );
      const names = ['home', 'menu', 'mypage', 'stdium', 'calendar'];
      final labels = [
        LocaleKeys.home.tr,
        LocaleKeys.menu_en.tr,
        LocaleKeys.my_page.tr,
        LocaleKeys.stadium.tr,
        LocaleKeys.calendar.tr,
        '楽しみ方',
      ];
      final icons = tester
          .widgetList<SuppliedUiIcon>(
            find.byType(SuppliedUiIcon),
          )
          .toList();
      expect(icons, hasLength(5));
      for (var i = 0; i < names.length; i++) {
        expect(icons[i].fileName,
            '${names[i]}_icon_${i == selected ? "on" : "off"}.png');
        expect(icons[i].color,
            i == selected ? BrandColor.main : TextColor.disabled);
        expect(tester.getSize(find.byWidget(icons[i])), const Size(20, 20));
      }
      final guide = tester.widget<Icon>(find.byIcon(Icons.menu_book_outlined));
      expect(guide.color, selected == 5 ? BrandColor.main : TextColor.disabled);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(taps, [0, 1, 2, 3, 4, 5]);
      final nodes = <SemanticsNode>[];
      void collect(SemanticsNode node) {
        nodes.add(node);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(tester.binding.renderViews.single.owner!.semanticsOwner!
          .rootSemanticsNode!);
      final tabs = nodes
          .where((node) =>
              node.hasFlag(SemanticsFlag.isButton) &&
              labels.any((label) => node.label.contains(label)))
          .toList();
      expect(tabs, hasLength(6));
      expect(tabs.where((node) => node.hasFlag(SemanticsFlag.isSelected)),
          hasLength(1));
      expect(tabs[selected].hasFlag(SemanticsFlag.isSelected), isTrue);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shared footer disabled state blocks taps and retains opacity',
      (tester) async {
    final taps = <int>[];
    await _screen(
      tester,
      AppBottomNavigationBar(
        selectedIndex: 0,
        onTap: taps.add,
        enabled: false,
      ),
    );
    await tester.tap(find.text(LocaleKeys.home.tr), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, isEmpty);
    final opacity = find
        .descendant(
          of: find.byType(AppBottomNavigationBar),
          matching: find.byType(Opacity),
        )
        .first;
    expect(tester.widget<Opacity>(opacity).opacity, 0.6);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fixed footer background and tint survive $brightness',
        (tester) async {
      await _screen(
        tester,
        AppBottomNavigationBar(selectedIndex: 3, onTap: (_) {}),
        brightness: brightness,
      );
      expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .backgroundColor,
          BackgroundColor.primary);
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images.every((image) => image.fit == BoxFit.contain), isTrue);
      expect(images.every((image) => image.colorBlendMode == BlendMode.srcIn),
          isTrue);
      expect(images.every((image) => image.excludeFromSemantics), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  final headerRoles = {
    'news': LocaleKeys.news_title,
    'fanclub': LocaleKeys.fan_club,
    'ticket': LocaleKeys.ticket,
    'goods': LocaleKeys.goods,
  };
  for (final role in headerRoles.entries) {
    testWidgets('header ${role.key} preserves label, hit area and action',
        (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await _screen(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 64,
            child: Builder(
              builder: (_) => MainHeaderIconButton(
                icon: SuppliedUiIcon(
                  fileName: '${role.key}_icon.png',
                  width: 24.w,
                  height: 24.h,
                  color: Colors.white,
                ),
                text: role.value.tr,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SuppliedUiIcon)), const Size(24, 24));
      final buttonSize = tester.getSize(find.byType(ElevatedButton));
      expect(buttonSize.width, greaterThanOrEqualTo(40));
      expect(buttonSize.height, greaterThanOrEqualTo(48));
      expect(
          tester.getSemantics(find.byType(ElevatedButton)),
          matchesSemantics(
              label: role.value.tr,
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
              hasFocusAction: true,
              isFocusable: true));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  for (final fileName in ['home_icon_on.png', 'news_icon.png']) {
    testWidgets('$fileName paints tint without filling transparent pixels',
        (tester) async {
      final key = GlobalKey();
      const tint = Color(0xFF072460);
      await _screen(
        tester,
        Center(
          child: RepaintBoundary(
            key: key,
            child: SuppliedUiIcon(
              fileName: fileName,
              width: 40,
              height: 40,
              color: tint,
            ),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pixels = (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
      var transparent = 0;
      var solid = 0;
      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] == 0) transparent++;
        if (pixels[i + 3] == 255) {
          solid++;
          expect(pixels.sublist(i, i + 3), [7, 36, 96]);
        }
      }
      expect(transparent, greaterThan(0));
      expect(solid, greaterThan(0));
    });
  }

  test('approved colors preserve or improve baseline contrast', () {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return first > second
          ? (first + 0.05) / (second + 0.05)
          : (second + 0.05) / (first + 0.05);
    }

    expect(contrast(Colors.white, BrandColor.hover), greaterThan(4.5));
    expect(
        contrast(BrandColor.main, BackgroundColor.primary), greaterThan(4.5));
    // The pre-existing disabled gray has low contrast; do not claim AA here.
    expect(contrast(TextColor.disabled, BackgroundColor.primary),
        greaterThanOrEqualTo(contrast(const Color(0xFFC9CFD3), Colors.white)));
    expect(BrandColor.main, isNot(TextColor.disabled));
  });
}
