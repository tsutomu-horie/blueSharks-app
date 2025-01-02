import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/notification_preference.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/register/fan_club_confirmation/controllers/fan_club_confirmation.controller.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/utils.dart';

class MypageController extends FanClubConfirmationController {
  final isLogin = false.obs;
  final Rx<UserData?> profileData = Rx<UserData?>(null);
  final isLoading = false.obs;
  final AuthProvider apiProvider = AuthProvider();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;


  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    getToken();
    getWallpaper();


    print("open mypage");
    AnalyticsService.logPageView(Routes.MYPAGE);
  }

  void logout() async {

     await apiProvider.logoutAccount();

     final auth = AuthToken();
     await auth.deleteToken();

     isLogin.value = false;
     profileData.value = null;

      onInit();

      final mainController = Get.find<MainController>();
      mainController.refreshUnreadMessageCount();

  }

  void getToken() async {
    isLoading.value = true;
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    if (token != null) {
      isLogin.value = true;

      getProfile2(token);
      getNotificationSetting();

    }


    playerNameController.value =  MySharedPref.getWallpaperName() ?? "";
    isSelectNotificaiton.value = MySharedPref.getNotification() == LocaleKeys.active.tr;

  }

  void getProfile2(String token) async {
    print("response token = $token");
    final response = await apiProvider.getProfile(token, (){
      print("error get profile ");
    });

    profileData.value = response;
    print("finish profile ${response}");
    isLoading.value = false;
  }

  Future<void> getWallpaper() async {
    // final wallpaper = WallpaperPreferences();
    // final wallpaperName = await wallpaper.getWallpaper();
    final wallpaperLink = MySharedPref.getWallpaper();
    final wallpaperName = MySharedPref.getWallpaperName();

   playerLinkController.value = wallpaperLink ?? "";
   playerNameController.value = wallpaperName ?? "";
  }

  Future<void> getNotificationSetting() async {
    final wallpaper = NotificationPreference();
    // final notificationSetting = await wallpaper.getNotificationSetting();
    final notificationSetting = MySharedPref.getNotification();

    isSelectNotificaiton.value = notificationSetting == LocaleKeys.active.tr;
  }
}
