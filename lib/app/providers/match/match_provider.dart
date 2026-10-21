import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/constant.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class MatchProvider extends GetConnect {
  MatchProvider({RenewalWebsiteProvider? renewal})
      : renewal = renewal ?? RenewalWebsiteProvider();
  final RenewalWebsiteProvider renewal;
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Category>> getMatch({int page = 1}) =>
      renewal.seasons(page: page);

  Future<Rendered> getMatchStatus(String id) async {
    if (const {'host', 'visitor'}.contains(id)) {
      return Rendered(rendered: id);
    }
    final url = Uri.parse('media/$id?_fields=id,title,content,custom_field');
    print("load getMatchStatus ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because $response');
    }
    print("data getMatchStatus ${response.body}");
    return Rendered.fromJson(response.body['title']);
  }

  Future<List<MatchResultBySeason>> getMatchBySeasonId(int seasonId,
          {int page = 1}) =>
      renewal.matches(seasonId, page: page);
}
