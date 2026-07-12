import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/controllers/register_member_fanclub.controller.dart';

class RegisterMemberFanclubControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterMemberFanclubController>(
      () => RegisterMemberFanclubController(),
    );
  }
}
