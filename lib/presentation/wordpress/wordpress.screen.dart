import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/admin_sidebar.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/wordpress.controller.dart';

const _blue = Color(0xFF2F80ED);
const _pageBackground = Color(0xFFF5F7FA);
const _border = Color(0xFFD7E0EA);
const _text = Color(0xFF1D2733);

class WordPressScreen extends GetView<WordPressController> {
  const WordPressScreen({super.key});

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
                    selectedItem: 'WordPress',
                    onItemTap: (item) {
                      if (item == 'QR施策') {
                        Get.offNamed(Routes.QR_CAMPAIGN);
                      }
                    },
                  ),
                  Expanded(child: _WordPressContent(controller: controller)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WordPressContent extends StatelessWidget {
  const _WordPressContent({required this.controller});

  final WordPressController controller;

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
                'WordPress / ホームゲーム記事（外部管理）',
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
            padding: const EdgeInsets.fromLTRB(30, 29, 30, 36),
            child: _WordPressPanel(controller: controller),
          ),
        ),
      ],
    );
  }
}

class _WordPressPanel extends StatelessWidget {
  const _WordPressPanel({required this.controller});

  final WordPressController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(31, 27, 31, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 56,
                child: _ExternalSystemDescription(controller: controller),
              ),
              const SizedBox(width: 31),
              const Expanded(flex: 39, child: _IntegrationRules()),
            ],
          ),
          const SizedBox(height: 24),
          const _WordPressWarning(),
        ],
      ),
    );
  }
}

class _ExternalSystemDescription extends StatelessWidget {
  const _ExternalSystemDescription({required this.controller});

  final WordPressController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 122,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            '外部システム',
            style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '記事の作成・公開・更新・削除は\n既存WordPress管理画面で行います',
          style: TextStyle(
            color: _text,
            fontSize: 25,
            height: 1.48,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 19),
        const Text(
          'BlueSharks管理画面には記事編集機能と記事DBを新設せず、\nWordPress管理画面への導線と連携状態だけを表示します。',
          style: TextStyle(
            color: Color(0xFF6A7684),
            fontSize: 15,
            height: 1.65,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 29),
        SizedBox(
          width: 322,
          height: 39,
          child: ElevatedButton.icon(
            onPressed: controller.canOpenWordPressAdmin
                ? () => _confirmAndOpenExternal(context, controller.wordpressAdminUri)
                : null,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('WordPress管理画面を開く'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blueGrey.shade200,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndOpenExternal(BuildContext context, Uri uri) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('外部ページを開きますか？'),
          content: Text('WordPress管理画面を外部ブラウザで開きます。\n\n$uri'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('開く'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WordPress管理画面を開けませんでした。')),
      );
    }
  }
}

class _IntegrationRules extends StatelessWidget {
  const _IntegrationRules();

  static const _rules = [
    '公開済み記事のみ取得',
    'WordPress表示順を採用',
    '初回・復帰・Pullで更新',
    'タイムアウト約30秒 / 再試行2回',
    '外部URLは確認後ブラウザ起動',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: const Color(0xFFE1E7EF)),
        borderRadius: BorderRadius.circular(7),
      ),
      padding: const EdgeInsets.fromLTRB(26, 21, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アプリ連携仕様',
            style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ..._rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓',
                    style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordPressWarning extends StatelessWidget {
  const _WordPressWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9EB),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        '要確認：表示対象期間、全ユーザー公開、詳細画面で許可するURL / ドメイン。',
        style: TextStyle(color: Color(0xFFCF202A), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
