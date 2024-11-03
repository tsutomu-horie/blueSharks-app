import 'dart:convert';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class GalleryProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrlAuthApi;
  }

  Future<List<Album>> fetchGalleryList(int categoryId, String year, Function onError) async {
    final response = await get('galleries/albums?category_id=$categoryId&year=${year}');

    if (response.hasError) {
      throw Exception('Failed to load media with I');
    }

    print("finish with ${response.body}");

    return (response.body['data'] as List)
        .map((json) => Album.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlbumDetail>> fetchGalleryDetail(int albumId, Function onError) async {
    final response = await get('galleries?album_id=$albumId');
    print('fetch galleries?albums_id=$albumId');

    if (response.hasError) {
      throw Exception('Failed to load media with I');
    }

    print("finish with ${response.body}");

    return (response.body['data'] as List)
        .map((json) => AlbumDetail.fromJson(json as Map<String, dynamic>))
        .toList();;
  }
}