import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/server_time_clock.dart';

void main() {
  test('サーバー時刻を基準に時計を同期する', () {
    final clock = ServerTimeClock.instance;
    final serverTime = DateTime.utc(2026, 8, 28, 12, 34, 56);

    clock.synchronize(serverTime);

    expect(clock.isSynchronized, isTrue);
    expect(
      clock.now.difference(serverTime),
      lessThan(const Duration(seconds: 1)),
    );
  });
}
