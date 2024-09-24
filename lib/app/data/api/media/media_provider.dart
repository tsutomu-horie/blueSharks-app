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

  //fetch image with end point : /wp-json/wp/v2/media?parent=19702
  Future<Media> fetchParentMedia(String mediaId) async {
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

    print("get media ${media.title}");

    return media;
  }
}