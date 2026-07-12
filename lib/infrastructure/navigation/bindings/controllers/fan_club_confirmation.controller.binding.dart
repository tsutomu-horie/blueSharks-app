import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/register/fan_club_confirmation/controllers/fan_club_confirmation.controller.dart';

class FanClubConfirmationControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FanClubConfirmationController>(
      () => FanClubConfirmationController(),
    );
  }
}
