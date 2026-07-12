import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_detail/controllers/match_detail.controller.dart';

class MatchDetailControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchDetailController>(
      () => MatchDetailController(),
    );
  }
}
