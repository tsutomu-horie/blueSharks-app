import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/notification_preference.dart';
import 'package:koto_blue_sharks/app/data/api/userPreferences/wallpaper_preference.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/presentation/FanClubConfirmation/controllers/fan_club_confirmation.controller.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';

class MypageController extends FanClubConfirmationController {
  final isLogin = false.obs;
  final Rx<UserData?> profileData = Rx<UserData?>(null);
  final AuthProvider apiProvider = AuthProvider();

  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    getToken();
  }
  void logout() async {
    final auth = AuthToken();
    await auth.deleteToken();

    Get.offAll(() => const SplashScreen());
  }

  void getToken() async {
    final auth = AuthToken();
    final token = await auth.getAccessToken();

    if (token != null) {
      isLogin.value = true;

      getProfile(token);

    }

  }

  void getProfile(String token) async {
    print("response token = $token");
    final response = await apiProvider.getProfile(token, (){
      print("error get profile ");
    });

    profileData.value = response;
  }

  Future<String> getWallpaper() async {
    final wallpaper = WallpaperPreferences();
    final wallpaperName = await wallpaper.getWallpaper();

    return wallpaperName ?? "";
  }

  Future<String> getNotificationSetting() async {
    final wallpaper = NotificationPreference();
    final notificationSetting = await wallpaper.getNotificationSetting();

    return notificationSetting ?? "active";
  }
}
