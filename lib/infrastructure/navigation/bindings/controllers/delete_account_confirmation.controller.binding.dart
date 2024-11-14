import 'package:get/get.dart';

import '../../../../presentation/DeleteAccountConfirmation/controllers/delete_account_confirmation.controller.dart';

class DeleteAccountConfirmationControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeleteAccountConfirmationController>(
      () => DeleteAccountConfirmationController(),
    );
  }
}
