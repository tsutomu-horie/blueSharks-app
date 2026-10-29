import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/point/point_models.dart';
import 'package:koto_blue_sharks/app/providers/point/api_point_repository.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/point/controllers/point.controller.dart';
import 'package:koto_blue_sharks/presentation/point/point_screens.dart';
import 'package:koto_blue_sharks/presentation/point/widgets/point_reward_image.dart';

Map<String, dynamic> rewardJson(dynamic images) => {
      'id': 1,
      'name': '画像テスト景品',
      'required_points': 10,
      'offers': [
        {'id': 11}
      ],
      'images': images,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const url = 'https://example.test/bluesharks_web/storage/rewards/sample.png';

  test('API image URL preserves HTTPS, subdirectory and query parameters', () {
    final reward = ApiPointRepository.instance.rewardFromJson(rewardJson([
      {'id': 1, 'display_order': 0, 'image_url': '$url?version=2'}
    ]));
    expect(reward.imageUrl, '$url?version=2');
    expect(reward.offerId, '11');
  });

  test('selects usable images by display_order then numeric id', () {
    final reward = ApiPointRepository.instance.rewardFromJson(rewardJson([
      {'id': 1, 'display_order': 0, 'image_url': null},
      {
        'id': 2,
        'display_order': 2,
        'image_url': 'https://example.test/last.png'
      },
      {
        'id': '10',
        'display_order': '1',
        'image_url': 'https://example.test/tie.png'
      },
      {'id': '3', 'display_order': '1', 'image_url': url},
    ]));
    expect(reward.imageUrl, url);
  });

  test('marks a reward unavailable when the API reports the customer limit', () {
    final reward = ApiPointRepository.instance.rewardFromJson({
      'id': 1,
      'name': '上限テスト景品',
      'required_points': 10,
      'offers': [
        {
          'id': 11,
          'per_customer_limit': 1,
          'customer_exchange_count': 1,
        }
      ],
      'images': [],
    });

    expect(reward.perCustomerLimit, 1);
    expect(reward.customerExchangeCount, 1);
    expect(reward.status, PointRewardStatus.customerLimitReached);
  });

  for (final images in [
    null,
    [],
    [null, 'invalid'],
    [
      {'image_path': 'rewards/legacy.png'}
    ],
    [
      {'image_url': ' '},
      {'image_url': '/storage/rewards/a.png'},
      {'image_url': 'javascript:alert(1)'},
      {'image_url': 'https://user:password@example.test/a.png'},
    ],
  ]) {
    test('missing or invalid public URL uses fallback: $images', () {
      expect(
          ApiPointRepository.instance
              .rewardFromJson(rewardJson(images))
              .imageUrl,
          isNull);
    });
  }

  setUp(() {
    Get.testMode = true;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    Get.reset();
  });

  for (final status in [200, 404]) {
    testWidgets('list and detail load the public image (HTTP $status)',
        (tester) async {
      final transport = _ImageClient(status);
      debugNetworkImageHttpClientProvider = () => transport;
      try {
        final reward = ApiPointRepository.instance.rewardFromJson(rewardJson([
          {'id': 1, 'display_order': 0, 'image_url': url}
        ]));
        Get.put<PointController>(_ImageController(reward));
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        if (status == 200) {
          await tester.runAsync(() => precacheImage(NetworkImage(url),
              tester.element(find.byType(PointRewardImage))));
          await tester.pumpAndSettle();
        }

        expect(find.byType(PointRewardImage), findsOneWidget);
        expect(transport.visited, contains(Uri.parse(url)));
        expect(find.byIcon(Icons.card_giftcard),
            status == 200 ? findsNothing : findsOneWidget);
        if (status == 200) {
          final image = tester.widget<Image>(find.descendant(
              of: find.byType(PointRewardImage), matching: find.byType(Image)));
          expect(image.fit, BoxFit.contain);
          expect(
              find.descendant(
                  of: find.byType(PointRewardImage),
                  matching: find.byType(RawImage)),
              findsOneWidget);
          final decoded = tester.widget<RawImage>(find.descendant(
              of: find.byType(PointRewardImage),
              matching: find.byType(RawImage)));
          expect(decoded.image, isNotNull);
        }

        await tester.tap(find.text('画像テスト景品'));
        await tester.pumpAndSettle();
        expect(find.text('景品詳細'), findsOneWidget);
        final detail =
            tester.widget<PointRewardImage>(find.byType(PointRewardImage).last);
        expect(detail.url, url);
        if (status == 200) {
          final decoded = tester.widget<RawImage>(find.descendant(
              of: find.byType(PointRewardImage),
              matching: find.byType(RawImage)));
          expect(decoded.image, isNotNull);
        }
        expect(find.byIcon(Icons.card_giftcard),
            status == 200 ? findsNothing : findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugNetworkImageHttpClientProvider = null;
      }
    });
  }

  testWidgets('no image stays a gift icon in both list and detail',
      (tester) async {
    final transport = _ImageClient(200);
    debugNetworkImageHttpClientProvider = () => transport;
    try {
      Get.put<PointController>(_ImageController(
          ApiPointRepository.instance.rewardFromJson(rewardJson([]))));
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      await tester.tap(find.text('画像テスト景品'));
      await tester.pumpAndSettle();
      expect(find.text('景品詳細'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      expect(transport.visited, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets('customer limit appears unavailable in list and detail',
      (tester) async {
    final reward = ApiPointRepository.instance.rewardFromJson({
      'id': 1,
      'name': '上限テスト景品',
      'required_points': 10,
      'offers': [
        {
          'id': 11,
          'per_customer_limit': 1,
          'customer_exchange_count': 1,
        }
      ],
      'images': [],
    });
    Get.put<PointController>(_ImageController(reward));

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('交換上限に達しています'), findsOneWidget);

    await tester.tap(find.text('上限テスト景品'));
    await tester.pumpAndSettle();
    expect(find.text('この景品の交換上限に達しています'), findsOneWidget);
    final detailButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '交換上限に達しています'),
    );
    expect(detailButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer limit disables the confirmation action', (tester) async {
    final reward = ApiPointRepository.instance.rewardFromJson({
      'id': 1,
      'name': '上限テスト景品',
      'required_points': 10,
      'offers': [
        {
          'id': 11,
          'per_customer_limit': 1,
          'customer_exchange_count': 1,
        }
      ],
      'images': [],
    });
    final controller = _ImageController(reward)
      ..selectedReward.value = reward
      ..account.value = const PointAccount(
        balance: 100,
        lifetimeEarned: 100,
        lifetimeSpent: 0,
      );
    Get.put<PointController>(controller);

    await tester.pumpWidget(
      _app(initialRoute: Routes.POINT_EXCHANGE_CONFIRM),
    );
    await tester.pumpAndSettle();
    expect(find.text('この景品の交換上限に達しているため、交換できません。'),
        findsOneWidget);
    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '交換上限に達しています'),
    );
    expect(confirmButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({String initialRoute = Routes.POINT_REWARDS}) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => GetMaterialApp(
        initialRoute: initialRoute,
        getPages: [
          GetPage(
              name: Routes.POINT_REWARDS,
              page: () => const PointRewardsScreen()),
          GetPage(
              name: Routes.POINT_REWARD_DETAIL,
              page: () => const PointRewardDetailScreen()),
          GetPage(
              name: Routes.POINT_EXCHANGE_CONFIRM,
              page: () => const PointExchangeConfirmScreen()),
        ],
      ),
    );

class _ImageController extends PointController {
  _ImageController(this.reward);
  final PointReward reward;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadRewards() async {
    rewards.assignAll([reward]);
    account.value =
        const PointAccount(balance: 100, lifetimeEarned: 100, lifetimeSpent: 0);
  }

  @override
  Future<void> loadReward(String id) async {
    selectedReward.value = reward;
  }
}

// Generated one-pixel fixture, never a user's uploaded image. No real network.
class _ImageClient implements HttpClient {
  _ImageClient(this.status);
  final int status;
  final visited = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    visited.add(url);
    return _ImageRequest(status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageRequest implements HttpClientRequest {
  _ImageRequest(this.status);
  final int status;
  @override
  final HttpHeaders headers = _ImageHeaders();
  @override
  Future<HttpClientResponse> close() async => _ImageResponse(status);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse(this.statusCode);
  @override
  final int statusCode;
  final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFUCNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC');
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream.value(bytes).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
