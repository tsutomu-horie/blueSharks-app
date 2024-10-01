import 'package:get/get.dart';

import '../../../../presentation/member/controllers/member.controller.dart';

class MemberControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MemberController>(
      () => MemberController(),
    );
  }
}
