import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_home_roaming_character.dart';

const _avatarKey = ValueKey<String>('roaming-avatar');

Widget _host({
  bool enabled = true,
  Duration idleDuration = const Duration(milliseconds: 1),
  Duration walkDuration = const Duration(seconds: 1),
  TrainingHomeWalkPreparation? prepareWalk,
  Object? preparationKey,
  bool reactToTap = false,
  TrainingGameSoundService Function()? soundFactory,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: TrainingHomeRoamingCharacter(
              random: math.Random(2),
              prepareWalk: prepareWalk,
              preparationKey: preparationKey,
              builder: (_, isWalking) => SizedBox.expand(
                key: _avatarKey,
                child: Text(isWalking ? 'walking' : 'idle'),
              ),
              width: 80,
              height: 80,
              travelDistance: 100,
              idleDuration: idleDuration,
              walkDuration: walkDuration,
              enabled: enabled,
              reactToTap: reactToTap,
              soundFactory: soundFactory ?? TrainingGameSoundService.new,
            ),
          ),
        ),
      ),
    );

Widget _breathingHost({bool enabled = true}) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: TrainingHomeIdleMotion(
            enabled: enabled,
            child: const SizedBox(
              key: _avatarKey,
              width: 80,
              height: 120,
            ),
          ),
        ),
      ),
    );

Widget _animationHost(
  TrainingHomeCharacterFrameSet frameSet, {
  required bool isWalking,
}) =>
    MaterialApp(
      home: TrainingHomeCharacterAnimation(
        key: const ValueKey<String>('adult-character'),
        frameSet: frameSet,
        isWalking: isWalking,
        width: 128,
        height: 184,
      ),
    );

