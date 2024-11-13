import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class TeamController extends GetxController {

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.TEAM);

  }
}
