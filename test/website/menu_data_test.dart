import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/website/renewal_website_content.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_list/controllers/match_list_screen.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_list/controllers/player_list.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/player/player_detail/controllers/player_detail.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/gallery/gallery_list/controllers/gallery.controller.dart';
import 'package:koto_blue_sharks/presentation/menu/gallery/gallery_list/gallery.screen.dart';

String fixture(String name) =>
    File('test/website/fixtures/$name').readAsStringSync();
final site = Uri.parse('https://blue-sharks.donati.jp/');
List<Map<String, dynamic>> records(String name) =>
    (jsonDecode(fixture(name)) as List).cast<Map<String, dynamic>>();

RenewalWebsiteProvider source({List<Uri>? requests}) =>
    RenewalWebsiteProvider(load: (uri) async {
      requests?.add(uri);
      if (uri.path == '/members/') return fixture('current-members.html');
      if (uri.path.contains('/schedule-and-result/season/'))
        return fixture('current-schedule.html');
      final file = {
        '/wp-json/wp/v2/member_position': 'current-positions.json',
        '/wp-json/wp/v2/season': 'current-seasons.json',
        '/wp-json/wp/v2/member': 'current-member-posts.json',
        '/wp-json/wp/v2/match': 'current-match-posts.json',
      }[uri.path];
      if (file == null) throw StateError('Unexpected request $uri');
      var data = records(file);
      if (uri.path.endsWith('/match'))
        data = data
            .where((p) => (p['season'] as List)
                .contains(int.parse(uri.queryParameters['season']!)))
            .toList();
      final page = int.parse(uri.queryParameters['page']!);
      final count = int.parse(uri.queryParameters['per_page']!);
      return jsonEncode(data.skip((page - 1) * count).take(count).toList());
    });

class Gallery extends GalleryProvider {
  Gallery(this.load);
  final Future<List<Album>> Function(int, String) load;
  final requests = <String>[];
  @override
  Future<List<Album>> fetchGalleryList(
      int categoryId, String year, Function onError) {
    requests.add('$categoryId/$year');
    return load(categoryId, year);
  }
}

class ScreenGallery extends GalleryController {
  ScreenGallery(GalleryProvider provider) : super(apiProvider: provider);
  @override
  // This test supplies its own loader and skips native Firebase analytics startup.
  // ignore: must_call_super
  void onInit() {
    apiProvider.onInit();
    getGalleryList();
  }
}

class MatchApi extends MatchProvider {
  MatchApi(this.values);
  final List<MatchResultBySeason> values;
  @override
  Future<List<MatchResultBySeason>> getMatchBySeasonId(int id,
          {int page = 1}) async =>
      values.skip((page - 1) * 10).take(10).toList();
}

