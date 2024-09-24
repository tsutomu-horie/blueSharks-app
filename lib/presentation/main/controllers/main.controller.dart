import 'package:get/get.dart';

class MainController extends GetxController {
  var selectedIndex = 0.obs;
  var selectedTopicId = Rx<int?>(null); // Track the selected topic ID
}
