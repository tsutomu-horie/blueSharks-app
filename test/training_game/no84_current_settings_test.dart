import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:koto_blue_sharks/presentation/training_game/models/current_decay_policy.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/training_game_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/controllers/training_game.controller.dart';
import 'package:koto_blue_sharks/presentation/training_game/models/mini_game_settings.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MySharedPref.init();
    Get.testMode = true;
    TrainingGameProvider.registerPendingSync(Future.value());
  });
  Future<TrainingGameController> open(WidgetTester t, P p) async {
    TrainingGameProvider.registerPendingSync(Future<void>.value());
    Get.routing.args = p.state();
    final c = TrainingGameController(serverProvider: p, serverElapsedSinceSyncSeconds:p.useFakeClock?()=>p.fakeElapsed:null);
    c.onInit();
    await t.pump();
    expect(c.stageIndex.value, p.stage == 'child' ? 1 : 2);
    return c;
  }

  for (final speed in [1, 4, 16]) {
    testWidgets('child foreground speed [$speed]', (t) async {
      final c = await open(t, P());
      c.setTimeSpeed(speed);
      c.tickTutorialTimer();
      expect(c.meters['清潔'], closeTo(75 - .1 * speed, 1e-8));
      expect(c.meters['食事'], closeTo(100 - .2 * speed, 1e-8));
      c.onClose();
      await t.pump();
      Get.routing.args = null;
    });
  }
  testWidgets('growth threshold preserved and confirmed by mock server',
      (t) async {
    final p = P();
    final c = await open(t, p);
    c.trainingCount.value = 15;
    c.meters['清潔'] = 60;
    c.tickTutorial(1);
    await t.pump();
    expect(c.stageIndex.value, 1);
    c.meters['清潔'] = 60.2;
    c.tickTutorial(1);
    await t.pump();
    await t.pump();
    expect(p.stage, 'training');
    expect(c.stageIndex.value, 2);
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets(
      'pause stops local decay and resume accepts offline state without second decay',
      (t) async {
    final p = P();
    final c = await open(t, p);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await t.pump();
    await t.pump();
    c.tickTutorialTimer();
    expect(c.meters['清潔'], 75);
    p.values['cleanliness'] = 69;
    p.elapsed = 60;
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await t.pump();
    await t.pump();
    await t.pump();
    expect(p.fetches, greaterThan(0));
    expect(c.meters['清潔'], 69);
    expect(c.isTutorialTimeActive, true);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(68.9, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('exact cleanliness 60 includes growth boundary', (t) async {
    final p = P();
    final c = await open(t, p);
    c.trainingCount.value = 15;
    c.meters['清潔'] = 60.1;
    c.tickTutorial(1);
    expect(c.meters['清潔'], 60.0);
    await t.pump();
    await t.pump();
    expect(c.stageIndex.value, 2);
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  for (final start in [50.0, 90.0]) {
    testWidgets('child clean operation [$start]', (t) async {
      final p = P();
      p.values['cleanliness'] = start;
      final c = await open(t, p);
      c.perform(TrainingActionType.clean);
      await t.pump();
      await t.pump();
      expect(c.meters['清潔'], start == 50 ? 75 : 100);
      expect(c.cooldownRemaining(TrainingActionType.clean).inSeconds,
          greaterThan(0));
      c.perform(TrainingActionType.clean);
      expect(c.meters['清潔'], start == 50 ? 75 : 100);
      c.onClose();
      await t.pump();
      Get.routing.args = null;
    });
  }
  testWidgets('training clean remains40 and tutorial speed has no effect',
      (t) async {
    final p = P();
    p.stage = 'training';
    p.values['cleanliness'] = 50;
    final c = await open(t, p);
    c.setTimeSpeed(16);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], 50);
    c.perform(TrainingActionType.clean);
    await t.pump();
    await t.pump();
    expect(c.meters['清潔'], 90);
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });

  testWidgets('current settings change affects existing child on next restore',
      (t) async {
    final p = P();
    final c = await open(t, p);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(74.9, 1e-8));
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await t.pump();
    await t.pump();
    final map = p.policy as Map;
    map['rates']['child']['cleanliness'] = .3;
    map['revision'] = 'next';
    p.values['cleanliness'] = 70;
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await t.pump();
    await t.pump();
    await t.pump();
    expect(c.meters['清潔'], 70);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(69.7, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('missing old API key preserves legacy rate', (t) async {
    final p = P()..includePolicy = false;
    final c = await open(t, p);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(74.8, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('explicit unavailable policy disables foreground decay',
      (t) async {
    final p = P()..policy = null;
    final c = await open(t, p);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], 75);
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('main custom rate and subhour debug interval', (t) async {
    final p = P()..stage = 'training';
    final c = await open(t, p);
    c.advanceTimeMinutes(30);
    await t.pump();
    await t.pump();
    expect(c.meters['清潔'], closeTo(74.85, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  test('shared PHP policy crossing100 fractions floor and perstage', () {
    final raw =
        jsonDecode(File('test/fixtures/no84/policy-fixture.json').readAsStringSync());
    final p = CurrentDecayPolicy.parse(raw)!;
    expect(p.after('training', 'cleanliness', 102, 3600, 10),
        closeTo(101.4, 1e-8));
    expect(
        p.after('growth', 'cleanliness', 102, 7200, 10), closeTo(99.6, 1e-8));
    expect(
        p.after('growth', 'cleanliness', 100, 1800, 10), closeTo(99.65, 1e-8));
    expect(p.after('first_team', 'cleanliness', 100, 3600, 10),
        closeTo(99.8, 1e-8));
    expect(p.after('child', 'cleanliness', 11, 100, 10), 10);
    expect(p.after('child', 'work', 0, 100, 10), 0);
    for (final bad in [-1, double.infinity, double.nan]) {
      final copy = jsonDecode(jsonEncode(raw));
      copy['rates']['child']['cleanliness'] = bad;
      expect(() => CurrentDecayPolicy.parse(copy), throwsFormatException);
    }
  });

  testWidgets('foreground refresh poll adopts new rate within60 ticks',
      (t) async {
    final p = P();
    final c = await open(t, p);
    final map = p.policy as Map;
    map['rates']['child']['cleanliness'] = .3;
    map['revision'] = 'poll';
    p.values['cleanliness'] = 57;
    await t.pump(const Duration(seconds: 60));
    await t.pump();
    await t.pump();
    expect(p.fetches, 1);
    expect(c.meters['清潔'], 57);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(56.7, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('refresh failure pauses rather than fixed fallback', (t) async {
    final p = P();
    final c = await open(t, p);
    p.failFetch = true;
    await c.refreshDecaySettings();
    await t.pump();
    expect(c.isServerStateReady.value, false);
    c.tickTutorialTimer();
    expect(c.meters['清潔'], 75);
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });
  testWidgets('server fractional remainder restored before next tick',
      (t) async {
    final p = P();
    p.remainders = {'cleanliness': .1};
    final c = await open(t, p);
    expect(c.meters['清潔'], closeTo(74.9, 1e-8));
    c.tickTutorialTimer();
    expect(c.meters['清潔'], closeTo(74.8, 1e-8));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });

  testWidgets('main hour progress survives periodic settings refresh',
      (t) async {
    final p = P()..stage = 'training';
    final c = await open(t, p);
    p.elapsed = 3600;
    p.values['cleanliness'] = 74.7;
    await c.refreshDecaySettings();
    await t.pump();
    expect(c.elapsedHours.value, 0);
    await t.pump(const Duration(seconds: 1));
    expect(c.elapsedHours.value, 1);
    expect(c.meters['清潔'], closeTo(74.7, 1e-6));
    c.onClose();
    await t.pump();
    Get.routing.args = null;
  });

  test('1260 production PHP calculator cases match app', () {
    final policy = CurrentDecayPolicy.parse(jsonDecode(
        File('test/fixtures/no84/policy-fixture.json').readAsStringSync()))!;
    final rows =
        jsonDecode(File('test/fixtures/no84/parity-fixture.json').readAsStringSync())
            as List;
    expect(rows.length, 1260);
    for (final row in rows) {
      expect(
          policy.after(row['stage'], row['name'],
              (row['value'] as num).toDouble(), row['seconds'], 10),
          closeTo(row['expected'], 1e-6),
          reason: row.toString());
    }
  });
  testWidgets('review saved work100 remainder01 meets100', (t) async {
    final p=P()..stage='training';p.values['work']=100;p.remainders={'work':.1};p.stageProgress={'required_work_value':100,'next_stage_code':'growth'};
    final c=await open(t,p);expect(c.meters['仕事'],closeTo(99.9,1e-8));c.perform(TrainingActionType.meal);await t.pump();await t.pump();expect(p.stage,'growth');c.onClose();await t.pump();Get.routing.args=null;
  });
  for(final hours in [2,48]){
  testWidgets('review chronological zero hours [$hours]',(t) async {
    final p=P()..stage='training';final policy=p.policy as Map;policy['floor']=0;policy['rates']['training']={'hunger':0,'cleanliness':0,'condition':2.1,'work':0};p.values['condition']=3;p.values['work']=100;
    final c=await open(t,p);c.advanceTime(hours);expect(c.ended.value,false);await t.pump();await t.pump();await c.syncNow();await t.pump();final local=jsonDecode(MySharedPref.getTrainingGameLocalState()!);expect(local['zero_hours']['体調'],hours-1);c.onClose();await t.pump();Get.routing.args=null;
  });}
  testWidgets('review chronological cared day',(t) async {
    final p=P()..stage='training';final policy=p.policy as Map;policy['floor']=0;policy['rates']['training']={'hunger':0,'cleanliness':0,'condition':2.1,'work':0};p.values['condition']=25;p.values['work']=100;
    final c=await open(t,p);c.advanceTime(48);expect(c.daysInStage.value,1);c.onClose();await t.pump();Get.routing.args=null;
  });

  testWidgets('review active multi-hour history and timed growth',(t) async {
    final p=P()..stage='training'..useFakeClock=true;final policy=p.policy as Map;policy['floor']=0;policy['rates']['training']={'hunger':0,'cleanliness':0,'condition':2.1,'work':0};p.values['condition']=3;p.values['work']=100;
    final c=await open(t,p);p.fakeElapsed=7200;await t.pump(const Duration(seconds:1));await t.pump();expect(c.elapsedHours.value,2);expect(p.stage,'training');expect(c.ended.value,false);await c.syncNow();await t.pump();expect(jsonDecode(MySharedPref.getTrainingGameLocalState()!)['zero_hours']['体調'],1);c.onClose();await t.pump();Get.routing.args=null;
  });

  testWidgets('review chronological timed stage48 not24',(t)async{
    final p=P()..stage='training';(p.policy as Map)['rates']['training']={'hunger':0,'cleanliness':0,'condition':0,'work':0};p.values['work']=100;p.stageProgress={'required_elapsed_hours':48,'next_stage_code':'growth'};
    final c=await open(t,p);c.advanceTime(48);expect(c.elapsedHours.value,48);for(var i=0;i<20 && p.stage!='growth';i++)await t.pump();expect(p.stage,'growth',reason:c.logs.join('|')+' '+c.serverErrorMessage.value+' '+c.syncStatusMessage.value);c.onClose();await t.pump();Get.routing.args=null;
  });

  testWidgets('review long interval retains single settlement cap',(t)async{
    final p=P()..stage='training';final policy=p.policy as Map;policy['floor']=0;policy['rates']['training']={'hunger':0,'cleanliness':0,'condition':2.1,'work':0};p.values['condition']=100;p.values['work']=100;
    final c=await open(t,p);c.advanceTime(48);expect(c.meters['体調'],closeTo(74.8,1e-8));c.onClose();await t.pump();Get.routing.args=null;
  });
  testWidgets('review zero limit reaches48 on hour49',(t)async{
    final p=P()..stage='training';final policy=p.policy as Map;policy['floor']=0;policy['rates']['training']={'hunger':0,'cleanliness':0,'condition':2.1,'work':0};p.values['condition']=3;p.values['work']=100;
    final c=await open(t,p);c.advanceTime(49);expect(c.ended.value,true);expect(c.elapsedHours.value,49);c.onClose();await t.pump();Get.routing.args=null;
  });

}

class P extends TrainingGameProvider {
  String stage = 'child';
  bool useFakeClock=false;int fakeElapsed=0;
  int elapsed = 0, fetches = 0;
  bool includePolicy = true, failFetch = false;
  Map<String, num> remainders = {};
  Map<String,dynamic>? stageProgress;
  Object? policy =
      jsonDecode(File('test/fixtures/no84/policy-fixture.json').readAsStringSync());
  Map<String, double> values = {
    'hunger': 100,
    'cleanliness': 75,
    'condition': 100,
    'work': 0
  };
  Map<String, dynamic> state() => {
        'id': 7,
        'cycle_no': 1,
        'lock_version': 0,
        'stage_code': stage,
        'status': 'playing',
        'started_at': '2026-10-27T00:00:00Z',
        'elapsed_seconds': elapsed,
        'work_available': false,
        if(stageProgress!=null)'stage_progress':stageProgress,
        'actions_today': 0,
        if (includePolicy) 'decay_policy': policy,
        'decay_remainders': remainders,
        'parameters': Map.from(values),
        'cooldowns': <String, dynamic>{}
      };
  @override
  Future<Map<String, dynamic>> syncDebugTime(
      {required String stageCode,
      required Map<String, double> parameters,
      required int lockVersion,
      int? expectedSessionVersion}) async {
    stage = stageCode;
    values = Map.from(parameters);
    return state();
  }

  @override
  Future<List<String>> fetchUnlockedPositions(
          {int? expectedSessionVersion}) async =>
      [];
  @override
  Future<Map<String, dynamic>?> fetchCurrent(
      {int? expectedSessionVersion}) async {
    fetches++;
    if (failFetch) throw Exception('offline mock');
    return state();
  }

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
    stage = stageCode;
    values = Map.from(parameters);
    return state();
  }
}
