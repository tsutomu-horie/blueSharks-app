import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koto_blue_sharks/app/services/auth_token.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game.screen.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';
import 'prepare_grounded_frames.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';

void main() {
  setUpAll(prepareGroundedFrames);
  testWidgets('筋トレ実画面の開始・完了・中断・再入・状態変更', (tester) async {
    for (final scenario in [
      'complete',
      'cancel-reenter',
      'rapid',
      'session',
      'player',
      'cycle',
      'stage',
      'stage-aba',
      'player-aba',
      'cycle-aba'
    ]) {
      SharedPreferences.setMockInitialValues({});
      await MySharedPref.init();
      TrainingGameProvider.registerPendingSync(Future<void>.value());
      Get.reset();
      Get.testMode = true;
      final provider = SceneProvider(meterValue: 50);
      Get.routing.args = provider.state('child');
      final controller = TrainingGameController(
          serverProvider: provider,
          writePendingActions: (_) async => true,
          clearPendingActions: () async => true,
          archivePendingActions: (_) async => true);
      Get.put<TrainingGameController>(controller);

      await tester.pump();
      await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(home: TrainingGameScreen())));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      for (var i = 0; i < 20; i++) {
        await tester.pump();
      }
      expect(controller.isServerStateReady.value, isTrue, reason: scenario);
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final frame in [
          ...SametarohAssets.careFramesFor(TrainingActionType.squat,
              bodyKey: SametarohAssets.childBodyKey),
          SametarohAssets.completionFrameFor(TrainingActionType.squat,
              bodyKey: SametarohAssets.childBodyKey),
        ]) {
          await precacheImage(AssetImage(frame.asset), context);
        }
      });
      final button = find.byKey(const ValueKey('training-home-care-squat'));
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
      if (scenario == 'cancel-reenter') {
        await tester.tap(find.byTooltip('お世話を中止'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(provider.syncedActionCodes.whereType<String>(), isEmpty);
        controller.meters.addAll({'食事': 50, '清潔': 50, '体調': 50});
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(TrainingGameCareActionScreen), findsOneWidget);
      }
      if (scenario == 'rapid') {
        expect(controller.beginSquatScene(), isNull);
        controller.perform(TrainingActionType.squat);
        await tester.tapAt(const Offset(2, 200));
        await tester.tapAt(const Offset(2, 200));
      }
      if (scenario == 'session')
        await AuthToken.notifySessionChangedForTesting();
      if (scenario.startsWith('stage')) {
        controller.stageIndex.value = 2;
        if (scenario.endsWith('aba')) controller.stageIndex.value = 1;
      }
      if (scenario.startsWith('player') || scenario.startsWith('cycle')) {
        if (scenario.startsWith('player')) provider.playerId++;
        if (scenario.startsWith('cycle')) provider.cycle++;
        controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
        for (var i = 0; i < 15; i++) {
          await tester.pump();
        }
        if (scenario.endsWith('aba')) {
          if (scenario.startsWith('player')) provider.playerId--;
          if (scenario.startsWith('cycle')) provider.cycle--;
          controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
          for (var i = 0; i < 15; i++) {
            await tester.pump();
          }
        }
      }
      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('タップして戻る'), findsOneWidget);
      await tester.tap(find.text('タップして戻る'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 15; i++) {
        await tester.pump();
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => TrainingGameProvider.waitForPendingSync());
      if (scenario == 'complete') {
        expect(controller.meters['食事']!, lessThan(50));
      }
      final actions = provider.syncedActionCodes.whereType<String>().toList();
      expect(
          actions,
          [
            'session',
            'player',
            'cycle',
            'stage',
            'stage-aba',
            'player-aba',
            'cycle-aba'
          ].contains(scenario)
              ? isEmpty
              : ['training']);
      await tester.pump(const Duration(seconds: 6));
      expect(provider.syncedActionCodes.whereType<String>().length,
          actions.length);
      expect(tester.takeException(), isNull);
      controller.onClose();
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      Get.routing.args = null;
      Get.reset();
    }
  });
}

class SceneProvider extends TrainingGameProvider {
  SceneProvider({this.meterValue = 80});

  final double meterValue;
  int playerId = 7;
  int cycle = 3;
  final syncedStageCodes = <String>[];
  final syncedActionCodes = <String?>[];

  Map<String, dynamic> state(String stageCode) => {
        'id': playerId,
        'cycle_no': cycle,
        'lock_version': syncedStageCodes.length,
        'stage_code': stageCode,
        'status': 'playing',
        'started_at': '2026-10-20T00:00:00Z',
        'elapsed_seconds': 0,
        'actions_today': 0,
        'work_available': false,
        'branch_code': null,
        'position_code': null,
        'parameters': {
          'hunger': meterValue,
          'cleanliness': meterValue,
          'condition': meterValue,
          'work': 80.0,
          'tendency_fw': 0.0,
          'tendency_command': 0.0,
          'tendency_backs': 0.0,
          'tendency_bulk': 0.0,
          'tendency_tech': 0.0,
        },
        'cooldowns': <String, dynamic>{},
        if (stageCode == 'growth')
          'stage_progress': {'next_stage_code': 'first_team'},
      };

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      state('child');

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
    double? actionScore,
    double? actionEffectMultiplier,
    String? actionResultCode,
    String? actionResultPolicy,
    int? actionAttemptCount,
    int? actionSuccessCount,
    int? actionSuccessfulReactionTotalUs,
    TackleSettings? actionTackleSettings,
    bool debugBypassCooldown = false,
    String status = 'playing',
  }) async {
    syncedStageCodes.add(stageCode);
    syncedActionCodes.add(actionCode);
    return state(stageCode);
  }
}
