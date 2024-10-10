import 'package:get/get.dart';

import '../../../../presentation/team/controllers/team.controller.dart';

class TeamControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamController>(
      () => TeamController(),
    );
  }
}