class DetailSource extends RenewalWebsiteProvider {
  final pending = <Completer<Member>>[];
  @override
  Future<Member> memberDetail(Member member) {
    final c = Completer<Member>();
    pending.add(c);
    return c.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);
  test('現在の新APIから既存一覧に81名を表示し、分類の件数が古くても全員取得する', () async {
    final requests = <Uri>[];
    final c = PlayerListController(
        memberProvider: MemberProvider(renewal: source(requests: requests)));
    await c.getAllMembers();
    expect(c.errorMessage.value, isEmpty);
    expect(c.isLoading.value, isFalse);
    final members = c.categoryPlayers.values.expand((v) => v).toList();
    expect(members, hasLength(81));
    expect(members.map((m) => m.id).toSet(), hasLength(81));
    expect(
        members.every((m) => m.custom_field!.profile_image_1!.single
            .startsWith('https://blue-sharks.donati.jp/')),
        isTrue);
    expect(
        c
            .groupPlayersByCategory(c.categoryPlayers)
            .expand((g) => g.playerGroups)
            .expand((g) => g.players),
        hasLength(81));
    expect(requests.where((u) => u.path.endsWith('/member')), hasLength(1));
    expect(requests.where((u) => u.path == '/members/'), hasLength(1));
    c.addGroupKey('FW');
    final key = c.groupKeys['FW'];
    c.addGroupKey('FW');
    expect(c.groupKeys['FW'], same(key));
    c.onDelete();
  });
  test('GAME INFOは新seasonを使って今季26試合を取得し、再読込でも同じシーズンを保つ', () async {
    final c = MatchListController(
        apiProvider: MatchProvider(renewal: source()),
        now: () => DateTime(2026, 10, 21));
    await c.fetchMatchResult();
    expect(c.errorMessage.value, isEmpty);
    expect(c.seasonSlug.value, 'season_2026_2027');
    expect(c.listMatch.value, hasLength(26));
    expect(
        c.listMatch.value
            .every((m) => m.custom_field.gameDate!.single.isNotEmpty),
        isTrue);
    await c.fetchMatchResult();
    expect(c.listMatch.value, hasLength(26));
    c.onDelete();
  });
  test('古い件数が0でも実ページをたどり、10件を越える試合を落とさない', () async {
    final post = records('current-match-posts.json').first;
    final cards = RenewalWebsiteContent.matchCards(
        fixture('current-schedule.html'), site);
    final match =
        RenewalWebsiteContent.match(post, 51, cards[post['id']]!, site);
    final c = MatchListController(
        apiProvider:
            MatchApi(List.generate(12, (i) => match.copyWith(id: i + 1))));
    expect(await c.getLatestPosts(51, 0), hasLength(12));
    c.onDelete();
  });
  test('GALLERYの通信失敗でも読み込みが終了し、再試行で空状態に回復する', () async {
    var count = 0;
    final c = GalleryController(apiProvider: Gallery((_, __) async {
      if (++count == 1) throw StateError('offline');
      return [];
    }));
    await c.getGalleryList();
    expect(c.isLoading.value, isFalse);
    expect(c.errorMessage.value, isNotEmpty);
    await c.onRefresh();
    expect(c.errorMessage.value, isEmpty);
    expect(c.album, isEmpty);
    c.onDelete();
  });
  test('GALLERYで区分を素早く変えても遅い旧区分の応答が新しい表示を上書きしない', () async {
    final old = Completer<List<Album>>();
    final latest = Completer<List<Album>>();
    final c = GalleryController(
        apiProvider: Gallery((id, _) => id == 1 ? old.future : latest.future));
    final a = c.getGalleryList();
    final b = c.onSwitch(2, 'EVENT');
    latest.complete([Album(id: 2, name: 'event')]);
    await b;
    old.complete([Album(id: 1, name: 'old')]);
    await a;
    expect(c.album.single.id, 2);
    expect(c.selectedIndex.value, 2);
    expect(c.isLoading.value, isFalse);
    c.onDelete();
  });
  test('選手詳細A→B→Aで旧Aの遅い応答が最新Aを上書きしない', () async {
    final provider = DetailSource();
    final c = PlayerDetailController(website: provider);
    final p = records('current-member-posts.json').first;
    final member = RenewalWebsiteContent.member(p, 55, 'staff', null, site);
    final a = c.loadDetail(member);
    final b = c.loadDetail(member.copyWith(id: 2));
    final fresh = c.loadDetail(member);
    provider.pending[2]
        .complete(member.copyWith(title: Title(rendered: 'fresh')));
    await fresh;
    provider.pending[0].complete(member);
    provider.pending[1].complete(member.copyWith(id: 2));
    await a;
    await b;
    expect(c.detail.value!.title.rendered, 'fresh');
    c.onDelete();
  });
  testWidgets('GALLERYの未登録案内を表示し、再ビルドでフィルタをリセットしない', (tester) async {
    final provider = Gallery((_, __) async => []);
    final c = ScreenGallery(provider);
    Get.put<GalleryController>(c);
    Widget app() => ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => GetMaterialApp(home: const GalleryScreen()));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('この条件の写真はまだ登録されていません。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gallery-category-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    final count = provider.requests.length;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(c.selectedIndex.value, 2);
    expect(c.selectedYear.value, '2026');
    expect(provider.requests.length, count);
    expect(tester.takeException(), isNull);
  });
}
