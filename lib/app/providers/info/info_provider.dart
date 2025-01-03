import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class InfoProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Post>> getMatchInformation({int page = 1}) async {
    final url = Uri.parse('posts?categories=33&page=$page');
    print("load getMatchInformation ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getNotice({int page = 1}) async {
    final url = Uri.parse('posts?categories=1&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getEventInformation({int page = 1}) async {
    final url = Uri.parse('posts?categories=34&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getActivities({int page = 1}) async {
    final url = Uri.parse('posts?categories=39&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getInterview({int page = 1}) async {
    final url = Uri.parse('posts?categories=39&page=$page');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    print("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }
}
