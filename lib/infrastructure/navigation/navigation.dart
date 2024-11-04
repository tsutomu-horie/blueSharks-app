import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/presentation/register/register_member_fanclub/register_member_fanclub.screen.dart';

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
      page: () => HomeScreen((value) {}, () {}),
      binding: HomeControllerBinding(),
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
      page: () => MainScreen(),
      binding: MainControllerBinding(),
    ),
    GetPage(
      name: Routes.INFO,
      page: () => InfoScreen((value) {}),
      binding: InfoControllerBinding(),
    ),
    GetPage(
      name: Routes.MYPAGE,
      page: () => const MypageScreen(),
      binding: BindingsBuilder(() {
        print("log page my");
        // AnalyticsService.logPageView(Routes.MYPAGE);
      }),
    ),
    GetPage(
      name: Routes.STADIUM,
      page: () => const StadiumScreen(),
      binding: BindingsBuilder(() {
        // AnalyticsService.logPageView(Routes.STADIUM);
      }),
    ),
    GetPage(
      name: Routes.CALENDAR,
      page: () => CalendarScreen(),
      binding: CalendarControllerBinding(),
    ),
    GetPage(
      name: Routes.LIST_TOPICS,
      page: () => ListTopicsScreen(
        onOpenDetail: (value) {},
      ),
      binding: ListTopicsControllerBinding(),
    ),
    GetPage(
      name: Routes.DETAIL_INFO,
      page: () => DetailInfoScreen(() {}, null),
      binding: DetailInfoControllerBinding(),
    ),
    GetPage(
      name: Routes.GAME_INFO,
      page: () => const GameInfoScreen(),
      binding: GameInfoControllerBinding(),
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
      page: () => const MemberScreen(null),
      binding: MemberControllerBinding(),
    ),
    GetPage(
      name: Routes.PLAYER_DETAIL,
      page: () => MemberDetailScreen(null),
      binding: PlayerDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.TEAM,
      page: () => const TeamScreen(),
      binding: TeamControllerBinding(),
    ),
    GetPage(
      name: Routes.WEBVIEW,
      page: () => const WebviewScreen(WebviewType.team),
      binding: WebviewControllerBinding(),
    ),
    GetPage(
      name: Routes.FANCLUB,
      page: () => const FanclubScreen(),
      binding: FanclubControllerBinding(),
    ),
    GetPage(
      name: Routes.WALLPAPER_SET_PLAYER,
      page: () => const WallpaperSetPlayerScreen(null),
      binding: WallpaperSetPlayerControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_EMAIL,
      page: () => const RegisterEmailScreen(""),
      binding: RegisterEmailControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_OTP,
      page: () => const RegisterOtpScreen(
        email: "",
        fromScreen: "",
        otpId: "",
        selectedPlayer: "",
      ),
      binding: RegisterOtpControllerBinding(),
    ),
    GetPage(
      name: Routes.REGISTER_MEMBER_FANCLUB,
      page: () => const RegisterMemberFanclubScreen(
        email: "",
        otpId: "",
        selectedPlayer: "",
      ),
      binding: RegisterMemberFanclubControllerBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginScreen("", false),
      binding: LoginControllerBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ResetPasswordScreen(""),
      binding: ResetPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(""),
      binding: ForgotPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.FAN_CLUB_CONFIRMATION,
      page: () => const FanClubConfirmationScreen(
        email: "",
        id: "",
        isNotification: true,
        playerSelected: "",
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
      page: () => const RegisterEmailFromHomeScreen(""),
      binding: RegisterEmailFromHomeControllerBinding(),
    ),
    GetPage(
      name: Routes.EDIT_PASSWORD,
      page: () => const EditPasswordScreen(),
      binding: EditPasswordControllerBinding(),
    ),
    GetPage(
      name: Routes.GALLERY_SCREEN_DETAIL,
      page: () => const GalleryScreenDetailScreen(null, ""),
      binding: GalleryScreenDetailControllerBinding(),
    ),
    GetPage(
      name: Routes.NOTIFICATION_LIST,
      page: () => const NotificationListScreen(),
      binding: NotificationListControllerBinding(),
    ),
  ];
}
