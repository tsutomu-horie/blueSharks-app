import 'package:get/get.dart';

import '../../../../presentation/PrivacyPolicyScreen/controllers/privacy_policy_screen.controller.dart';

class PrivacyPolicyScreenControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyPolicyScreenController>(
      () => PrivacyPolicyScreenController(),
    );
  }
}
