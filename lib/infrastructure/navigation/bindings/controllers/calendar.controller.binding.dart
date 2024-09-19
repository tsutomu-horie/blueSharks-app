import 'package:get/get.dart';

import '../../../../presentation/calendar/controllers/calendar.controller.dart';

class CalendarControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CalendarController>(
      () => CalendarController(),
    );
  }
}
