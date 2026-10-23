import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_game_care_action.screen.dart';

const _newSquatDescription = '日々のトレーニングを重ねて、たくましい鮫太郎を目指しましょう！';
const _oldSquatDescription = '日課の筋トレで、フォワードと体格の傾向を伸ばします。';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final body in <String?>[null, SametarohAssets.childBodyKey]) {
    testWidgets(
      '${body == SametarohAssets.childBodyKey ? '幼少期' : '通常'}の筋トレ画面にNo.43の説明文を表示する',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              home: TrainingGameCareActionScreen(
                actionType: TrainingActionType.squat,
                bodyKey: body,
              ),
            ),
          ),
        );

        expect(find.text(_newSquatDescription), findsOneWidget);
        expect(find.text(_oldSquatDescription), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
