import 'package:get/get.dart';

import '../../../../presentation/FanClubConfirmation/controllers/fan_club_confirmation.controller.dart';

class FanClubConfirmationControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FanClubConfirmationController>(
      () => FanClubConfirmationController(),
    );
  }
}
