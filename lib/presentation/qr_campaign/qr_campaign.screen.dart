import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/admin_sidebar.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';

import 'controllers/qr_campaign.controller.dart';
import 'models/qr_campaign_models.dart';

const _navy = Color(0xFF132941);
const _blue = Color(0xFF2F80ED);
const _pageBackground = Color(0xFFF5F7FA);
const _border = Color(0xFFD7E0EA);
const _text = Color(0xFF1D2733);

class QrCampaignScreen extends GetView<QrCampaignController> {
  const QrCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = math.max(constraints.maxWidth, 1280.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: pageWidth,
              height: constraints.maxHeight,
              child: Row(
                children: [
                  AdminSidebar(
                    selectedItem: 'QR施策',
                    wireframeLabel: 'WIREFRAME ・ 13',
                    requiredPermissionLabel:
                        'point.qr-campaign.view\npoint.qr-campaign.manage',
                    onItemTap: (item) {
                      if (item == 'WordPress') {
                        Get.toNamed(Routes.WORDPRESS);
                      }
                    },
                  ),
                  Expanded(child: _QrCampaignContent(controller: controller)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QrCampaignContent extends StatelessWidget {
  const _QrCampaignContent({required this.controller});

  final QrCampaignController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: [
              const Text(
                'QR施策  /  QR施策',
                style: TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '管理者01',
                style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
              ),
              const SizedBox(width: 5),
              Icon(Icons.keyboard_arrow_down, size: 17, color: Colors.blueGrey.shade700),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 17, 30, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionBar(controller: controller),
                const SizedBox(height: 18),
                _CampaignTable(controller: controller),
                const SizedBox(height: 30),
                _CampaignSettings(controller: controller),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final QrCampaignController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const _SpecLegend(),
        const SizedBox(width: 32),
        SizedBox(
          height: 37,
          width: 190,
          child: ElevatedButton.icon(
            onPressed: controller.startCreating,
            icon: const Icon(Icons.add, size: 19),
            label: const Text('QR施策を作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecLegend extends StatelessWidget {
  const _SpecLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendChip(label: '確定', backgroundColor: const Color(0xFFE8F2FF), foregroundColor: _blue),
        const SizedBox(width: 7),
        _LegendChip(
          label: '調整値',
          backgroundColor: const Color(0xFFFFF3D5),
          foregroundColor: const Color(0xFF9A6500),
        ),
        const SizedBox(width: 7),
        _LegendChip(
          label: '要確認',
          backgroundColor: const Color(0xFFFFE9EB),
          foregroundColor: const Color(0xFFCF202A),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 69,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CampaignTable extends StatelessWidget {
  const _CampaignTable({required this.controller});

  final QrCampaignController controller;

  static const _widths = [176.0, 139.0, 128.0, 187.0, 128.0, 129.0, 79.0];
  static const _headers = ['施策ID', '施策名', '付与pt', '実施期間', '状態', '操作', '読取'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.visibleCampaigns;
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 966,
          child: Column(
            children: [
              _TableRow(
                cells: _headers,
                widths: _widths,
                backgroundColor: _navy,
                textColor: Colors.white,
                isHeader: true,
              ),
              if (rows.isEmpty)
                Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: _border),
                      right: BorderSide(color: _border),
                      bottom: BorderSide(color: _border),
                    ),
                  ),
                  child: const Text(
                    '該当するQR施策はありません',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                )
              else
                ...rows.map(
                  (campaign) => _CampaignTableRow(
                    campaign: campaign,
                    widths: _widths,
                    selected: campaign.id == controller.selectedCampaignId.value,
                    onTap: () => controller.selectCampaign(campaign),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.widths,
    required this.backgroundColor,
    required this.textColor,
    this.isHeader = false,
  });

  final List<String> cells;
  final List<double> widths;
  final Color backgroundColor;
  final Color textColor;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isHeader ? 34 : 49,
      color: backgroundColor,
      child: Row(
        children: List.generate(
          cells.length,
          (index) => SizedBox(
            width: widths[index],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  cells[index],
                  style: TextStyle(
                    color: textColor,
                    fontSize: isHeader ? 12 : 11,
                    fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignTableRow extends StatelessWidget {
  const _CampaignTableRow({
    required this.campaign,
    required this.widths,
    required this.selected,
    required this.onTap,
  });

  final QrCampaign campaign;
  final List<double> widths;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final values = [
      campaign.id,
      campaign.name,
      campaign.points,
      campaign.period.replaceAll(' 00:00', '').replaceAll(' 23:59', ''),
      campaign.status.label,
      '編集',
      campaign.readMode,
    ];
    return Material(
      color: selected ? const Color(0xFFF8FBFF) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 49,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: _border),
              right: BorderSide(color: _border),
              bottom: BorderSide(color: _border),
            ),
          ),
          child: Row(
            children: List.generate(
              values.length,
              (index) => SizedBox(
                width: widths[index],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: index == 4
                        ? _StatusText(status: campaign.status)
                        : Text(
                            values[index],
                            style: const TextStyle(color: _text, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.status});

  final QrCampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      QrCampaignStatus.active => const Color(0xFF129451),
      QrCampaignStatus.scheduled => _blue,
      QrCampaignStatus.adjustment => const Color(0xFF9A6500),
      QrCampaignStatus.needsReview => const Color(0xFFCF202A),
      QrCampaignStatus.draft => Colors.blueGrey,
    };
    return Text(
      status.label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    );
  }
}

class _CampaignSettings extends StatelessWidget {
  const _CampaignSettings({required this.controller});

  final QrCampaignController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(21, 17, 25, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(
              controller.isCreating.value ? '施策設定（新規作成）' : '施策設定',
              style: const TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 27, child: _InputField(label: '施策名', controller: controller.nameController)),
              const SizedBox(width: 14),
              Expanded(
                flex: 16,
                child: _InputField(
                  label: '付与ポイント',
                  helperText: '運用で調整',
                  controller: controller.pointsController,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(flex: 22, child: _InputField(label: '開始日時', controller: controller.startAtController)),
              const SizedBox(width: 14),
              Expanded(flex: 24, child: _InputField(label: '終了日時', controller: controller.endAtController)),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 20, child: _InputField(label: '会員あたり上限', controller: controller.maxPerMemberController)),
              const SizedBox(width: 14),
              Expanded(flex: 17, child: _InputField(label: 'オフライン受付', controller: controller.offlineReceptionController)),
              const SizedBox(width: 14),
              Expanded(
                flex: 17,
                child: Obx(
                  () => _StatusDropdown(
                    value: controller.selectedStatus.value,
                    onChanged: (value) {
                      if (value != null) controller.selectedStatus.value = value;
                    },
                  ),
                ),
              ),
              const Spacer(flex: 18),
              SizedBox(
                width: 172,
                height: 37,
                child: ElevatedButton(
                  onPressed: () {
                    final saved = controller.saveCampaign();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(saved ? 'QR施策を保存しました（仮実装）' : '施策名・実施期間を入力してください'),
                          backgroundColor: saved ? const Color(0xFF238653) : const Color(0xFFCF202A),
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9EB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              '要確認：固定会員QR方式と読取時刻を含む方式の回答が競合。ペイロード・有効期限・署名方式を確定する。',
              style: TextStyle(color: Color(0xFFCF202A), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label, required this.controller, this.helperText});

  final String label;
  final String? helperText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF617082), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: _text, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _blue, width: 1.2),
              ),
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 2),
            child: Text(helperText!, style: const TextStyle(color: Color(0xFF8190A0), fontSize: 10)),
          ),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final QrCampaignStatus value;
  final ValueChanged<QrCampaignStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('状態', style: TextStyle(color: Color(0xFF617082), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<QrCampaignStatus>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 17),
            style: const TextStyle(color: _text, fontSize: 13),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: const BorderSide(color: _border),
              ),
            ),
            items: QrCampaignStatus.values
                .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                .toList(),
          ),
        ),
      ],
    );
  }
}
