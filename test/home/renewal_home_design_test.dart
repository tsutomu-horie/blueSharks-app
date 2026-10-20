import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_follow_section.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/app_bottom_navigation_bar.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_featured_topics.dart';
import 'package:koto_blue_sharks/presentation/main/main_header_icon_button.dart';

Post post(int id) => Post(
    id: id,
    date: '2026-10-20T00:00:00',
    slug: 'news-$id',
    link: 'https://blue-sharks.donati.jp/news/$id/',
    title: PostTitle(rendered: '<b>長い見出し &amp; 掲載記事の内容を保つための確認</b>' * 3),
    content: PostContent(rendered: '', protected: false),
    excerpt: PostExcerpt(rendered: '', protected: false),
    categories: [1, 33, 34, 38],
    featured_media: id);

Widget app(Widget child, {double scale = 1}) => ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: Scaffold(body: SingleChildScrollView(child: child))));

void main() {
  testWidgets('320/375/430幅・文字1/2倍でもヘッダー全体の4操作が欠けない', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 375.0, 430.0]) {
      tester.view.physicalSize = Size(width, 812);
      for (final scale in [1.0, 2.0]) {
        final calls = <String>[];
        await tester.pumpWidget(app(
            SizedBox(
                height: 64,
                child: MainHeaderBar(
                    key: ValueKey('$width/$scale'),
                    unreadCount: 12,
                    onNews: () => calls.add('NEWS'),
                    onFanClub: () => calls.add('FAN CLUB'),
                    onTicket: () => calls.add('TICKET'),
                    onGoods: () => calls.add('GOODS'))),
            scale: scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width/$scale');
        for (final label in ['NEWS', 'FAN CLUB', 'TICKET', 'GOODS']) {
          await tester.tap(find.text(label));
        }
        expect(calls, ['NEWS', 'FAN CLUB', 'TICKET', 'GOODS']);
        expect(find.text('9+'), findsOneWidget);
      }
    }
  });

  testWidgets('長い記事も文字2倍でカード内に収まり横送りと記事遷移を維持する', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 375.0, 430.0]) {
      tester.view.physicalSize = Size(width, 812);
      Post? opened;
      final posts = [post(1), post(2)];
      await tester.pumpWidget(app(
          RenewalFeaturedTopics(
              key: ValueKey(width),
              posts: posts,
              loadImage: (_) async => '',
              onOpen: (post) => opened = post),
          scale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$width');
      await tester.tap(find.byType(InkWell).first);
      expect(opened?.id, 1);
      await tester.drag(find.byType(PageView), Offset(-width, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('記事画像の一時失敗を固定せず、同じ記事の再表示で再取得できる', (tester) async {
    var calls = 0;
    final posts = [post(1)];
    Future<String> load(Post _) async {
      calls++;
      if (calls == 1) throw StateError('temporary image failure');
      return '';
    }

    Widget show() => app(
        RenewalFeaturedTopics(posts: posts, loadImage: load, onOpen: (_) {}));
    await tester.pumpWidget(show());
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(show());
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('楽しみ方画面でも5項目フッターはHOME選択として利用できる', (tester) async {
    await tester.pumpWidget(
        app(AppBottomNavigationBar(selectedIndex: 5, onTap: (_) {})));
    await tester.pumpAndSettle();
    final footer =
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(footer.items, hasLength(5));
    expect(footer.currentIndex, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('FOLLOW USの3リンクは対応する公式URLを外部で開く', (tester) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(app(const RenewalFollowSection()));
    await tester.pumpAndSettle();
    for (final label in ['X', 'Instagram', 'YouTube']) {
      await tester.tap(find.byTooltip(label));
      await tester.pumpAndSettle();
    }
    expect(calls.map((c) => (c.arguments as Map)['url']), [
      'https://x.com/Bluesharks_2020',
      'https://www.instagram.com/shimz.bluesharks/',
      'https://www.youtube.com/@KotoBlueSharks',
    ]);
    expect(calls.every((c) => (c.arguments as Map)['useSafariVC'] != true),
        isTrue);
    expect(tester.takeException(), isNull);
  });
}
