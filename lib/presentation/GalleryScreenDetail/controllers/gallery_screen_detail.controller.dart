import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/gallery/gallery_provider.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';

class GalleryScreenDetailController extends GetxController {
  final GalleryProvider apiProvider = GalleryProvider();
  final RxList<AlbumDetail> album = <AlbumDetail>[].obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();
    // getGalleryList();
  }

  void getGalleryList(int albumId) async {
    final response = await apiProvider.fetchGalleryDetail(albumId, (){
      print("error");
    });

    album.value = response;
    print("getvalue ${albumId} ${response}");
    print("index == ${album.length}");
  }
}
