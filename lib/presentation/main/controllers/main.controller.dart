import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/presentation/NotificationList/notification_list.screen.dart';
import 'package:koto_blue_sharks/presentation/login/login.screen.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:url_launcher/url_launcher.dart';

class MainController extends GetxController {
  var selectedIndex = 0.obs;
  var selectedTopicId = Rx<int?>(null); // Track the selected topic ID
  var selectedPost = Rx<Post?>(null); // Track the selected topic ID

  void navigateToNotification() async {
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    var wallpaper = MySharedPref.getWallpaper();
    var wallpaperName = MySharedPref.getWallpaperName();

    if (token != null) {
      Get.to(() => const NotificationListScreen());
    } else {
      Get.to(() => LoginScreen(wallpaper ?? "", true, wallpaperName ?? ""));
    }
  }

  void launchFanClub(){
    launchExternalWeb(Constants.fanClubUrl);
  }

  void launchTicket(){
    launchExternalWeb(Constants.ticketsUrl);
  }

  void launchGood(){
    launchExternalWeb(Constants.shopUrl);
  }

  void launchExternalWeb(String url) async {
    final Uri webUrl = Uri.parse(url); // Replace with your profile URL
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    } else {
      throw 'Could not launch $webUrl';
    }
  }
}
