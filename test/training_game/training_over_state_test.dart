import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
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

  for (final entry in {'hunger': '食事', 'work': '仕事'}.entries) {
    test('休止中に${entry.value}が過剰で終了した場合、初回取得と再起動で終了理由を復元する', () async {
      final provider = _OverStateProvider()..endingParameter = entry.key;
      for (var launch = 0; launch < 2; launch++) {
        final controller = TrainingGameController(serverProvider: provider);
        await controller.retryRestoreServerState();
        expect(controller.isServerStateReady.value, isTrue);
        expect(controller.ended.value, isTrue);
        expect(controller.endingStep.value, 2);
        expect(
            controller.endingMessage.value, '${entry.value}が過剰のまま72時間経過しました。');
        expect(provider.normalSaves, 0);
        controller.onClose();
        await Future<void>.delayed(Duration.zero);
      }
    });
  }

  test('古い端末の過剰時間や時計から終了を推定せずサーバーの育成中状態を維持する', () async {
    final provider = _OverStateProvider()..serverStatus = 'playing';
    await MySharedPref.setTrainingGameLocalState(jsonEncode({
      'player_id': 7,
      'cycle_no': 1,
      'over_hours': {'食事': 100},
      'over_hours_checkpoint': -1000000,
    }));
    final controller = TrainingGameController(serverProvider: provider);
    addTearDown(controller.onClose);
    await controller.retryRestoreServerState();
    expect(controller.ended.value, isFalse);
    expect(provider.normalSaves, 0);
  });

  for (final sameCycle in [true, false]) {
    test('終了同期と過剰終了が競合しても同じ育成だけを確定する: $sameCycle', () async {
      final provider = _OverStateProvider()..serverStatus = 'playing';
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.retryRestoreServerState();
      provider.forceOverEnding = true;
      provider.endingParameter = 'hunger';
      provider.readbackCycle = sameCycle ? null : 2;
      controller.ended.value = true;
      controller.clearPosition.value = 'プロップ';
      controller.retryEndingSync();
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.isEndingSyncPending.value, isFalse);
      if (sameCycle) {
        expect(controller.endingSyncError.value, isEmpty);
        expect(controller.clearPosition.value, isNull);
        expect(controller.endingMessage.value, '食事が過剰のまま72時間経過しました。');
      } else {
        expect(controller.endingSyncError.value, isNotEmpty);
      }
    });
  }

  for (final parameter in [null, 'cleanliness']) {
    test('旧APIや未知の終了理由 $parameter でも従来の終了画面を維持する', () async {
      final provider = _OverStateProvider()..endingParameter = parameter;
      final controller = TrainingGameController(serverProvider: provider);
      addTearDown(controller.onClose);
      await controller.retryRestoreServerState();
      expect(controller.ended.value, isTrue);
      expect(controller.endingMessage.value, '育成は終了しました。卵からやりなおしてください。');
    });
  }
}

class _OverStateProvider extends DebugDayProvider {
  _OverStateProvider() {
    serverStatus = 'negative_end';
  }
  String? endingParameter;
  bool forceOverEnding = false;
  int? readbackCycle;
  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      {...payload(), if (readbackCycle != null) 'cycle_no': readbackCycle};
  @override
  Map<String, dynamic> payload() => {
        ...super.payload(),
        if (forceOverEnding) 'status': 'negative_end',
        if (endingParameter != null)
          'over_state': {'schema': 1, 'ending_parameter': endingParameter},
      };
}
