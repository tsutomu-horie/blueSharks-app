import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/match/match_provider.dart';
import 'package:koto_blue_sharks/app/providers/member/member_provider.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';

mixin Responses on GetConnect {
  int status = 400;
  dynamic payload = {'code': 'rest_post_invalid_page'};
  @override
  Future<Response<T>> get<T>(String url,
          {Map<String, String>? headers,
          String? contentType,
          Map<String, dynamic>? query,
          T Function(dynamic)? decoder}) async =>
      Response<T>(
          statusCode: status, statusText: 'test response', body: payload as T);
}

class Matches extends MatchProvider with Responses {}

class Members extends MemberProvider with Responses {}

void main() {
  if (!AppEnvironment.usesProductionServices) {
    test('旧本番APIの互換テストはAPP_ENV=productionで実行する', () {}, skip: true);
    return;
  }
  test('旧試合APIの最終ページだけを終端とし、先頭や他の400はエラーにする', () async {
    final p = Matches();
    expect(await p.getMatchBySeasonId(1, page: 2), isEmpty);
    await expectLater(p.getMatchBySeasonId(1, page: 1), throwsException);
    p.payload = {'code': 'rest_invalid_param'};
    await expectLater(p.getMatchBySeasonId(1, page: 2), throwsException);
    p.httpClient.close();
    p.renewal.httpClient.close();
  });
  test('旧選手APIの失敗を未登録と混同せず、実際の0件だけ空として返す', () async {
    final p = Members();
    p.status = 500;
    await expectLater(p.getCategories(), throwsException);
    await expectLater(p.getPlayersByCategory(1), throwsException);
    p.status = 200;
    p.payload = [];
    expect(await p.getCategories(), isEmpty);
    expect(await p.getPlayersByCategory(1), isEmpty);
    p.status = 400;
    p.payload = {'code': 'rest_post_invalid_page'};
    expect(await p.getPlayersByCategory(1, page: 2), isEmpty);
    p.httpClient.close();
    p.renewal.httpClient.close();
  });
}
