import 'dart:convert';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MediaProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<Media> fetchMedia(String mediaId) async {
    httpClient.baseUrl = Constants.baseUrl;
    final response = await get('media/$mediaId');

    print("fetch ${httpClient.baseUrl}/media/${mediaId}?_fields={id,media_details,content,custom_field}");
    if (response.hasError) {
      throw Exception('Failed to load media with ID: $mediaId');
    }

    print("finish with ${response.body}");

    return Media.fromJson(response.body);
  }

  //fetch image with end point : /wp-json/wp/v2/media?parent=19702
  Future<Media> fetchParentMedia(String mediaId) async {
    httpClient.baseUrl = Constants.baseUrl;
    final response = await get('media?parent=$mediaId');

    print("fetch image parent ${httpClient.baseUrl}media?parent=$mediaId");
    if (response.hasError) {
      throw Exception('Failed to load media with ID: $mediaId');
    }

    print("finish with ${response.body}");

    List<dynamic> bodyList = response.body;

    if (bodyList.isEmpty) {
      throw Exception('No media found with ID: $mediaId');
    }

    // Parse the first item in the list to Media
    final media = Media.fromJson(bodyList.first);

    return media;
  }

  Future<List<WallpaperCategory>> fetchWallpaper(Function(String errorMessage) onSucces) async {
    // final response = await get('wallpapers');
    httpClient.baseUrl = Constants.baseUrlAuthApi;
    final url = Uri.parse('wallpapers');
    print("load ${httpClient.baseUrl}${url.toString()}");

    final response = await get(
      url.toString() // Send the body in the request
    );

    print("Login successful2 , ${response.body}");

    if (response.hasError) {
      onSucces("${response.statusText}");
      throw Exception('Failed to login: ${response.statusText}');
    }

    print("Login successful, received data: ${response.body}");

      return (response.body['data'] as List)
        .map((json) => WallpaperCategory.fromJson(json as Map<String, dynamic>))
        .toList();

    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body)['data'] as List;
    //
    //   return data
    //       .map((categoryJson) =>
    //       WallpaperCategory.fromJson(categoryJson as Map<String, dynamic>))
    //       .toList();
    // } else {
    //   throw Exception('Failed to load wallpapers');
    // }
  }
}