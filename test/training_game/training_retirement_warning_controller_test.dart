import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_work_debug_day_test.dart' show DebugDayProvider;

class RetirementWarningProvider extends DebugDayProvider {
  DateTime at = DateTime.utc(2026, 10, 30, 10, 23, 45);
  DateTime? overStart = DateTime.utc(2026, 10, 28, 10, 23, 45);
  double food = 145;
  double work = 20;
  double condition = 80;
  double cleanliness = 80;
  bool malformedStart = false;
  @override
  Map<String, dynamic> payload() => {
        ...super.payload(),
        'started_at': '2026-10-01T00:00:00.000Z',
        'server_time': at.toIso8601String(),
        'elapsed_seconds': at.difference(DateTime.utc(2026, 10, 1)).inSeconds,
        'parameters': {
          'hunger': food,
          'work': work,
          'condition': condition,
          'cleanliness': cleanliness
        },
        'over_state': {
          'schema': 1,
          'started_at': {
            'hunger': malformedStart
                ? '2026-10-28T10:23:45'
                : overStart?.toIso8601String(),
            'work': null,
          }
        },
      };
  @override
  Future<Map<String, dynamic>?> fetchCurrent(
          {int? expectedSessionVersion}) async =>
      payload();
}

class QuietRetirementController extends TrainingGameController {
  QuietRetirementController({required super.serverProvider});
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
  });
  test(
      'dismissal survives server refresh, route/controller recreation, and background age',
      () async {
    final provider = RetirementWarningProvider();
    var c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    var warning = c.retirementWarnings.single;
    c.collapseRetirementWarning(warning);
    await Future<void>.delayed(Duration.zero);
    await c.retryRestoreServerState();
    expect(c.isRetirementWarningCollapsed(c.retirementWarnings.single), isTrue);
    c.onClose();
    c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    expect(c.isRetirementWarningCollapsed(c.retirementWarnings.single), isTrue);
    c.expandRetirementWarning(c.retirementWarnings.single);
    expect(
        c.isRetirementWarningCollapsed(c.retirementWarnings.single), isFalse);
    c.collapseRetirementWarning(c.retirementWarnings.single);
    provider.at = provider.at.add(const Duration(hours: 1));
    await c.retryRestoreServerState();
    expect(c.isRetirementWarningCollapsed(c.retirementWarnings.single), isTrue);
    expect(provider.normalSaves, 0);
    c.onClose();
  });
  test(
      'recovery clears dismissal; a new over episode and new cycle start expanded',
      () async {
    final provider = RetirementWarningProvider();
    final c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    c.collapseRetirementWarning(c.retirementWarnings.single);
    provider.food = 100;
    provider.overStart = null;
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, isEmpty);
    provider.food = 145;
    provider.overStart = provider.at.subtract(const Duration(hours: 49));
    await c.retryRestoreServerState();
    expect(
        c.isRetirementWarningCollapsed(c.retirementWarnings.single), isFalse);
    c.collapseRetirementWarning(c.retirementWarnings.single);
    provider.cycleNo++;
    await c.retryRestoreServerState();
    expect(
        c.isRetirementWarningCollapsed(c.retirementWarnings.single), isFalse);
    provider.serverStatus = 'negative_end';
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, isEmpty);
    expect(provider.normalSaves, 0);
    c.onClose();
  });
  test(
      'zero counter and collapsed episode remain stable across long background/reentry',
      () async {
    final provider = RetirementWarningProvider()
      ..food = 0
      ..overStart = null;
    await MySharedPref.setTrainingGameLocalState(jsonEncode({
      'player_id': 7,
      'cycle_no': 1,
      'elapsed_hours': 30,
      'zero_hours': {'食事': 24, '体調': 0, '清潔': 0, '仕事': 0},
    }));
    var c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    final episode = c.retirementWarnings.single.episode;
    c.collapseRetirementWarning(c.retirementWarnings.single);
    await Future<void>.delayed(Duration.zero);
    c.onClose();
    provider.at = provider.at.add(const Duration(days: 100));
    c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    expect(c.retirementWarnings.single.episode, episode);
    expect(c.elapsedHours.value, 30);
    expect(c.isRetirementWarningCollapsed(c.retirementWarnings.single), isTrue);
    expect(provider.normalSaves, 0);
    c.onClose();
  });
  test(
      'timezone-less timestamps and short-time tutorial conditions add no warning',
      () async {
    final provider = RetirementWarningProvider()..malformedStart = true;
    final c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, isEmpty);
    provider.malformedStart = false;
    provider.stageCode = 'child';
    c.onClose();
    final child = QuietRetirementController(serverProvider: provider);
    await child.retryRestoreServerState();
    expect(child.retirementWarnings, isEmpty);
    expect(provider.normalSaves, 0);
    child.onClose();
  });
  test('local recovery invalidates the old server start before a second meal',
      () async {
    final provider = RetirementWarningProvider()..food = 105;
    var c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, hasLength(1));
    c.perform(TrainingActionType.rest);
    expect(c.meters['食事'], lessThanOrEqualTo(100));
    c.perform(TrainingActionType.meal);
    expect(c.meters['食事'], greaterThan(100));
    expect(c.retirementWarnings, isEmpty);
    // A server response that still has the pre-recovery timestamp is not a new
    // confirmed episode and must not restore the previous 48-hour warning.
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, isEmpty);
    await Future<void>.delayed(Duration.zero);
    c.onClose();
    c = QuietRetirementController(serverProvider: provider);
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, isEmpty);
    provider.overStart = provider.at.subtract(const Duration(hours: 50));
    await c.retryRestoreServerState();
    expect(c.retirementWarnings, hasLength(1));
    c.onClose();
  });
}
