import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/services/notification_service.dart';
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
  final isLogoutInProgress = false.obs;
  Future<void>? _logoutFuture;
  final AuthProvider apiProvider;
  late final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  MypageController({AuthProvider? apiProvider})
      : apiProvider = apiProvider ?? AuthProvider();


  @override
  void onInit() {
    super.onInit();
    apiProvider.onInit();
    getToken();
    getWallpaper();


    AnalyticsService.logPageView(Routes.MYPAGE);
  }

  Future<void> logout() {
    final inFlight = _logoutFuture;
    if (inFlight != null) return inFlight;

    late final Future<void> pending;
    pending = _performLogout().whenComplete(() {
      if (identical(_logoutFuture, pending)) _logoutFuture = null;
    });
    _logoutFuture = pending;
    return pending;
  }

  Future<void> _performLogout() async {
    isLogoutInProgress.value = true;
    try {
      final auth = AuthToken();
      final snapshot = await auth.readSessionSnapshot();
      final token = snapshot.token;
      if (token == null) {
        if (AuthToken.sessionVersion == snapshot.sessionVersion) {
          _clearLocalSession();
        }
        return;
      }

      await apiProvider.logoutAccount(token);
      final deleted = await auth.deleteTokenIfMatches(
        token,
        snapshot.sessionVersion,
      );
      if (deleted &&
          AuthToken.sessionVersion == snapshot.sessionVersion + 1) {
        _clearLocalSession();
      }
    } finally {
      isLogoutInProgress.value = false;
    }
  }

  void onAccountDeleted() {
    _clearLocalSession();
  }

  void handleAccountDeletionResult(Object? result) {
    if (result == true) onAccountDeleted();
  }

  void _clearLocalSession() {
    isLogin.value = false;
    profileData.value = null;
    isLoading.value = false;
    Get.find<MainController>().refreshUnreadMessageCount();
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
    playerLinkController.value =  MySharedPref.getWallpaper() ?? "";
    isSelectNotificaiton.value = MySharedPref.getNotification() == LocaleKeys.active.tr;

  }

  void getProfile2(String token) async {
    final response = await apiProvider.getProfile(token, () {});

    profileData.value = response;
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
