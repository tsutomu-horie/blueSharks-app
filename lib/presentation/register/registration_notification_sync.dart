enum RegistrationNotificationTokenSyncStatus {
  notRequired,
  missingSavedToken,
  missingAuthToken,
  synced,
  failed,
}

/// A per-dialog action gate. It locks synchronously before invoking async work
/// and remains locked after completion so a still-open dialog cannot repeat it.
class OneShotAsyncAction {
  bool _started = false;

  Future<void> run(Future<void> Function() action) {
    if (_started) return Future<void>.value();
    _started = true;
    return Future<void>.sync(action);
  }
}

/// Best-effort sync of a token that was saved by the app bootstrap. It never
/// obtains or stores an FCM token itself.
Future<RegistrationNotificationTokenSyncStatus>
    syncSavedFcmTokenAfterRegistration({
  required bool isFromHome,
  required String? Function() readSavedFcmToken,
  required Future<Object?> Function(String fcmToken) updateNotificationToken,
}) async {
  // The regular registration flow syncs through the confirmation screen's
  // existing FcmHelper.initFcm() call. Avoid a second sync on that path.
  if (!isFromHome) {
    return RegistrationNotificationTokenSyncStatus.notRequired;
  }

  String? fcmToken;
  try {
    fcmToken = readSavedFcmToken();
  } catch (_) {
    return RegistrationNotificationTokenSyncStatus.failed;
  }

  if (fcmToken == null || fcmToken.isEmpty) {
    return RegistrationNotificationTokenSyncStatus.missingSavedToken;
  }

  try {
    final response = await updateNotificationToken(fcmToken);
    if (response == null) {
      return RegistrationNotificationTokenSyncStatus.missingAuthToken;
    }
    return RegistrationNotificationTokenSyncStatus.synced;
  } catch (_) {
    // Do not block account registration or navigation on notification sync.
    return RegistrationNotificationTokenSyncStatus.failed;
  }
}

/// Keeps the existing success/navigation path alive if notification syncing
/// fails. The caller provides a status logger that must not include token data.
Future<void> continueAfterBestEffortNotificationSync({
  required bool isFromHome,
  required Future<RegistrationNotificationTokenSyncStatus> Function() sync,
  required Future<void> Function() continueFlow,
  required void Function(RegistrationNotificationTokenSyncStatus status)
      onSyncIncomplete,
}) async {
  if (isFromHome) {
    RegistrationNotificationTokenSyncStatus status;
    try {
      status = await sync();
    } catch (_) {
      status = RegistrationNotificationTokenSyncStatus.failed;
    }
    if (status != RegistrationNotificationTokenSyncStatus.synced) {
      onSyncIncomplete(status);
    }
  }

  await continueFlow();
}
