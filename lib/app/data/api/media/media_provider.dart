import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';

class MediaProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = Constants.baseUrl;
  }

  Future<Media> fetchMedia(String mediaId) async {
    final response = await get('media/$mediaId');

    print("fetch ${httpClient.baseUrl}/media/${mediaId}");
    if (response.hasError) {
      throw Exception('Failed to load media with ID: $mediaId');
    }

    print("finish with ${response.body}");

    return Media.fromJson(response.body);
  }
}