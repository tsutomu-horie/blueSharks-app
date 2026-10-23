import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class Website extends RenewalWebsiteProvider {
  final calls = <String>[];
  @override
  Future<List<Category>> seasons({int page = 1}) async {
    calls.add('season/$page');
    return [];
  }

  @override
  Future<List<Category>> memberCategories({int page = 1}) async {
    calls.add('position/$page');
    return [];
  }

  @override
  Future<List<Member>> members(int id, {int page = 1}) async {
    calls.add('member/$id/$page');
    return [];
  }

  @override
  Future<List<MatchResultBySeason>> matches(int id, {int page = 1}) async {
    calls.add('match/$id/$page');
    return [];
  }
}

mixin NoLegacyRequests on GetConnect {
  @override
  Future<Response<T>> get<T>(String url,
          {Map<String, String>? headers,
          String? contentType,
          Map<String, dynamic>? query,
          T Function(dynamic)? decoder}) async =>
      throw StateError('Legacy website request: $url');
}

class Matches extends MatchProvider with NoLegacyRequests {
  Matches(Website website) : super(renewal: website);
}

class Members extends MemberProvider with NoLegacyRequests {
  Members(Website website) : super(renewal: website);
}

void main() {
  test('本番・テスト共に試合一覧とHOST/VISITORは新サイトのデータを使う', () async {
    final website = Website();
    final p = Matches(website);
    await p.getMatch(page: 2);
    await p.getMatchBySeasonId(51, page: 3);
    expect((await p.getMatchStatus('host')).rendered, 'host');
    expect((await p.getMatchStatus('visitor')).rendered, 'visitor');
    expect(website.calls, ['season/2', 'match/51/3']);
    p.httpClient.close();
    website.httpClient.close();
  });
  test('本番・テスト共に選手一覧の全入口が新サイトの分類を使う', () async {
    final website = Website();
    final p = Members(website);
    await p.fetchSinglePage(page: 2);
    await p.getCategories(page: 3);
    await p.getPlayersByCategory(52, page: 4);
    expect(website.calls, ['position/2', 'position/3', 'member/52/4']);
    p.httpClient.close();
    website.httpClient.close();
  });
}
