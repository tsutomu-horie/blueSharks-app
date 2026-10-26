import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/auth/auth_provider.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/presentation/splash/splash.screen.dart';

class DeleteAccountConfirmationController extends GetxController {
  final emailTextFieldController = TextEditingController();
  final emailText = "".obs;
  final AuthProvider apiProvider;

  DeleteAccountConfirmationController({AuthProvider? apiProvider})
      : apiProvider = apiProvider ?? AuthProvider();

  Future<void> onDeleteAccount() async {
    final deletedCurrentSession = await deleteCurrentAccount();
    Get.back();
    Get.back(result: deletedCurrentSession);
  }

  Future<bool> deleteCurrentAccount() async {
    apiProvider.onInit();
    final auth = AuthToken();
    final snapshot = await auth.readSessionSnapshot();
    final token = snapshot.token;
    if (token == null) {
      throw StateError('No authenticated session to delete.');
    }

    await apiProvider.deleteProfile(token, () {});

    final deleted = await auth.deleteTokenIfMatches(
      token,
      snapshot.sessionVersion,
    );
    return deleted && AuthToken.sessionVersion == snapshot.sessionVersion + 1;
  }
}
