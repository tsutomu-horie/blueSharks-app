import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/main/controllers/main.controller.dart';
import 'package:koto_blue_sharks/presentation/main/main.screen.dart';
import 'package:koto_blue_sharks/presentation/register/fan_club_confirmation/fan_club_confirmation.screen.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/utils/fcm_helper.dart';
import 'package:koto_blue_sharks/app/services/notification_token_sync.dart';
import 'package:koto_blue_sharks/utils/utils.dart';
import '../../registration_notification_sync.dart';

class RegisterMemberFanclubController extends GetxController {
  final idTextFieldController = TextEditingController();
  final passwordTextFieldController = TextEditingController();
  final AuthProvider apiProvider;
  final Future<void> Function(String) _saveAccessToken;
  final Future<NotificationSyncOutcome> Function() _syncNotifications;
  final void Function(BuildContext, Function) _showSuccessDialog;
  final Future<void> Function(bool isFromHome)? _continueAfterRegistration;

  RegisterMemberFanclubController({
    AuthProvider? apiProvider,
    Future<void> Function(String)? saveAccessToken,
    Future<NotificationSyncOutcome> Function()? syncNotifications,
    void Function(BuildContext, Function)? showSuccessDialog,
    Future<void> Function(bool isFromHome)? continueAfterRegistration,
  })  : apiProvider = apiProvider ?? AuthProvider(),
        _saveAccessToken = saveAccessToken ?? _persistAccessToken,
        _syncNotifications =
            syncNotifications ?? FcmHelper.syncAfterRegistration,
        _showSuccessDialog =
            showSuccessDialog ?? Utils.showCustomSuccessRegisterDialog,
        _continueAfterRegistration = continueAfterRegistration;

  static Future<void> _persistAccessToken(String token) =>
      AuthToken().saveAccessToken(token);

  final isConfirmPasswordHidden = true.obs;
  final confirmPasswordController = TextEditingController();

  var isPasswordHidden = true.obs;

  @override
  void onInit() async {
    super.onInit();
    apiProvider.onInit();

    AnalyticsService.logPageView(Routes.REGISTER_MEMBER_FANCLUB);
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void onRegister(
      String otpId,
      String email,
      Function showError,
      Function showSuccess,
      String playerLink,
      String playerName,
      BuildContext context,
      bool isFromHome) async {
    print("set wallpaper ${playerLink}");
    final response = await apiProvider.register(idTextFieldController.text,
        email, otpId, passwordTextFieldController.text, (String errorText) {
      Utils.showError(context, "Something wrong", errorText);
    });

    await _saveAccessToken(response.access_token);

    // WallpaperPreferences wallpaper = WallpaperPreferences();
    // await wallpaper.saveWallpaper(playerName);
    MySharedPref.setWallpaper(playerLink);
    MySharedPref.setWallpaperName(playerName);

    final successAction = OneShotAsyncAction();
    _showSuccessDialog(context, () {
      return successAction.run(() async {
        await continueAfterBestEffortNotificationSync(
          isFromHome: isFromHome,
          sync: () async =>
              await _syncNotifications() == NotificationSyncOutcome.synced
                  ? RegistrationNotificationTokenSyncStatus.synced
                  : RegistrationNotificationTokenSyncStatus.failed,
          onSyncIncomplete: (status) {
            debugPrint(
              'Home registration notification token sync: ${status.name}',
            );
          },
          continueFlow: () async {
            final continueAfterRegistration = _continueAfterRegistration;
            if (continueAfterRegistration != null) {
              await continueAfterRegistration(isFromHome);
              return;
            }

            if (!isFromHome) {
              Get.offAll(() => FanClubConfirmationScreen(
                    email: email,
                    id: idTextFieldController.text,
                    isNotification: true,
                    playerSelected: playerLink,
                    playerSelectedName: playerName,
                    isFromHome: false,
                  ));
            } else {
              Get.offAll(() => const MainScreen(initialTab: 2));

              final mainController = Get.find<MainController>();
              mainController.refreshUnreadMessageCount();
            }
          },
        );
      });
    });

    // showSuccess();
  }
}
