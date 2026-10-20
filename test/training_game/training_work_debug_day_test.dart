import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  test('仕事後に＋1日を押してすぐ再照会しても、日次解除後の仕事を開始できる', () async {
    final provider = DebugDayProvider();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    expect(await controller.prepareWork(), isTrue);
    controller.finishWorkPreparation();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.canWorkToday, isFalse);

    controller.advanceTime(24);
    final expectedMeters = Map<String, double>.from(controller.meters);
    expect(await controller.prepareWork(), isTrue);
    expect(provider.dailyResets, 1);
    expect(controller.meters, expectedMeters);
    controller.finishWorkPreparation();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    expect(provider.workActions, 2);
  });

  for (final failTimeSync in [true, false]) {
    test('${failTimeSync ? '時間同期' : '日次解除'}失敗を1日1回制限と誤表示せず、次の仕事押下で解除を再試行する',
        () async {
      final provider = DebugDayProvider()
        ..failTimeSync = failTimeSync
        ..failDailyReset = !failTimeSync;
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.debugStartAtTraining();
      controller.perform(TrainingActionType.work);
      await TrainingGameProvider.waitForPendingSync();
      controller.advanceTime(24);
      final expectedMeters = Map<String, double>.from(controller.meters);

      expect(await controller.prepareWork(), isFalse);
      expect(controller.workAvailabilityError.value, contains('時間変更'));
      expect(controller.meters, expectedMeters);
      provider.failDailyReset = false;
      provider.failTimeSync = false;
      expect(await controller.prepareWork(), isTrue);
      expect(provider.dailyResets, failTimeSync ? 1 : 2);
      expect(controller.meters, expectedMeters);
      controller.finishWorkPreparation();
    });
  }

  test('仕事の保存保留を日次制限と誤表示しない', () async {
    final provider = DebugDayProvider()..rateLimitWork = true;
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    controller.perform(TrainingActionType.work);
    await TrainingGameProvider.waitForPendingSync();
    controller.advanceTime(24);

    expect(await controller.prepareWork(), isFalse);
    expect(controller.workAvailabilityError.value, contains('同期待ち'));
    expect(provider.dailyResets, 0);
  });

  testWidgets('＋1日の日次解除を再試行してから仕事中の画面を表示し、中止では仕事を実行しない', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    addTearDown(Get.reset);
    final provider = DebugDayProvider()..failTimeSync = true;
    final controller = _ManualController(serverProvider: provider);
    await tester.runAsync(() async {
      await controller.debugStartAtTraining();
      controller.perform(TrainingActionType.work);
      await TrainingGameProvider.waitForPendingSync();
    });
    Get.put<TrainingGameController>(controller);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => const MaterialApp(home: TrainingGameScreen()),
    ));
    await tester.runAsync(() async {
      controller.advanceTime(24);
      await tester.tap(find.widgetWithText(TextButton, '仕事'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.workAvailabilityError.value, contains('時間変更'));
    expect(find.byType(TrainingGameCareActionScreen), findsNothing);
    expect(find.textContaining('時間変更を保存できませんでした'), findsOneWidget);
    expect(find.text('仕事は1日1回までです。'), findsNothing);

    // エラーのSnackBarが下部の仕事ボタンを覆っている間は押さない。
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));

    provider.failTimeSync = false;
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(TextButton, '仕事'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
    expect(find.text('仕事中…'), findsOneWidget);
    expect(provider.workActions, 1);
    await tester.tap(find.byTooltip('お世話を中止'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(provider.workActions, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

class _ManualController extends TrainingGameController {
  _ManualController({required super.serverProvider});

  // 周期clockと起動時通信を省き、可否照会・時間操作・仕事処理は実装を使用します。
  @override
  // ignore: must_call_super
  void onInit() {}
}

class DebugDayProvider extends TrainingGameProvider {
  int dailyResets = 0;
  int workActions = 0;
  bool failDailyReset = false;
  bool failTimeSync = false;
  bool rateLimitWork = false;
  int _lockVersion = 0;
  bool _workAvailable = true;
  final _startedAt = DateTime.now().toUtc();
  Map<String, double> _parameters = {
    'hunger': 100,
    'cleanliness': 100,
    'condition': 100,
    'work': 20,
  };

  Map<String, dynamic> payload() => {
        'id': 7,
        'cycle_no': 1,
        'lock_version': _lockVersion,
        'stage_code': 'training',
        'status': 'playing',
        'started_at': _startedAt.toIso8601String(),
        'server_time': _startedAt.toIso8601String(),
        'elapsed_seconds': 0,
        'work_available': _workAvailable,
        'actions_today': _workAvailable ? 0 : 1,
        'play_floor': 20,
        'parameters': Map<String, double>.from(_parameters),
        'cooldowns': <String, dynamic>{},
      };

  @override
  Future<Map<String, dynamic>> start({
    required String stageCode,
    required Map<String, double> parameters,
    bool forceRestart = false,
    int? expectedSessionVersion,
  }) async =>
      payload();

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      payload();

  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      [];

  @override
  Future<Map<String, dynamic>> syncDebugTime({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
    int? expectedSessionVersion,
  }) async {
    expect(lockVersion, _lockVersion);
    if (failTimeSync) {
      throw TrainingGameApiException(statusCode: 404, message: 'Not Found');
    }
    _parameters = Map.of(parameters);
    _lockVersion++;
    return payload();
  }

  @override
  Future<Map<String, dynamic>> resetDebugDailyActionUsage(
      {int? expectedSessionVersion}) async {
    dailyResets++;
    if (failDailyReset) {
      throw TrainingGameApiException(statusCode: 404, message: 'Not Found');
    }
    _workAvailable = true;
    return payload();
  }

  @override
  Future<Map<String, dynamic>> sync({
    required String stageCode,
    required Map<String, double> parameters,
    required int lockVersion,
    required int cycleNo,
    String? positionCode,
    String? branchCode,
    String? actionCode,
    String? actionIdempotencyKey,
    int? expectedSessionVersion,
    String? status,
    String? endingType,
    String? actionResultCode,
    double? actionScore,
    double? actionEffectMultiplier,
    bool debugBypassCooldown = false,
  }) async {
    if (actionCode == 'work' && rateLimitWork) {
      throw TrainingGameApiException(
          statusCode: 429,
          message: 'Too Many Attempts',
          retryAfter: const Duration(seconds: 65));
    }
    expect(lockVersion, _lockVersion);
    _lockVersion++;
    _parameters = Map.of(parameters);
    if (actionCode == 'work') {
      workActions++;
      _workAvailable = false;
    }
    return payload();
  }
}
