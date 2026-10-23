import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/providers/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class GalleryController extends GetxController {
  GalleryController({GalleryProvider? apiProvider})
      : apiProvider = apiProvider ?? GalleryProvider();
  final selectedIndex = 1.obs;
  final selectedName = LocaleKeys.game.tr.obs;
  final selectedYear = ''.obs;
  final GalleryProvider apiProvider;
  final album = <Album>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    getGalleryList();
    AnalyticsService.logPageView(Routes.GALLERY);
  }

  Future<void> onRefresh() => getGalleryList();

  Future<void> onSwitch(int index, String name) {
    selectedIndex.value = index;
    selectedName.value = name;
    return getGalleryList();
  }

  Future<void> getGalleryList() async {
    final request = ++_request;
    final category = selectedIndex.value;
    final year = selectedYear.value;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response =
          await apiProvider.fetchGalleryList(category, year, () {});
      if (!isClosed && request == _request) album.assignAll(response);
    } catch (_) {
      if (!isClosed && request == _request)
        errorMessage.value = '写真を取得できませんでした。';
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _request++;
    apiProvider.httpClient.close();
    super.onClose();
  }

  String imageCompressor(String image) =>
      'https://wsrv.nl/?url=${Uri.encodeComponent(image)}&dpr=2';
}
