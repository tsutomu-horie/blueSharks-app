import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';

class MainController extends GetxController {
  var selectedIndex = 0.obs;
  var selectedTopicId = Rx<int?>(null); // Track the selected topic ID
  var selectedPost = Rx<Post?>(null); // Track the selected topic ID

}
