import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_clean_warp.dart';

/// Decode engine images in the real async zone before fake animation clocks.
Future<void> prepareGroundedFrames() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final frames = [
    ...SametarohAssets.suppliedFrames.values,
    ...SametarohAssets.careFrames.values.expand((f) => f),
    ...SametarohAssets.completionFrames.values
  ];
  for (final frame in frames) {
    if (SametarohCleanWarp.supports(frame)) {
      await SametarohCleanWarp.prepare(frame);
    }
  }
}
