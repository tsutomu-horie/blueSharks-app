import 'package:koto_blue_sharks/app/services/server_time_clock.dart';

/// 育成ゲームで使うサーバー時刻時計です。
class TrainingGameClock {
  TrainingGameClock._();

  /// サーバー時刻を基準に、通信間の経過を補間した現在時刻を返します。
  static DateTime now() => ServerTimeClock.instance.now;
}
