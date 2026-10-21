import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/constant.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:koto_blue_sharks/app/providers/website/renewal_website_provider.dart';

class MatchProvider extends GetConnect {
  MatchProvider({RenewalWebsiteProvider? renewal})
      : renewal = renewal ?? RenewalWebsiteProvider();
  final RenewalWebsiteProvider renewal;
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Category>> getMatch({int page = 1}) async {
    if (!AppEnvironment.usesProductionServices) {
      return renewal.seasons(page: page);
    }
    final url = Uri.parse('categories?parent=24&page=$page&per_page=100');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    return (response.body as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<Rendered> getMatchStatus(String id) async {
    if (!AppEnvironment.usesProductionServices &&
        const {'host', 'visitor'}.contains(id)) {
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
      {int page = 1}) async {
    if (!AppEnvironment.usesProductionServices) {
      return renewal.matches(seasonId, page: page);
    }
    final url = Uri.parse('posts?categories=$seasonId&page=$page&per_page=10');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());

    if (page > 1 &&
        response.statusCode == 400 &&
        response.body is Map &&
        response.body['code'] == 'rest_post_invalid_page') return [];
    if (response.hasError) {
      print(
          'Error: Failed to load match results. Status: ${response.statusCode}, Message: ${response.statusText}, Body: ${response.body}');
      throw Exception(
          'Failed to load match results: ${response.statusText} (Code: ${response.statusCode})');
    }
    return (response.body as List)
        .map((e) => MatchResultBySeason.fromJson(e))
        .toList();
  }
}
