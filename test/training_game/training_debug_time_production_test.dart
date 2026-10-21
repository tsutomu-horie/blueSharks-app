import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/utils/app_environment.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('通常版では時間加算も専用API呼出しも実行しない', () async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    final controller = TrainingGameController();
    addTearDown(controller.onClose);
    controller.stageIndex.value = 2;
    final meters = Map<String, double>.from(controller.meters);
    controller.advanceTime(1);
    expect(controller.elapsedHours.value, 0);
    expect(controller.meters, meters);
    expect(controller.logs, isEmpty);
    await expectLater(
      TrainingGameProvider().syncDebugTime(
        stageCode: 'training',
        parameters: const {'hunger': 100},
        lockVersion: 0,
      ),
      throwsStateError,
    );
  }, skip: !AppEnvironment.usesProductionServices);
}
