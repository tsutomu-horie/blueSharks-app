import 'package:get/get.dart';

import 'package:koto_blue_sharks/presentation/qr_campaign/controllers/qr_campaign.controller.dart';

class QrCampaignControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QrCampaignController>(() => QrCampaignController());
  }
}
