import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';

import '../../config.dart';
import '../../presentation/screens.dart';
import 'bindings/controllers/controllers_bindings.dart';
import 'routes.dart';

class EnvironmentsBadge extends StatelessWidget {
  final Widget child;
  EnvironmentsBadge({required this.child});
  @override
  Widget build(BuildContext context) {
    var env = ConfigEnvironments.getEnvironments()['env'];
    return env != Environments.PRODUCTION
        ? Banner(
            location: BannerLocation.topStart,
            message: env!,
            color: env == Environments.QAS ? Colors.blue : Colors.purple,
            child: child,
          )
        : SizedBox(child: child);
  }
}

class Nav {
  static List<GetPage> routes = [
    GetPage(
      name: Routes.HOME,
      page: () => HomeScreen((value) {}, () {}, () {}),
      binding: HomeControllerBinding(),
    ),
    GetPage(
      name: Routes.GAME_GUIDE,
      page: () => const GameGuideListScreen(),
    ),
    GetPage(
      name: Routes.GAME_GUIDE_DETAIL,
      page: () => GameGuideDetailScreen(
        post: Get.arguments as GameGuidePost,
      ),
    ),
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashControllerBinding(),
    ),
    GetPage(
      name: Routes.WALLPAPER,
      page: () => const WallpaperScreen(),
      binding: WallpaperControllerBinding(),
    ),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainScreen(),
      binding: MainControllerBinding(),
    ),
    GetPage(
      name: Routes.INFO,
      page: () => MenuScreen((value) {}),
      binding: MenuControllerBinding(),
    ),
    GetPage(
      name: Routes.MYPAGE,
      page: () => const MypageScreen(),
      binding: MypageControllerBinding(),
    ),
    GetPage(
      name: Routes.STADIUM,
      page: () => const StadiumScreen(),
      binding: StadiumControllerBinding(),
    ),
    GetPage(
      name: Routes.CALENDAR,
      page: () => CalendarScreen(),
      binding: CalendarControllerBinding(),
    ),
    GetPage(
      name: Routes.LIST_TOPICS,
      page: () => TopicListScreen(
        onOpenDetail: (value) {},
      ),
      binding: TopicListControllerBinding(),
    ),
    GetPage(
      name: Routes.DETAIL_INFO,
      page: () => InfoDetailScreen(() {}, null),
      binding: InfoDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.GAME_INFO,
      page: () => const MatchListScreen(),
      binding: MatchListControllerBinding(),
    ),
    GetPage(
      name: Routes.MATCH_DETAIL,
      page: () => const MatchDetailScreen(
        null,
        homeStatus: "",
      ),
      binding: MatchDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.MEMBER,
      page: () => const PlayerListScreen(null),
      binding: PlayerListControllerBinding(),
    ),
    GetPage(
      name: Routes.PLAYER_DETAIL,
      page: () => const PlayerDetailScreen(null),
      binding: PlayerDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.WEBVIEW,
      page: () => const WebviewScreen(WebviewType.team),
      binding: WebviewControllerBinding(),
    ),
    GetPage(
      name: Routes.WALLPAPER_SET_PLAYER,
      page: () => const UpdateWallpaperScreen(null, ""),
      binding: WallpaperSetPlayerControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_EMAIL,
      page: () => const RegisterEmailScreen("", ""),
      binding: RegisterEmailControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_OTP,
      page: () => const RegisterOtpScreen(
        isRegister: false,
        email: "",
        fromScreen: "",
        otpId: "",
        selectedPlayer: "",
        selectedPlayerName: "",
      ),
      binding: RegisterOtpControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_MEMBER_FANCLUB,
      page: () => const RegisterMemberFanclubScreen(
          email: "",
          otpId: "",
          selectedPlayer: "",
          selectedPlayerName: '',
          isFromHome: false),
      binding: RegisterMemberFanclubControllerBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen("", false, ""),
      binding: LoginControllerBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ResetPasswordScreen(
        "",
        isFromHome: false,
      ),
      binding: ResetPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen("", ""),
      binding: ForgotPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.FAN_CLUB_CONFIRMATION,
      page: () => const FanClubConfirmationScreen(
        email: "",
        id: "",
        isNotification: true,
        playerSelected: "",
        playerSelectedName: "",
        isFromHome: false,
      ),
      binding: FanClubConfirmationControllerBinding(),
    ),
    GetPage(
      name: Routes.GALLERY,
      page: () => const GalleryScreen(),
      binding: GalleryControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_EMAIL_FROM_HOME,
      page: () => const RegisterEmailFromHomeScreen("", ""),
      binding: RegisterEmailFromHomeControllerBinding(),
    ),
    GetPage(
      name: Routes.EDIT_PASSWORD,
      page: () => const EditPasswordScreen(),
      binding: EditPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.GALLERY_SCREEN_DETAIL,
      page: () => const GalleryDetailScreen(null, ""),
      binding: GalleryScreenDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.NOTIFICATION_LIST,
      page: () => const NotificationListScreen(),
      binding: NotificationListControllerBinding(),
    ),
    GetPage(
      name: Routes.NOTIFICATION_DETAIL,
      page: () => const NotificationDetailScreen(null),
      binding: NotificationDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.DELETE_ACCOUNT_CONFIRMATION,
      page: () => const DeleteAccountConfirmationScreen(),
      binding: DeleteAccountConfirmationControllerBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD_HOME,
      page: () => const ForgotPasswordHomeScreen("", ""),
      binding: ForgotPasswordHomeControllerBinding(),
    ),
    GetPage(
      name: Routes.PRIVACY_POLICY_SCREEN,
      page: () => const PrivacyPolicyScreen(),
      binding: PrivacyPolicyScreenControllerBinding(),
    ),
    GetPage(
      name: Routes.LOCAL_FULL_SCREEN,
      page: () => const StadiumImageFullScreen(
        imageUrl: '',
      ),
      binding: StadiumImageFullScreenControllerBinding(),
    ),
  ];
}
