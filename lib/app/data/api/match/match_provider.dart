import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MatchProvider extends GetConnect {
  @override
  void onInit() {
    print("initttt");
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<MatchResult>> getMatch({int page = 1}) async {
    final url = Uri.parse('categories?parent=24&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => MatchResult.fromJson(e)).toList();
  }

  Future<List<MatchResultBySeason>> getMatchBySeasonId(int seasonId, {int page = 1}) async {
    final url = Uri.parse('posts?categories=$seasonId&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());

    if (response.hasError) {
      print('Error: Failed to load match results. Status: ${response.statusCode}, Message: ${response.statusText}, Body: ${response.body}');
      throw Exception('Failed to load match results: ${response.statusText} (Code: ${response.statusCode})');
    }
    return (response.body as List).map((e) => MatchResultBySeason.fromJson(e)).toList();
  }
}
