import 'package:get/get.dart';

import '../../../../presentation/ListTopics/controllers/list_topics.controller.dart';

class ListTopicsControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListTopicsController>(
      () => ListTopicsController(),
    );
  }
}
