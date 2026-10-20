import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/providers/training_game/training_game_provider.dart';
import 'package:koto_blue_sharks/presentation/training_game/mini_games/models/mini_game_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'canonical metadata uses integer boundary and preserves allMISS distinction',
      () {
    for (final entry in {
      900000: 'S',
      900001: 'A',
      1350000: 'A',
      1350001: 'B',
      1800000: 'B',
      1800001: 'C',
      2250000: 'C'
    }.entries) {
      expect(
          TackleResultMetadata(
                  successCount: 3, successfulReactionTotalUs: entry.key)
              .rank,
          entry.value);
    }
    expect(
        TackleResultMetadata(successCount: 0, successfulReactionTotalUs: 0)
            .rank,
        'D');
    expect(
        TackleResultMetadata(
                successCount: 3, successfulReactionTotalUs: 2250000)
            .rank,
        'C');
    expect(
        TackleResultMetadata(successCount: 2, successfulReactionTotalUs: 0)
            .rank,
        'S');
    expect(
        TackleResultMetadata(successCount: 1, successfulReactionTotalUs: 0)
            .rank,
        'B');
  });
  test('real provider serializer emits four v2 keys and omits them for legacy',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'accessToken': 'transport-test-token'});
    addTearDown(() => FlutterSecureStorage.setMockInitialValues({}));
    final provider = _CaptureBodyProvider();
    addTearDown(provider.onClose);
    await provider.sync(
        stageCode: 'training',
        parameters: {},
        lockVersion: 0,
        cycleNo: 1,
        actionCode: 'tackle',
        actionIdempotencyKey: 'v2-body',
        actionScore: .75,
        actionResultCode: 'D',
        actionEffectMultiplier: .25,
        actionResultPolicy: TackleResultMetadata.policy,
        actionAttemptCount: 3,
        actionSuccessCount: 0,
        actionSuccessfulReactionTotalUs: 0);
    final v2 =
        Map<String, dynamic>.from(provider.bodies.single['action'] as Map);
    expect(v2['result_policy'], TackleResultMetadata.policy);
    expect(v2['attempt_count'], 3);
    expect(v2['success_count'], 0);
    expect(v2['successful_reaction_total_us'], 0);
    await provider.sync(
        stageCode: 'training',
        parameters: {},
        lockVersion: 0,
        cycleNo: 1,
        actionCode: 'tackle',
        actionIdempotencyKey: 'legacy-body',
        actionScore: .5,
        actionResultCode: 'D',
        actionEffectMultiplier: .25);
    final legacy =
        Map<String, dynamic>.from(provider.bodies.last['action'] as Map);
    for (final key in [
      'result_policy',
      'attempt_count',
      'success_count',
      'successful_reaction_total_us'
    ]) {
      expect(legacy.containsKey(key), isFalse);
    }
    expect(legacy['score'], .5);
    expect(legacy['idempotency_key'], 'legacy-body');
  });
  test('provider rejects incomplete metadata before authentication or network',
      () async {
    final provider = TrainingGameProvider();
    addTearDown(provider.onClose);
    await expectLater(
        provider.sync(
            stageCode: 'training',
            parameters: {},
            lockVersion: 0,
            cycleNo: 1,
            actionCode: 'tackle',
            actionResultPolicy: TackleResultMetadata.policy,
            actionAttemptCount: 3,
            actionSuccessCount: 0),
        throwsArgumentError);
    await expectLater(
        provider.sync(
            stageCode: 'training',
            parameters: {},
            lockVersion: 0,
            cycleNo: 1,
            actionCode: 'tackle',
            actionResultPolicy: TackleResultMetadata.policy,
            actionAttemptCount: 3,
            actionSuccessCount: 0,
            actionSuccessfulReactionTotalUs: 1),
        throwsArgumentError);
    await expectLater(
        provider.sync(
            stageCode: 'training',
            parameters: {},
            lockVersion: 0,
            cycleNo: 1,
            actionCode: 'pass_run',
            actionResultPolicy: TackleResultMetadata.policy,
            actionAttemptCount: 3,
            actionSuccessCount: 0,
            actionSuccessfulReactionTotalUs: 0),
        throwsArgumentError);
  });
}

class _CaptureBodyProvider extends TrainingGameProvider {
  final bodies = <Map<String, dynamic>>[];
  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    dynamic decoder,
    dynamic uploadProgress,
  }) async {
    expect(url, 'game/sync');
    bodies.add(Map<String, dynamic>.from(body as Map));
    return Response<T>(
        statusCode: 200, body: {'data': <String, dynamic>{}} as T);
  }
}
