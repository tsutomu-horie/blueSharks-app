import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MemberProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Category>> getMember({int page = 1}) async {
    final url = Uri.parse('categories?parent=2&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Category.fromJson(e)).toList();
  }
}