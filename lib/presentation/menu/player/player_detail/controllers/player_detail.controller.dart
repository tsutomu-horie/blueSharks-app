import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/media/media_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

class PlayerDetailController extends GetxController {
  final MediaProvider mediaProvider = MediaProvider();


  @override
  void onInit() async {
    super.onInit();
    mediaProvider.onInit();

    AnalyticsService.logPageView(Routes.PLAYER_DETAIL);

  }
}
