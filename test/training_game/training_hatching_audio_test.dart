import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koto_blue_sharks/app/services/training_game_sound_service.dart';
import 'package:koto_blue_sharks/presentation/training_game/sametaroh_asset.dart';
import 'package:koto_blue_sharks/presentation/training_game/training_hatching_scene.dart';

class _Player
    implements
        TrainingGameResumableEffectPlayer,
        TrainingGamePreparableEffectPlayer {
  _Player({this.ready});
  final Completer<void>? ready;
  final events = <String>[];
  @override
  Future<void> prepare() async {
    await ready?.future;
  }

  @override
  Future<void> play() async {
    events.add('play');
  }

  @override
  Future<void> pause() async {
    events.add('pause');
  }

  @override
  Future<void> resume() async {
    events.add('resume');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized()
      .handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  Widget scene(TrainingGameSoundService service,
          {bool playing = true,
          bool reduced = false,
          VoidCallback? onCompleted,
          VoidCallback? onLoadFailed}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                  body: Center(
                      child: TrainingHatchingScene(
                          isPlaying: playing,
                          soundFactory: () => service,
                          onCompleted: onCompleted ?? () {},
                          onLoadFailed: onLoadFailed)))));

  Future<void> preload(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      for (final path in [
        TrainingHatchingScene.eggAsset,
        TrainingHatchingScene.silhouetteAsset,
        SametarohAssets.newbornFrame.asset
      ]) {
        await precacheImage(AssetImage(path), context);
      }
    });
  }

  TrainingGameSoundService service(_Player player) => TrainingGameSoundService(
      configureAudioSession: () async {},
      createPlayer: (path) {
        expect(path, TrainingGameSoundEffect.hatching.assetPath);
        return player;
      });

  testWidgets('A案の合成音源が標準bundleに含まれる', (tester) async {
    final bytes =
        await rootBundle.load(TrainingGameSoundEffect.hatching.assetPath);
    expect(bytes.lengthInBytes, greaterThan(1000));
    expect(String.fromCharCodes(bytes.buffer.asUint8List(4, 4)), 'ftyp');
  });

  testWidgets('開始前には鳴らず、停止・復帰しても先頭再生を繰り返さない', (tester) async {
    await preload(tester);
    final player = _Player();
    final sound = service(player);
    var completed = 0;
    await tester.pumpWidget(
        scene(sound, playing: false, onCompleted: () => completed++));
    await tester.pumpAndSettle();
    expect(player.events, isEmpty);
    await tester.pumpWidget(scene(sound, onCompleted: () => completed++));
    await tester.pump();
    expect(player.events, ['play']);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('あれ？ 卵が動きはじめた！'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
    expect(find.text('あれ？ 卵が動きはじめた！'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));
    expect(completed, 1);
    await tester.pumpWidget(scene(sound, onCompleted: () => completed++));
    await tester.pump();
    expect(player.events, containsAllInOrder(['play', 'pause', 'resume']));
    expect(player.events.where((e) => e == 'play').length, 1);
    await tester.pumpWidget(const SizedBox());
    expect(player.events.last, 'dispose');
  });

  testWidgets('音源準備中の中断と準備完了後の復帰で1回だけ開始する', (tester) async {
    await preload(tester);
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    final sound = service(player);
    var completed = 0;
    await tester.pumpWidget(scene(sound, onCompleted: () => completed++));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    ready.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(player.events, isEmpty);
    expect(completed, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4210));
    expect(player.events, ['play']);
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('準備が600msを超えても孵化は無音で進み、後から音を出さない', (tester) async {
    await preload(tester);
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    final sound = service(player);
    var completed = 0;
    await tester.pumpWidget(scene(sound, onCompleted: () => completed++));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 601));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4210));
    expect(completed, 1);
    expect(player.events, ['dispose']);
    ready.complete();
    await tester.pump();
    expect(player.events, ['dispose']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('準備中に破棄しても遅れて再生・完了しない', (tester) async {
    await preload(tester);
    final ready = Completer<void>();
    final player = _Player(ready: ready);
    var completed = 0;
    await tester
        .pumpWidget(scene(service(player), onCompleted: () => completed++));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    ready.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(player.events, ['dispose']);
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('音源準備失敗では画像ロード失敗にせず孵化を完了する', (tester) async {
    await preload(tester);
    var completed = 0;
    var failed = 0;
    final sound = TrainingGameSoundService(
        configureAudioSession: () async {},
        createPlayer: (_) => throw StateError('audio unavailable'));
    await tester.pumpWidget(scene(sound,
        onCompleted: () => completed++, onLoadFailed: () => failed++));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4210));
    expect(completed, 1);
    expect(failed, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('動きを減らす設定では音を作らず450msで完了する', (tester) async {
    await preload(tester);
    final player = _Player();
    var completed = 0;
    await tester.pumpWidget(
        scene(service(player), reduced: true, onCompleted: () => completed++));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, 1);
    expect(player.events, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
