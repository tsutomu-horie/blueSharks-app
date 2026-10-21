import 'package:flutter/material.dart';

import 'controllers/training_game.controller.dart';
import 'models/training_debug_growth.dart';

/// サーバーの候補取得、分岐選択、置換の確認を順に行います。
class TrainingDebugGrowthDialog extends StatefulWidget {
  const TrainingDebugGrowthDialog({super.key, required this.controller});
  final TrainingGameController controller;

  @override
  State<TrainingDebugGrowthDialog> createState() =>
      _TrainingDebugGrowthDialogState();
}

class _TrainingDebugGrowthDialogState extends State<TrainingDebugGrowthDialog> {
  TrainingDebugGrowthOptions? _options;
  String? _selected;
  String? _error;
  bool _loading = true;
  bool _confirming = false;
  bool _starting = false;
  bool _failedStart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.controller.fetchDebugGrowthOptions();
      if (mounted) setState(() => _options = options);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '開始条件を取得できません。通信とサーバーの対応状況を確認してください。');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_starting || _selected == null || _options == null) return;
    setState(() => _starting = true);
    try {
      await widget.controller.debugStartGrowth(_options!, _selected!);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _failedStart = true;
          _error = '開始結果を確認してください。開始要求は再送していません。この画面を閉じ、現在の育成を確認してください。';
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const stageNames = {
      'egg': '卵',
      'child': '幼少期',
      'training': '育成期',
      'growth': '成長期',
      'first_team': '一軍'
    };
    return PopScope(
      canPop: !_starting,
      child: AlertDialog(
        title: Text(_confirming ? '成長期から開始しますか？' : '分岐を選んで成長期から開始'),
        content: SingleChildScrollView(
          child: _loading
              ? const SizedBox(
                  height: 72, child: Center(child: CircularProgressIndicator()))
              : _error != null
                  ? Text(_error!)
                  : _confirming
                      ? Text(
                          '対象：現在の育成（${stageNames[_options!.currentGame['stage_code']] ?? '育成中'}）\n'
                          '開始先：成長期／${_options!.branches[_selected]}\n\n'
                          '現在の育成・数値・経過時間を置き換え、新しい育成を始めます。\n'
                          'これまでの履歴・図鑑・ポイントは削除も付与もしません。当日の仕事制限は引き継ぎます。\n'
                          '開始後の分岐・ポジションは通常のサーバー判定です。テスト用の育成であることを確認してください。')
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('開始時の大別を選んでください。ポジションの確定や図鑑への登録は行いません。'),
                          for (final entry in _options!.branches.entries)
                            ListTile(
                              title: Text(entry.value),
                              leading: Icon(_selected == entry.key
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off),
                              selected: _selected == entry.key,
                              onTap: () =>
                                  setState(() => _selected = entry.key),
                            ),
                        ]),
        ),
        actions: [
          TextButton(
              onPressed: _starting ? null : () => Navigator.pop(context, false),
              child: Text(_failedStart ? '閉じる' : 'キャンセル')),
          if (!_loading && _error != null && !_failedStart)
            TextButton(onPressed: _load, child: const Text('一覧を再取得')),
          if (!_loading && _error == null)
            FilledButton(
              onPressed: _selected == null || _starting
                  ? null
                  : _confirming
                      ? _start
                      : () => setState(() => _confirming = true),
              child: Text(_starting
                  ? '開始を確認中…'
                  : _confirming
                      ? '成長期から開始する'
                      : '確認へ'),
            ),
        ],
      ),
    );
  }
}
