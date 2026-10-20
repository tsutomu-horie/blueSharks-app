import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_goods.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/app/views/views/other/views/website_goods_section.dart';
import 'package:koto_blue_sharks/presentation/home/controllers/home.controller.dart';

void main() {
  final origin = Uri.parse('https://blue-sharks.donati.jp/');
  final fixture =
      File('test/home/fixtures/renewal_goods_20261016.html').readAsStringSync();
  String card(
          {String href = 'https://bluesharks.base.shop/items/123',
          String image = '/uploads/item.jpg',
          String name = '商品 &amp; 鮫太朗',
          String price = '<span>¥</span>3,000'}) =>
      '''<a class="goods-card" href="$href">
      <img src="$image"><p class="goods-card__name">$name</p>
      <p class="goods-card__price">$price</p></a>''';
  String section(String cards) => '<section class="top-goods">$cards</section>';

  test('取得済みの公開HTML14商品をSSR掲載順・名称・円価格・画像・リンクのまま読む', () {
    final products = WebsiteGoods.parseHomepage(fixture, origin);
    expect(products, hasLength(14));
    expect(products.map((p) => p.url.pathSegments.last), [
      '140307419',
      '135090872',
      '135092305',
      '134425885',
      '128057421',
      '96305063',
      '96316581',
      '77077606',
      '71021402',
      '71020966',
      '70994230',
      '71021139',
      '82115304',
      '85093919',
    ]);
    expect(products.first.name, '応援フラッグ（エンブレムver.）');
    expect(products.first.priceLabel, '¥700');
    expect(products.first.imageUrl.toString(),
        '${origin}wp-content/uploads/2026/09/goods-base-140307419.jpg');
    expect(products.last.name, 'レインコート');
    expect(products.last.priceLabel, '¥4,900');
  });
  test('対象セクションだけを読み相対画像・文字参照を解決し重複を除く', () {
    final products = WebsiteGoods.parseHomepage(
        '${card()}${section('${card()}${card(href: 'https://bluesharks.base.shop/items/123/?x=1')}')}',
        origin);
    expect(products, hasLength(1));
    expect(products.single.name, '商品 & 鮫太朗');
    expect(products.single.priceLabel, '¥3,000');
    expect(products.single.imageUrl.toString(), '${origin}uploads/item.jpg');
  });
  test('未記載情報を捏造せず不正リンクや価格・欠損cardを除く', () {
    for (final href in [
      'javascript:alert(1)',
      'http://bluesharks.base.shop/items/123',
      'https://bluesharks.base.shop.evil.example/items/123',
      'https://user:pass@bluesharks.base.shop/items/123',
      'https://bluesharks.base.shop:444/items/123',
      'https://bluesharks.base.shop/',
      'https://bluesharks.base.shop/items/no-id'
    ]) {
      expect(WebsiteGoods.parseHomepage(section(card(href: href)), origin),
          isEmpty,
          reason: href);
    }
    for (final price in ['', '¥00,000,', '価格未定', '¥1,,234', '3,000']) {
      expect(WebsiteGoods.parseHomepage(section(card(price: price)), origin),
          isEmpty,
          reason: price);
    }
    expect(
        WebsiteGoods.parseHomepage(section(card(name: '')), origin), isEmpty);
    expect(
        WebsiteGoods.parseHomepage(
            section(card(image: 'data:image/png,x')), origin),
        isEmpty);
    expect(WebsiteGoods.parseHomepage('<html>maintenance</html>', origin),
        isEmpty);
  });
  test('動画とGOODSは1回の取得で同じHP応答から更新する', () async {
    var calls = 0;
    final controller = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      calls++;
      return '''$fixture<section class="top-movie"><a class="video-card"
        href="https://youtu.be/kVpQca35ECY"><img src="https://i.ytimg.com/vi/kVpQca35ECY/hqdefault.jpg"
        alt="チームPV"></a></section>''';
    }));
    await controller.fetchWebsiteContent();
    expect(calls, 1);
    expect(controller.websiteVideos, hasLength(1));
    expect(controller.websiteGoods, hasLength(14));
    await controller.fetchWebsiteContent();
    expect(calls, 1);
    await controller.fetchWebsiteContent(force: true);
    expect(calls, 2);
    controller.onClose();
  });
  test('再取得失敗は前回商品を保持し成功0件では旧商品を消す', () async {
    var calls = 0;
    final controller = HomeController(
        websiteVideoProvider: WebsiteVideoProvider(loadHomepage: (_) async {
      calls++;
      if (calls == 2) throw const WebsiteVideoRequestException();
      return calls == 3 ? '<html></html>' : fixture;
    }));
    await controller.fetchWebsiteContent();
    expect(controller.websiteGoods, hasLength(14));
    await controller.fetchWebsiteContent(force: true);
    expect(controller.websiteGoods, hasLength(14));
    await controller.fetchWebsiteContent(force: true);
    expect(controller.websiteGoods, isEmpty);
    controller.onClose();
  });
  testWidgets('320/375/430幅と文字1/2倍で横送りでき空状態は領域を追加しない', (tester) async {
    final products = WebsiteGoods.parseHomepage(fixture, origin);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
                body: WebsiteGoodsSection(
                    key: ValueKey('$width-$scale'), goods: products)),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text('GOODS'), findsOneWidget);
        expect(find.text(products.first.name), findsOneWidget);
        expect(find.text(products.first.priceLabel), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'width=$width textScale=$scale');
        await tester.drag(find.byKey(const ValueKey('website-goods-list')),
            Offset(-width, 0));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'width=$width textScale=$scale after scroll');
      }
    }
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const MaterialApp(
            home: Scaffold(body: WebsiteGoodsSection(goods: [])))));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
    expect(find.text('GOODS'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('商品カードは対応する公開商品URLだけを外部で開く', (tester) async {
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
    final products = WebsiteGoods.parseHomepage(fixture, origin);
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
            home: Scaffold(body: WebsiteGoodsSection(goods: products)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('goods-${products.first.url.path}')));
    await tester.pumpAndSettle();
    final args = calls.last.arguments as Map;
    expect(calls.last.method, 'launch');
    expect(args['url'], products.first.url.toString());
    expect(args['useSafariVC'], isFalse);
    expect(args['useWebView'], isFalse);
    expect(tester.takeException(), isNull);
  });
}
