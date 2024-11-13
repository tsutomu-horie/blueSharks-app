import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class DetailInfoController extends GetxController {
  final MediaProvider mediaProvider = MediaProvider();

  @override
  void onInit() {
    super.onInit();
    mediaProvider.onInit();

    AnalyticsService.logPageView(Routes.DETAIL_INFO);

  }

  Future<String> getNewsImage(String mediaId) async {
    final imageData = await mediaProvider.fetchParentMedia(mediaId);
    print("GET NEWS IMAGE ${imageData}");
    final image = imageData?.media_details.sizes.thumbnail.source_url;
    print("GET NEWS IMAGE ${mediaId}, ${image}");
    return image ?? "";
  }
}
