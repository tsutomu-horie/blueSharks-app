import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/webview/privacy_policy_screen/controllers/privacy_policy_screen.controller.dart';

class PrivacyPolicyScreenControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyPolicyScreenController>(
      () => PrivacyPolicyScreenController(),
    );
  }
}