String _shownAsset(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

void main() {
  testWidgets('画面非表示で反応を取り消し、戻ると元の歩行を再開する', (t) async {
    Widget host(bool active) =>
        TickerMode(enabled: active, child: _host(reactToTap: true));
    await t.pumpWidget(host(true));
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(_avatarKey));
    await t.pump();
    await t.pumpWidget(host(false));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('idle'), findsOneWidget);
    await t.pumpWidget(host(true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 30));
    expect(find.text('walking'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('SE準備が遅れた場合は後から再生しない', (t) async {
    var sounds = 0;
    final configured = Completer<void>();
    final sound = TrainingGameSoundService(
        configureAudioSession: () => configured.future,
        createPlayer: (_) => _TapPlayer(() => sounds++));
    await t.pumpWidget(
        _host(enabled: false, reactToTap: true, soundFactory: () => sound));
    await t.tap(find.byKey(_avatarKey));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    configured.complete();
    await t.pump();
    expect(sounds, 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('歩行中のタップで停止し、連打を無視して同じ方向へ再開する', (t) async {
    var sounds = 0;
    final service = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (_) => _TapPlayer(() => sounds++));
    await t.pumpWidget(_host(reactToTap: true, soundFactory: () => service));
    await t.pump(const Duration(milliseconds: 1));
    final before = t.getCenter(find.byKey(_avatarKey)).dx;
    await t.pump(const Duration(milliseconds: 100));
    final stopped = t.getCenter(find.byKey(_avatarKey)).dx;
    expect(find.text('walking'), findsOneWidget);
    await t.tap(find.byKey(_avatarKey));
    await t.pump();
    expect(find.text('idle'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300));
    expect(t.getCenter(find.byKey(_avatarKey)).dx, closeTo(stopped, .001));
    await t.tap(find.byKey(_avatarKey));
    await t.pump(const Duration(milliseconds: 451));
    await t.pump(const Duration(milliseconds: 299));
    expect(find.text('idle'), findsOneWidget);
    expect(sounds, 1);
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(const Duration(milliseconds: 30));
    expect(find.text('walking'), findsOneWidget);
    final resumed = t.getCenter(find.byKey(_avatarKey)).dx;
    expect((resumed - stopped).sign, (stopped - before).sign);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('素材準備中のタップは古い歩行開始を破棄する', (t) async {
    final prepared = Completer<bool>();
    await t.pumpWidget(
        _host(reactToTap: true, prepareWalk: (_) => prepared.future));
    await t.pump(const Duration(milliseconds: 1));
    await t.tap(find.byKey(_avatarKey));
    await t.pump();
    prepared.complete(true);
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('idle'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('反応中のアプリ中断でSEを破棄し、復帰時に再演出しない', (t) async {
    var disposed = 0;
    final service = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (_) => _TapPlayer(() {}, onDispose: () => disposed++));
    await t.pumpWidget(_host(reactToTap: true, soundFactory: () => service));
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(_avatarKey));
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump(const Duration(seconds: 2));
    expect(disposed, 1);
    expect(find.text('idle'), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 30));
    expect(find.text('walking'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('移動距離を親の左右境界内に制限する', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    final avatar = tester.getRect(find.byKey(_avatarKey));
    expect(find.text('walking'), findsOneWidget);
    expect(avatar.left, greaterThanOrEqualTo(0));
    expect(avatar.right, lessThanOrEqualTo(200));
  });

  testWidgets('繰り返し歩行の距離が変化し、常に画面内に収まる', (tester) async {
    await tester.pumpWidget(_host());
    final positions = <double>{};
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final rect = tester.getRect(find.byKey(_avatarKey));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(200));
      if (find.text('idle').evaluate().isNotEmpty) positions.add(rect.left);
    }
    expect(positions.length, greaterThan(3));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('enabled=falseで歩行を停止して中央に戻す', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('walking'), findsOneWidget);

    await tester.pumpWidget(_host(enabled: false));
    await tester.pump();

    final avatar = tester.getRect(find.byKey(_avatarKey));
    expect(find.text('idle'), findsOneWidget);
    expect(avatar.left, closeTo(60, 0.01));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('walking'), findsNothing);
  });

  testWidgets('walk素材の先読み中はidleのまま位置も変えない', (tester) async {
    final prepared = Completer<bool>();
    await tester.pumpWidget(
      _host(prepareWalk: (_) => prepared.future),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    final idleRect = tester.getRect(find.byKey(_avatarKey));
    expect(find.text('idle'), findsOneWidget);
    expect(idleRect.left, closeTo(60, 0.01));
    expect(idleRect.right, closeTo(140, 0.01));

    prepared.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('walking'), findsOneWidget);
    expect(tester.getRect(find.byKey(_avatarKey)).left, closeTo(60, 0.01));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        tester.getRect(find.byKey(_avatarKey)).left, isNot(closeTo(60, 0.01)));
  });

  testWidgets('衣装切替時に古い素材準備が終わっても歩行を始めない', (tester) async {
    final oldPreparation = Completer<bool>();
    final newPreparation = Completer<bool>();
    final newPreparationRequested = Completer<void>();
    await tester.pumpWidget(
      _host(
        preparationKey: 'normal',
        prepareWalk: (_) => oldPreparation.future,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));

    await tester.pumpWidget(
      _host(
        preparationKey: 'pr',
        prepareWalk: (_) {
          newPreparationRequested.complete();
          return newPreparation.future;
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(newPreparationRequested.isCompleted, isTrue);

    oldPreparation.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('idle'), findsOneWidget);
    expect(tester.getRect(find.byKey(_avatarKey)).left, closeTo(60, 0.01));

    newPreparation.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('walking'), findsOneWidget);
  });

  testWidgets('素材準備中に無効化したら完了後も歩かない', (tester) async {
    final prepared = Completer<bool>();
    await tester.pumpWidget(
      _host(prepareWalk: (_) => prepared.future),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(_host(enabled: false));
    prepared.complete(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('idle'), findsOneWidget);
    expect(tester.getRect(find.byKey(_avatarKey)).left, closeTo(60, 0.01));
  });

  testWidgets('disposeで待機Timerを破棄する', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  testWidgets('歩行中にdisposeしてもAnimationControllerが残らない', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('walking'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  testWidgets('幼体は足元と横位置を保って小さく呼吸する', (tester) async {
    await tester.pumpWidget(_breathingHost());
    final before = tester.getRect(find.byKey(_avatarKey));
    await tester.pump(const Duration(milliseconds: 900));
    final inhale = tester.getRect(find.byKey(_avatarKey));

    expect(inhale.height, greaterThan(before.height));
    expect(inhale.bottom, closeTo(before.bottom, 0.01));
    expect(inhale.center.dx, closeTo(before.center.dx, 0.01));

    await tester.pumpWidget(_breathingHost(enabled: false));
    await tester.pump();
    final staticRect = tester.getRect(find.byKey(_avatarKey));
    await tester.pump(const Duration(seconds: 2));
    final laterRect = tester.getRect(find.byKey(_avatarKey));
    expect(laterRect, staticRect);
  });

  test('全frameが共通canvasを使い、実alpha境界と足元を正確に表す', () {
    for (final bodyKey in <String?>[null, 'pr', 'sh', 'wtb']) {
      final frames = TrainingHomeCharacterFrameSet.forBodyKey(bodyKey);
      expect(
        TrainingHomeCharacterFrameSet.forBodyKey(bodyKey),
        same(frames),
        reason: '$bodyKey frame set is cached',
      );
      expect(frames.idleFrames, isNotEmpty);
      expect(frames.walkFrames, isNotEmpty);
      for (final frame in [...frames.idleFrames, ...frames.walkFrames]) {
        expect(frame.canvasSize, frames.canvasSize, reason: frame.asset);
        expect(
          frame.visibleBounds.bottom,
          closeTo(frames.canvasSize.height, 0.001),
          reason: frame.asset,
        );
        final isShorterNormalIdle =
            bodyKey == null && frame.asset.endsWith('normal_sametaroh_2.png');
        expect(
          frame.visibleBounds.height,
          closeTo(
              frames.canvasSize.height - (isShorterNormalIdle ? 1 : 0), 0.001),
          reason: '${frame.asset}: source alpha height',
        );
        expect(
          frame.visibleBounds.top,
          closeTo(isShorterNormalIdle ? 1 : 0, 0.001),
          reason: '${frame.asset}: source alpha top',
        );
        expect(
          frame.visibleBounds.left,
          greaterThanOrEqualTo(-0.001),
          reason: frame.asset,
        );
        expect(frame.visibleBounds.right,
            lessThanOrEqualTo(frames.canvasSize.width + 0.001),
            reason: frame.asset);
      }
    }
  });

  testWidgets('idle→walk→idleを各素材フレームで連続表示する', (tester) async {
    final frames = TrainingHomeCharacterFrameSet.forBodyKey('pr');
    await tester.pumpWidget(_animationHost(frames, isWalking: false));
    await tester.pumpAndSettle();
    await tester.pump();

    final animation = find.byType(TrainingHomeCharacterAnimation);
    final state = tester.state(animation);
    expect(_shownAsset(tester), frames.idleFrames.first.asset);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
    expect(_shownAsset(tester), frames.idleFrames[1].asset);

    await tester.pumpWidget(_animationHost(frames, isWalking: true));
    await tester.pump();
    expect(tester.state(animation), same(state));
    expect(_shownAsset(tester), frames.walkFrames.first.asset);
    await tester.pump(const Duration(milliseconds: 700));
    expect(_shownAsset(tester), frames.walkFrames[1].asset);

    await tester.pumpWidget(_animationHost(frames, isWalking: false));
    await tester.pump();
    expect(tester.state(animation), same(state));
    expect(_shownAsset(tester), frames.idleFrames.first.asset);
    await tester.pump(const Duration(milliseconds: 700));
    expect(_shownAsset(tester), frames.idleFrames[1].asset);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _TapPlayer implements TrainingGameEffectPlayer {
  _TapPlayer(this.onPlay, {this.onDispose});
  final VoidCallback onPlay;
  final VoidCallback? onDispose;
  @override
  Future<void> play() async => onPlay();
  @override
  Future<void> dispose() async => onDispose?.call();
}
