import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';

class PlayerDetailController extends GetxController {
  final MediaProvider mediaProvider = MediaProvider();

  @override
  void onInit() async {
    super.onInit();
    mediaProvider.onInit();
  }
}
