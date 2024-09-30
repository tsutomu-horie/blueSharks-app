import 'package:get/get.dart';

import '../../../../presentation/MatchDetail/controllers/match_detail.controller.dart';

class MatchDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchDetailController>(
      () => MatchDetailController(),
    );
  }
}
