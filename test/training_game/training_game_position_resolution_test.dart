import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    Get.testMode = true;
  });

  Future<TrainingGameController> open(_PositionProvider provider) async {
    Get.routing.args = provider.state();
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(() {
      controller.onClose();
      Get.routing.args = null;
    });
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    return controller;
  }

  test('一軍の未確定→確定応答で進化し、追加行動なしで一度だけ完了保存する', () async {
    final provider = _PositionProvider();
    final controller = await open(provider);
    expect(controller.position, '判定前');
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.evolutionStage.value, 4);
    expect(controller.ended.value, isFalse);
    expect(provider.statuses, ['playing']);
    // 同じplaying応答を再取得しても演出と未完了状態を保持します。
    await controller.retryRestoreServerState();
    expect(controller.evolutionStage.value, 4);
    controller.advanceEvolution();
    controller.advanceEvolution();
    await Future<void>.delayed(Duration.zero);
    await TrainingGameProvider.waitForPendingSync();
    await Future<void>.delayed(Duration.zero);
    expect(controller.ended.value, isTrue);
    expect(controller.clearPosition.value, isNotNull);
    expect(controller.isEndingSyncPending.value, isFalse);
    expect(controller.endingSyncError.value, isEmpty);
    expect(provider.statuses, ['playing', 'positive_end']);
    expect(provider.positiveCompletions, 1);
    expect(controller.unlockedPositions, contains('fullback'));
  });

  test('確定応答の同期終了前に次へを押しても完了保存する', () async {
    final provider = _PositionProvider();
    final controller = await open(provider);
    final worker = ever<int?>(controller.evolutionStage, (stage) {
      if (stage != null) controller.advanceEvolution();
    });
    addTearDown(worker.dispose);
    controller.perform(TrainingActionType.clean);
    await Future<void>.delayed(Duration.zero);
    await TrainingGameProvider.waitForPendingSync();
    await Future<void>.delayed(Duration.zero);
    expect(controller.ended.value, isTrue);
    expect(controller.endingSyncError.value, isEmpty);
    expect(provider.positiveCompletions, 1);
  });

  test('先行行動が完了保存済みならpositive_endを重複送信しない', () async {
    final provider = _PositionProvider()..resolved = 'fullback';
    final controller = await open(provider);
    controller.perform(TrainingActionType.clean);
    await Future<void>.delayed(Duration.zero);
    await TrainingGameProvider.waitForPendingSync();
    await Future<void>.delayed(Duration.zero);
    expect(controller.ended.value, isTrue);
    expect(controller.endingSyncError.value, isEmpty);
    expect(provider.positiveCompletions, 1);
  });

  test('一軍で未確定の応答なら育成を続ける', () async {
    final provider = _PositionProvider(resolve: false);
    final controller = await open(provider);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.evolutionStage.value, isNull);
    expect(controller.ended.value, isFalse);
    expect(provider.positiveCompletions, 0);
  });

  test('成長期のポジション応答では最終進化・完了を起動しない', () async {
    final provider = _PositionProvider(stage: 'growth');
    final controller = await open(provider);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.evolutionStage.value, isNull);
    expect(controller.ended.value, isFalse);
    expect(provider.positiveCompletions, 0);
  });

  test('終了済み応答は進化を再入せず終了状態を復元する', () async {
    final provider = _PositionProvider(responseStatus: 'positive_end');
    final controller = await open(provider);
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.evolutionStage.value, isNull);
    expect(controller.ended.value, isTrue);
    expect(provider.statuses, ['playing']);
  });

  test('一軍到達時に進化先があれば既存の演出から追加日数なしで完了する', () async {
    final provider = _PositionProvider(stage: 'growth', advanceStage: true);
    final controller = await open(provider);
    controller.daysInStage.value = 7;
    controller.perform(TrainingActionType.clean);
    await TrainingGameProvider.waitForPendingSync();
    expect(controller.stageIndex.value, 4);
    expect(controller.evolutionStage.value, 4);
    controller.advanceEvolution();
    await Future<void>.delayed(Duration.zero);
    await TrainingGameProvider.waitForPendingSync();
    await Future<void>.delayed(Duration.zero);
    expect(controller.ended.value, isTrue);
    expect(provider.positiveCompletions, 1);
  });
}

class _PositionProvider extends TrainingGameProvider {
  _PositionProvider(
      {this.resolve = true,
      this.stage = 'first_team',
      this.responseStatus = 'playing',
      this.advanceStage = false});
  final bool resolve;
  final bool advanceStage;
  String stage;
  final String responseStatus;
  String? resolved;
  String statusValue = 'playing';
  final statuses = <String>[];
  int positiveCompletions = 0;
  Map<String, dynamic> state() => {
        'id': 7,
        'cycle_no': 3,
        'lock_version': statuses.length,
        'stage_code': stage,
        'status': statusValue,
        'started_at': '2026-10-23T00:00:00Z',
        'elapsed_seconds': 0,
        'position_code': resolved,
        'actions_today': 0,
        'parameters': {
          'hunger': 80.0,
          'cleanliness': 80.0,
          'condition': 80.0,
          'work': 80.0
        },
        'cooldowns': <String, dynamic>{},
      };
  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      statusValue == 'playing' ? state() : null;
  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      positiveCompletions > 0 ? ['fullback'] : [];
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
    statuses.add(status);
    if (advanceStage) stage = stageCode;
    if (resolve) resolved = 'fullback';
    statusValue = status == 'positive_end' ? status : responseStatus;
    if (status == 'positive_end') positiveCompletions++;
    return state();
  }
}
