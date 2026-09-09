import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/qr_campaign_models.dart';

class QrCampaignController extends GetxController {
  final campaigns = <QrCampaign>[
    const QrCampaign(
      id: 'QRC-0001',
      name: 'ホームゲーム来場',
      points: '調整値',
      startAt: '2026/08/01 00:00',
      endAt: '2026/08/31 23:59',
      status: QrCampaignStatus.scheduled,
      maxPerMember: '1回',
      offlineReception: '許可',
      readMode: 'カメラ起動',
    ),
    const QrCampaign(
      id: 'QRC-0002',
      name: 'イベント来場',
      points: '調整値',
      startAt: '2026/07/01 00:00',
      endAt: '2026/07/31 23:59',
      status: QrCampaignStatus.active,
      maxPerMember: '1回',
      offlineReception: '許可',
      readMode: 'カメラ起動',
    ),
  ].obs;

  final selectedCampaignId = RxnString('QRC-0001');
  final selectedStatus = QrCampaignStatus.draft.obs;
  final isCreating = false.obs;

  final nameController = TextEditingController(text: 'ホームゲーム来場');
  final pointsController = TextEditingController(text: '調整値');
  final startAtController = TextEditingController(text: '2026/08/01 00:00');
  final endAtController = TextEditingController(text: '2026/08/31 23:59');
  final maxPerMemberController = TextEditingController(text: '1回');
  final offlineReceptionController = TextEditingController(text: '許可');

  List<QrCampaign> get visibleCampaigns {
    return campaigns.toList();
  }

  @override
  void onInit() {
    super.onInit();
    selectCampaign(campaigns.first);
  }

  void selectCampaign(QrCampaign campaign) {
    selectedCampaignId.value = campaign.id;
    isCreating.value = false;
    nameController.text = campaign.name;
    pointsController.text = campaign.points;
    startAtController.text = campaign.startAt;
    endAtController.text = campaign.endAt;
    maxPerMemberController.text = campaign.maxPerMember;
    offlineReceptionController.text = campaign.offlineReception;
    selectedStatus.value = campaign.status;
  }

  void startCreating() {
    selectedCampaignId.value = null;
    isCreating.value = true;
    nameController.clear();
    pointsController.text = '調整値';
    startAtController.text = '2026/09/01 00:00';
    endAtController.text = '2026/09/30 23:59';
    maxPerMemberController.text = '1回';
    offlineReceptionController.text = '許可';
    selectedStatus.value = QrCampaignStatus.draft;
  }

  bool saveCampaign() {
    final name = nameController.text.trim();
    if (name.isEmpty || startAtController.text.trim().isEmpty || endAtController.text.trim().isEmpty) {
      return false;
    }

    final id = selectedCampaignId.value ?? _nextCampaignId();
    final campaign = QrCampaign(
      id: id,
      name: name,
      points: pointsController.text.trim().isEmpty ? '調整値' : pointsController.text.trim(),
      startAt: startAtController.text.trim(),
      endAt: endAtController.text.trim(),
      status: selectedStatus.value,
      maxPerMember: maxPerMemberController.text.trim().isEmpty
          ? '1回'
          : maxPerMemberController.text.trim(),
      offlineReception: offlineReceptionController.text.trim().isEmpty
          ? '許可'
          : offlineReceptionController.text.trim(),
      readMode: 'カメラ起動',
    );

    final existingIndex = campaigns.indexWhere((item) => item.id == id);
    if (existingIndex == -1) {
      campaigns.add(campaign);
    } else {
      campaigns[existingIndex] = campaign;
      campaigns.refresh();
    }
    selectCampaign(campaign);
    return true;
  }

  String _nextCampaignId() {
    final maxNumber = campaigns.fold<int>(0, (currentMax, campaign) {
      final number = int.tryParse(campaign.id.replaceFirst('QRC-', '')) ?? 0;
      return number > currentMax ? number : currentMax;
    });
    return 'QRC-${(maxNumber + 1).toString().padLeft(4, '0')}';
  }

  @override
  void onClose() {
    nameController.dispose();
    pointsController.dispose();
    startAtController.dispose();
    endAtController.dispose();
    maxPerMemberController.dispose();
    offlineReceptionController.dispose();
    super.onClose();
  }
}
