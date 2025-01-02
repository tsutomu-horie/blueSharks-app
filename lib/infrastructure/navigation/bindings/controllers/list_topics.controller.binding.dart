import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/info/list_info/controllers/list_info.dart';

class TopicListControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopicListController>(
      () => TopicListController(),
    );
  }
}
