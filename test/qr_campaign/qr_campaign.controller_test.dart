import 'package:flutter_test/flutter_test.dart';

import 'package:koto_blue_sharks/presentation/qr_campaign/controllers/qr_campaign.controller.dart';
import 'package:koto_blue_sharks/presentation/qr_campaign/models/qr_campaign_models.dart';

void main() {
  late QrCampaignController controller;

  setUp(() {
    controller = QrCampaignController();
    controller.onInit();
  });

  tearDown(() {
    controller.onClose();
  });

  test('初期状態はワイヤーフレームの2件を表示する', () {
    expect(controller.visibleCampaigns, hasLength(2));
    expect(controller.selectedCampaignId.value, 'QRC-0001');
    expect(controller.nameController.text, 'ホームゲーム来場');
  });

  test('新規作成して保存すると連番IDで一覧へ追加する', () {
    controller.startCreating();
    controller.nameController.text = 'テスト来場';
    controller.selectedStatus.value = QrCampaignStatus.draft;

    expect(controller.saveCampaign(), isTrue);
    expect(controller.campaigns, hasLength(3));
    expect(controller.selectedCampaignId.value, 'QRC-0003');
    expect(controller.campaigns.last.name, 'テスト来場');
  });

  test('施策名が空の場合は保存しない', () {
    controller.nameController.clear();

    expect(controller.saveCampaign(), isFalse);
    expect(controller.campaigns, hasLength(2));
  });
}
