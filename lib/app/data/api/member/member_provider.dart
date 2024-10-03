import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MemberProvider extends GetConnect {

  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Category>> fetchSinglePage({int page = 1}) async {
    final url = Uri.parse('categories?parent=2&page=$page');
    print("Fetching data from ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load data. Error: ${response.statusText}');
    }

    // Parse the response body
    final List data = response.body;
    print("Data fetched for page $page: $data");

    return data.map((e) => Category.fromJson(e)).toList();
  }

  // Fetch categories
  Future<List<Category>> getCategories({int page = 1}) async {
    final response = await get('categories?parent=2&page=$page');
    if (response.hasError || response.body.isEmpty) {
      return []; // Return an empty list if no data or error occurs
    }

    return (response.body as List).map((categoryJson) {
      return Category.fromJson(categoryJson);
    }).toList();
  }

  // Fetch players by category
  Future<List<Member>> getPlayersByCategory(int categoryId, {int page = 1}) async {
    final response = await get('posts?categories=$categoryId&page=$page');
    if (response.hasError || response.body.isEmpty) {
      return []; // Return an empty list if no data or error occurs
    }

    return (response.body as List).map((playerJson) {
      return Member.fromJson(playerJson);
    }).toList();
  }
}