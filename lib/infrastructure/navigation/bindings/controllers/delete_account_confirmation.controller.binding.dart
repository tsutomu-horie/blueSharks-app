import 'package:get/get.dart';
import 'package:koto_blue_sharks/presentation/profile/delete_account_confirmation/controllers/delete_account_confirmation.controller.dart';

class DeleteAccountConfirmationControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeleteAccountConfirmationController>(
      () => DeleteAccountConfirmationController(),
    );
  }
}
