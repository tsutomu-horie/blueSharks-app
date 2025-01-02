import 'package:get/get.dart';

import '../../../../presentation/profile/mypage/controllers/mypage.controller.dart';

class MypageControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MypageController>(
      () => MypageController(),
    );
  }
}
