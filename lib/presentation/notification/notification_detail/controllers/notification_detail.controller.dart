import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import '../../../../app/data/api/auth/AuthToken.dart';
import '../../../../app/data/api/auth/auth_provider.dart';

class NotificationDetailController extends GetxController {

  final AuthProvider apiProvider = AuthProvider();

  String formatJapaneseDate(String dateString) {
    DateTime parsedDate = DateTime.parse(dateString);
    // Format the date to 'yyyy 年 MM 月 dd 日'
    String formattedDate = DateFormat('yyyy 年 M 月 d 日', 'ja_JP').format(parsedDate);
    return formattedDate;
  }

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.logPageView(Routes.NOTIFICATION_DETAIL);
  }

  void readNotification(String id) async {
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    if (token != null) {
      apiProvider.readNotification(id);
    }
  }


}
