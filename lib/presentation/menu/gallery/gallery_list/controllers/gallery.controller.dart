import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class GalleryController extends GetxController {
  var selectedIndex = 1.obs;
  var selectedName = LocaleKeys.game.tr.obs;
  var selectedYear = "".obs;
  final GalleryProvider apiProvider = GalleryProvider();
  final RxList<Album> album = <Album>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();
    getGalleryList();

    AnalyticsService.logPageView(Routes.GALLERY);

  }

  void onRefresh() {
    // selectedIndex.value = 1;
    // selectedName.value = LocaleKeys.game.tr;
    // selectedYear.value = "";
    onSwitch(selectedIndex.value, selectedName.value);
  }

  void onSwitch(int index, String name) {
    print("switch $index $name");
    selectedIndex.value = index;
    selectedName.value =  name;
    getGalleryList();
  }

  void getGalleryList() async {
    isLoading.value = true;

    print("get year data ${selectedYear.value}");
    final response = await apiProvider.fetchGalleryList(
      selectedIndex.value,
      selectedYear.value,
          (){
        // Utils.showError(context, LocaleKeys.error_login_message.tr, null );
      },
    );

    album.value = response;
    print("index == ${album.length}");
    isLoading.value = false;
  }
}
