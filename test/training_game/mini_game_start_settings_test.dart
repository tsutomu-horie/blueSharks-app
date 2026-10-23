import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'training_work_debug_day_test.dart' show DebugDayProvider;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });

  Future<TrainingGameController> open(_SettingsProvider provider) async {
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.debugStartAtTraining();
    return controller;
  }

  test(
      'each start fetches settings during the same cycle and keeps prior play immutable',
      () async {
    final provider = _SettingsProvider();
    final controller = await open(provider);
    final first = await controller.prepareMiniGame(TrainingActionType.tackle);
    expect(first?.tackle.setCount, 3);
    expect(first?.tackle.snapshotToken, 'snapshot-3');
    provider.setCount = 5;
    expect(first?.tackle.setCount, 3);
    expect(await controller.prepareMiniGame(TrainingActionType.tackle), isNull);
    controller.finishMiniGamePreparation();
    final second = await controller.prepareMiniGame(TrainingActionType.tackle);
    expect(second?.tackle.setCount, 5);
    expect(second?.tackle.snapshotToken, 'snapshot-5');
    expect(provider.currentReads, 2);
    controller.finishMiniGamePreparation();
  });

  test('failed fetch blocks play, retry reads fresh settings', () async {
    final provider = _SettingsProvider()..failRead = true;
    final controller = await open(provider);
    expect(await controller.prepareMiniGame(TrainingActionType.passAndRun),
        isNull);
    expect(controller.logs.first, contains('設定を取得できません'));
    provider.failRead = false;
    expect(await controller.prepareMiniGame(TrainingActionType.passAndRun),
        isNotNull);
    controller.finishMiniGamePreparation();
  });

  test('pending fetch excludes duplicate launch and intervening care action',
      () async {
    final provider = _SettingsProvider()..readGate = Completer<void>();
    final controller = await open(provider);
    final before = Map<String, double>.from(controller.meters);
    final first = controller.prepareMiniGame(TrainingActionType.tackle);
    expect(controller.canPerform(TrainingActionType.clean), isFalse);
    controller.perform(TrainingActionType.clean);
    expect(controller.meters, before);
    expect(await controller.prepareMiniGame(TrainingActionType.passAndRun),
        isNull);
    provider.readGate!.complete();
    expect(await first, isNotNull);
    controller.finishMiniGamePreparation();
  });

  test('cycle changed during preparation blocks launch', () async {
    final provider = _SettingsProvider();
    final controller = await open(provider);
    provider.cycle = 2;
    expect(await controller.prepareMiniGame(TrainingActionType.tackle), isNull);
    expect(controller.logs.first, contains('育成状態が変わりました'));
  });

  test('old server without settings starts with exact product defaults',
      () async {
    final provider = _SettingsProvider()..includeSettings = false;
    final controller = await open(provider);
    final rules = await controller.prepareMiniGame(TrainingActionType.tackle);
    expect(rules?.tackle.hasDefaultRules, isTrue);
    expect(rules?.tackle.snapshotToken, isNull);
    expect(rules?.passRun.runSpeedScale, 1.15);
    controller.finishMiniGamePreparation();
  });
}

class _SettingsProvider extends DebugDayProvider {
  int setCount = 3;
  int cycle = 1;
  bool failRead = false;
  bool includeSettings = true;
  Completer<void>? readGate;

  @override
  Map<String, dynamic> payload() => {
        ...super.payload(),
        'cycle_no': cycle,
        if (includeSettings)
          'mini_game_settings': {
            'schema': 1,
            'tackle': TackleSettings(
                    setCount: setCount, snapshotToken: 'snapshot-$setCount')
                .toJson(),
          },
      };

  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    currentReads++;
    await readGate?.future;
    if (failRead) {
      throw const TrainingGameApiException(
          statusCode: 503, message: 'isolated test');
    }
    return payload();
  }
}
