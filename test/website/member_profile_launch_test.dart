import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart' as media;
import 'package:koto_blue_sharks/app/views/views/member/views/player_card_view.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/controllers/player_list.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/player_list.screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Launcher extends UrlLauncherPlatform {
  @override
  get linkDelegate => null;
  final urls = <String>[];
  final modes = <PreferredLaunchMode>[];
  bool succeeds = true;
  bool throws = false;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    modes.add(options.mode);
    if (throws) throw Exception('Launch failed');
    return succeeds;
  }
}

class _Players extends PlayerListController {
  @override
  String imageCompressor(String url) => '';

  @override
  void onInit() {
    isLoading.value = false;
    isImageLoading.value = false;
    preloadedImages['null'] = 'https://example.com/player.jpg';
  }
}

Member _member(String link) => Member(
      id: 1,
      date: '',
      modified: '',
      slug: 'player',
      status: 'publish',
      type: 'member',
      link: link,
      title: media.Title(rendered: '選手'),
      categoryId: 1,
      categorySlug: 'prop',
      categoryName: 'PROP',
      custom_field: null,
    );

void main() {
  late UrlLauncherPlatform original;
  late _Launcher launcher;
  setUp(() {
    Get.testMode = true;
    original = UrlLauncherPlatform.instance;
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
  });
  tearDown(() async {
    UrlLauncherPlatform.instance = original;
    Get.reset();
  });

  Future<_Players> showList(WidgetTester tester, String link) async {
    final controller = _Players();
    Get.put<PlayerListController>(controller);
    controller.categoryPlayers[1] = [_member(link)];
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const GetMaterialApp(
        home: PlayerListScreen(null),
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  const profile = 'https://blue-sharks.donati.jp/members/prop/2025/01/17312/';

  for (final throws in [false, true]) {
    testWidgets('MEMBERの起動失敗後もリストから再試行できる（例外=$throws）', (tester) async {
      final controller = await showList(tester, profile);
      launcher.succeeds = false;
      launcher.throws = throws;
      final card = find.byType(PlayerCardView);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('選手ページを開けませんでした。'), findsOneWidget);
      expect(find.byType(PlayerListScreen), findsOneWidget);
      expect(controller.categoryPlayers[1]!.single.link, profile);
      expect(launcher.urls, [profile]);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      launcher.succeeds = true;
      launcher.throws = false;
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(launcher.urls, [profile, profile]);
      expect(
          launcher.modes, everyElement(PreferredLaunchMode.inAppBrowserView));
      expect(find.byType(PlayerListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final link in [
    '',
    '/members/prop/2025/01/17312/',
    'http://blue-sharks.donati.jp/members/prop/2025/01/17312/',
    'javascript:alert(1)',
    'https://user:pass@blue-sharks.donati.jp/members/',
    'https://blue-sharks.donati.jp:444/members/',
  ]) {
    testWidgets('安全なHTTPSではないMEMBERリンクを起動しない: $link', (tester) async {
      final controller = await showList(tester, link);
      await controller.navigateToMemberDetail(_member(link));
      await tester.pumpAndSettle();
      expect(launcher.urls, isEmpty);
      expect(find.text('選手ページを開けませんでした。'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerListScreen), findsOneWidget);
    });
  }

  testWidgets('ヘッダー3リンクもアプリ内ブラウザを明示する', (tester) async {
    final controller = MainController();
    controller.launchFanClub();
    controller.launchTicket();
    controller.launchGood();
    await tester.pump();
    expect(launcher.urls, hasLength(3));
    expect(launcher.modes, everyElement(PreferredLaunchMode.inAppBrowserView));
  });
}
