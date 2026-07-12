import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class InfoProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<List<Post>> getMatchInformation({int page = 1}) async {
    // First get interview category IDs
    // final categoryUrl = Uri.parse('categories?parent=15&order=desc');
    // final categoryResponse = await get(categoryUrl.toString());

    List<String> categoryIds = ['1', '33', '34', '38']; // Base categories

    // if (!categoryResponse.hasError) {
    //   List<dynamic> categories = categoryResponse.body as List;
    //   categoryIds.addAll(categories.map((c) => c['id'].toString()));
    // }

    // Make single request with all category IDs
    final url = Uri.parse('posts?categories=${categoryIds.join(',')}&page=$page');
    debugPrint("load getMatchInformation ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }

    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getNotice({int page = 1}) async {
    final url = Uri.parse('posts?categories=1&page=$page');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    debugPrint("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getEventInformation({int page = 1}) async {
    final url = Uri.parse('posts?categories=33&page=$page');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    debugPrint("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getActivities({int page = 1}) async {
    final url = Uri.parse('posts?categories=34&page=$page');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    debugPrint("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getInterview({int page = 1}) async {
    final url = Uri.parse('posts?categories=38&page=$page');
    debugPrint("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(url.toString());
    if (response.hasError) {
      throw Exception('Failed to load match results because ${response}');
    }
    debugPrint("data ${response.body}");
    return (response.body as List).map((e) => Post.fromJson(e)).toList();

    // // First fetch parent categories
    // final categoryUrl = Uri.parse('categories?parent=15&order=desc');
    // final categoryResponse = await get(categoryUrl.toString());
    //
    // List<Post> allPosts = [];
    //
    //
    // if (!categoryResponse.hasError) {
    //   List<dynamic> categories = categoryResponse.body as List;
    //
    //   // Fetch posts for each category ID
    //   for (var category in categories) {
    //     int categoryId = category['id'];
    //
    //     final postsUrl = Uri.parse('posts?categories=$categoryId&page=$page');
    //     print("loadxxxx ${httpClient.baseUrl}${postsUrl.toString()}");
    //
    //     debugPrint("load ${httpClient.baseUrl}${postsUrl.toString()}");
    //
    //     final postsResponse = await get(postsUrl.toString());
    //     if (!postsResponse.hasError) {
    //       List<Post> posts = (postsResponse.body as List).map((e) => Post.fromJson(e)).toList();
    //       allPosts.addAll(posts);
    //     }
    //   }
    // }
    //
    // return allPosts;
  }
}
