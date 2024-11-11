import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotificationDetailController extends GetxController {

  String formatJapaneseDate(String dateString) {
    DateTime parsedDate = DateTime.parse(dateString);
    // Format the date to 'yyyy 年 MM 月 dd 日'
    String formattedDate = DateFormat('yyyy 年 M 月 d 日', 'ja_JP').format(parsedDate);
    return formattedDate;
  }
}
