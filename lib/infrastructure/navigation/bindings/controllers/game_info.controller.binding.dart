import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_list/controllers/match_list_screen.dart';

class MatchListControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchListController>(
      () => MatchListController(),
    );
  }
}
