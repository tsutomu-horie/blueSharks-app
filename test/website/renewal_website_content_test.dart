import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/data/models/website/renewal_website_content.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

String fixture(String name) =>
    File('test/website/fixtures/$name').readAsStringSync();
List<Map<String, dynamic>> posts(String kind) =>
    (jsonDecode(fixture('$kind-posts.json')) as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

class _Media extends MediaProvider {
  int calls = 0;
  @override
  Future<Media> fetchMedia(String id) async {
    calls++;
    throw StateError('Legacy media lookup: $id');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final site = Uri.parse('https://blue-sharks.donati.jp/');

  test('新member投稿を既存Memberへ変換し、一覧画像とポジションを保持する', () {
    final cards =
        RenewalWebsiteContent.memberCards(fixture('members.html'), site);
    final post = posts('member').firstWhere((item) => item['id'] == 17265);
    final member =
        RenewalWebsiteContent.member(post, 61, 'prop', cards[17265], site);
    expect(member.id, 17265);
    expect(member.title.rendered, '志村 太基');
    expect(member.categoryId, 61);
    expect(member.categorySlug, 'prop');
    expect(member.custom_field!.profile_image_1!.single,
        contains('/wp-content/uploads/2025/01/'));
    expect(member.date, post['date']);
  });

  test('選手詳細のプロフィール・一問一答・YouTube・写真を既存画面の項目へ渡す', () {
    final post = posts('member').firstWhere((item) => item['id'] == 17265);
    final summary = RenewalWebsiteContent.member(post, 61, 'prop', null, site);
    final detail = RenewalWebsiteContent.memberDetail(
        fixture('player.html'), summary, site);
    final data = detail.custom_field!;
    expect(data.data_position, ['プロップ']);
    expect(data.data_number, ['55']);
    expect(data.data_birthday, ['1995年9月6日']);
    expect(data.data_height_weight, ['170cm／100kg']);
    expect(data.words_nickname, ['ヤンセン']);
    expect(data.words_playsseason, ['スクラム']);
    expect(data.words_goodplay, ['仲が良い']);
    expect(data.youtube_embed_src, ['https://youtube.com/embed/wSMXfNG2v08']);
    expect(data.main_image!.single, endsWith('-1.jpg'));
    expect(data.profile_image_2!.single, endsWith('-1.png'));
    expect(data.graph_image, isNull);
    expect(data.position_image, isNull);
  });

  test('スタッフの役職も既存プロフィールの役職欄へ渡す', () {
    final post = {
      ...posts('member').first,
      'id': 17338,
      'link': site.resolve('/members/staff/2024/01/17338/').toString()
    };
    final summary = RenewalWebsiteContent.member(post, 55, 'staff', null, site);
    final detail = RenewalWebsiteContent.memberDetail(
        fixture('staff.html'), summary, site);
    expect(detail.custom_field!.data_position, ['ヘッドコーチ兼マーケティングリーダー']);
  });

  test('新match投稿26件を日程カードに照合し、シーズンと日付を維持する', () {
    final cards =
        RenewalWebsiteContent.matchCards(fixture('schedule.html'), site);
    final data = posts('match')
        .map((post) =>
            RenewalWebsiteContent.match(post, 51, cards[post['id']]!, site))
        .toList();
    expect(data, hasLength(26));
    expect(data.map((match) => match.id).toSet(), hasLength(26));
    final match = data.firstWhere((match) => match.id == 25207);
    expect(match.categories, [51]);
    expect(match.custom_field.gameDate, ['2026年10月10日（土）']);
    expect(match.custom_field.team_score_1, ['14']);
    expect(match.custom_field.team_score_2, ['54']);
    expect(match.custom_field.game_result, ['LOSE']);
    final upcoming = data.firstWhere(
        (match) => match.custom_field.gameDate!.single.contains('12月12日'));
    expect(upcoming.custom_field.team_score_1, ['']);
    expect(upcoming.custom_field.team_score_2, ['']);
  });

  test('試合詳細は前後半T/G/PG/DG・メンバー・主将・経過・写真を保持する', () {
    final post = posts('match').firstWhere((item) => item['id'] == 25207);
    final cards =
        RenewalWebsiteContent.matchCards(fixture('schedule.html'), site);
    final summary = RenewalWebsiteContent.match(post, 51, cards[25207]!, site);
    final detail =
        RenewalWebsiteContent.matchDetail(fixture('match.html'), summary, site);
    final data = detail.custom_field;
    expect(data.team_T_first_half_1, ['1']);
    expect(data.team_T_second_half_2, ['3']);
    expect(data.team_G_first_half_2, ['4']);
    expect(data.team_RESULT_first_half_2, ['33']);
    expect(data.team_RESULT_second_half_2, ['21']);
    expect(data.member_starting, hasLength(15));
    expect(data.member_starting!.first, '1 野村 三四郎');
    expect(data.member_captain, ['野村 三四郎']);
    expect(data.member_reserves!.first, 'R 伊藤 潤乃助');
    expect(data.photos, hasLength(8));
    expect(detail.content.rendered, contains('試合経過'));
    expect(detail.content.rendered, isNot(contains('header__global')));
  });

  test('選手・シーズンの新taxonomyを利用し、一覧HTMLは1回にまとめる', () async {
    final requests = <Uri>[];
    final provider = RenewalWebsiteProvider(load: (url) async {
      requests.add(url);
      if (url.path.endsWith('/member_position')) {
        return fixture('positions.json');
      }
      if (url.path.endsWith('/member')) return fixture('member-posts.json');
      if (url.path == '/members/') return fixture('members.html');
      if (url.path.endsWith('/season')) return fixture('seasons.json');
      if (url.path.endsWith('/match')) return fixture('match-posts.json');
      if (url.path.contains('/season/')) return fixture('schedule.html');
      throw StateError('Unexpected request: $url');
    });
    final categories = await provider.memberCategories();
    expect(categories.firstWhere((item) => item.slug == 'prop').id, 61);
    expect(await provider.members(61), hasLength(12));
    expect(await provider.members(61), hasLength(12));
    expect(requests.where((url) => url.path == '/members/'), hasLength(1));
    final seasons = await provider.seasons();
    final season =
        seasons.firstWhere((item) => item.slug == 'season_2026_2027');
    expect(season.id, 51);
    expect(season.count, 26);
    expect(await provider.matches(51), hasLength(26));
    expect(requests.last.path, '/schedule-and-result/season/season_2026_2027/');
    expect(requests.where((url) => url.path.endsWith('/posts')), isEmpty);
    provider.httpClient.close();
  });

  test('一覧の読込失敗はキャッシュを固定せず、再試行で回復する', () async {
    var htmlCalls = 0;
    final provider = RenewalWebsiteProvider(load: (url) async {
      if (url.path.endsWith('/member')) return fixture('member-posts.json');
      if (++htmlCalls == 1) throw const RenewalWebsiteRequestException(503);
      return fixture('members.html');
    });
    await expectLater(
        provider.members(61), throwsA(isA<RenewalWebsiteRequestException>()));
    expect(await provider.members(61), hasLength(12));
    expect(htmlCalls, 2);
    provider.httpClient.close();
  });

  test('末尾ページだけを終端として扱い、他のHTTP400は失敗を隠さない', () async {
    var endOfPages = true;
    final provider = RenewalWebsiteProvider(load: (_) async {
      throw RenewalWebsiteRequestException(
          400, endOfPages ? 'rest_post_invalid_page' : 'rest_invalid_param');
    });
    expect(await provider.matches(51, page: 2), isEmpty);
    endOfPages = false;
    await expectLater(provider.matches(51, page: 2),
        throwsA(isA<RenewalWebsiteRequestException>()));
    provider.httpClient.close();
  });

  test('不正な詳細・異サイトURLは受け入れず、欠損データを捏造しない', () async {
    final post = posts('member').first;
    expect(
        () => RenewalWebsiteContent.member(
            {...post, 'link': 'https://evil.example/members/x/2025/01/1/'},
            61,
            'prop',
            null,
            site),
        throwsFormatException);
    expect(RenewalWebsiteContent.siteUrl(site, 'https://%'), isNull);
    expect(RenewalWebsiteContent.siteUrl(site, 'http://blue-sharks.donati.jp/'),
        isNull);
    final member = RenewalWebsiteContent.member(post, 61, 'prop', null, site);
    expect(
        () => RenewalWebsiteContent.memberDetail(
            '<main>maintenance</main>', member, site),
        throwsFormatException);
    final provider = RenewalWebsiteProvider(load: (_) async => '[]');
    await expectLater(
        provider.memberDetail(
            member.copyWith(link: 'https://evil.example/members/1/')),
        throwsFormatException);
    provider.httpClient.close();
  });

  test('過去シーズンも新seasonの実IDで選択し、旧投稿のない試合を表示できる', () {
    final cards =
        RenewalWebsiteContent.matchCards(fixture('old-season.html'), site);
    final posts = (jsonDecode(fixture('old-matches.json')) as List)
        .cast<Map<String, dynamic>>();
    final matches = posts
        .map((post) =>
            RenewalWebsiteContent.match(post, 44, cards[post['id']]!, site))
        .toList();
    expect(matches, hasLength(10));
    expect(matches.every((match) => match.categories.single == 44), isTrue);
    expect(
        matches
            .every((match) => match.custom_field.gameDate!.single.isNotEmpty),
        isTrue);
  });

  test('新サイトの画像URLは直接使い、従来のメディアIDは既存処理を維持する', () async {
    final media = _Media();
    const image = 'https://blue-sharks.donati.jp/wp-content/uploads/test.png';
    expect(await getImage(media, image), image);
    expect(await getImage(media, 'null'), '');
    expect(media.calls, 0);
    final match = MatchProvider();
    expect(await getAdditionalInfo(media, match, image, 'host'),
        {'image': image, 'matchStatus': 'host'});
    expect(media.calls, 0);
    expect(await getImage(media, '123', retries: 1), '');
    expect(media.calls, 1);
    media.httpClient.close();
    match.httpClient.close();
    match.renewal.httpClient.close();
  });
}
