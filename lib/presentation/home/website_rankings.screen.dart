import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';

const _ink = RenewalHomeDesign.navy;
const _muted = Color(0xff64748b);
const _background = Color(0xfff2f5f9);
const _basicStats = ['試合数', '勝', '分', '負'];

class WebsiteRankingsScreen extends StatefulWidget {
  const WebsiteRankingsScreen(
      {super.key, required this.url, this.expectedSeasonTitle, this.loadTable});
  final Uri url;
  final String? expectedSeasonTitle;
  final Future<WebsiteRankingsTable> Function(Uri)? loadTable;

  @override
  State<WebsiteRankingsScreen> createState() => _WebsiteRankingsScreenState();
}

class _WebsiteRankingsScreenState extends State<WebsiteRankingsScreen> {
  WebsiteVideoProvider? _provider;
  late Future<WebsiteRankingsTable> _table;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadTable == null) _provider = WebsiteVideoProvider();
    _table = _load();
  }

  Future<WebsiteRankingsTable> _load() async {
    final table =
        await (widget.loadTable ?? _provider!.fetchRankings)(widget.url);
    final expected =
        WebsiteStandings.seasonKey(widget.expectedSeasonTitle ?? '');
    if (expected != null &&
        WebsiteStandings.seasonKey(table.title) != expected) {
      throw const FormatException('TOP and rankings seasons differ.');
    }
    return table;
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() {
      _table = next;
    });
    // FutureBuilder presents the error; complete pull-to-refresh on failure too.
    try {
      await next;
    } catch (_) {}
  }

  @override
  void dispose() {
    _provider?.httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
          title: const Text('順位表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          centerTitle: true,
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
                tooltip: '更新',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded))
          ]),
      body: SafeArea(
          top: false,
          child: FutureBuilder<WebsiteRankingsTable>(
              future: _table,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(color: _ink));
                }
                final data = snapshot.data;
                if (snapshot.hasError || data == null) {
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 40, color: _muted),
                            const SizedBox(height: 16),
                            const Text('順位表を取得できませんでした。',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _ink)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                                onPressed: _reload, child: const Text('再試行'))
                          ])));
                }
                return RefreshIndicator(
                    onRefresh: _reload,
                    color: _ink,
                    child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CompetitionHeader(title: data.title),
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 20, 16, 12),
                                  child: Row(children: [
                                    const Expanded(
                                        child: Text('リーグ順位',
                                            style: TextStyle(
                                                color: _ink,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700))),
                                    Text('全${data.rows.length}チーム',
                                        style: const TextStyle(
                                            color: _muted, fontSize: 12))
                                  ])),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(children: [
                                    for (final details in [false, true])
                                      Expanded(
                                          child: Padding(
                                              padding: EdgeInsets.only(
                                                  right: details ? 0 : 8),
                                              child: _ViewButton(
                                                  label:
                                                      details ? '詳細成績' : '基本成績',
                                                  selected:
                                                      _showDetails == details,
                                                  onPressed: () => setState(
                                                      () => _showDetails =
                                                          details))))
                                  ])),
                              const SizedBox(height: 12),
                              for (var i = 0; i < data.rows.length; i++)
                                _TeamStandingCard(
                                    key: ValueKey('website-ranking-team-$i'),
                                    table: data,
                                    rowIndex: i,
                                    showDetails: _showDetails),
                              Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                  child: Text(
                                      '${_showDetails ? 'T：トライ　G：ゴール\nPG：ペナルティゴール　DG：ドロップゴール\n\n' : ''}情報提供：清水建設江東ブルーシャークス公式サイト',
                                      style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                          height: 1.7)))
                            ])));
              })));
}

class _CompetitionHeader extends StatelessWidget {
  const _CompetitionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
          color: _ink,
          border: Border(
              bottom: BorderSide(color: RenewalHomeDesign.cyan, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('STANDINGS',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(title.replaceFirst(RegExp(r'\s+(?=20[0-9]{2}\s*[-–])'), '\n'),
            style: const TextStyle(
                color: Color(0xffdbe9fa),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.6))
      ]));
}

class _ViewButton extends StatelessWidget {
  const _ViewButton(
      {required this.label, required this.selected, required this.onPressed});
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
      selected: selected,
      child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
              backgroundColor: selected ? _ink : Colors.white,
              foregroundColor: selected ? Colors.white : _muted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700))));
}

class _TeamStandingCard extends StatelessWidget {
  const _TeamStandingCard(
      {super.key,
      required this.table,
      required this.rowIndex,
      required this.showDetails});
  final WebsiteRankingsTable table;
  final int rowIndex;
  final bool showDetails;

  String? _value(String header) {
    final index = table.headers.indexOf(header);
    return index < 0 ? null : table.rows[rowIndex][index];
  }

  @override
  Widget build(BuildContext context) {
    final team = _value('チーム') ?? '';
    final isSharks = team == '清水建設江東ブルーシャークス';
    final logo = rowIndex < table.teamLogoUrls.length
        ? table.teamLogoUrls[rowIndex]
        : null;
    final points = _value('勝点');
    final stats = table.headers
        .where((header) => showDetails
            ? !['順位', 'チーム', '勝点'].contains(header)
            : _basicStats.contains(header))
        .toList();
    return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isSharks ? const Color(0xffedf7ff) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    isSharks ? RenewalHomeDesign.cyan : const Color(0xffe2e8f0),
                width: isSharks ? 1.5 : 1)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            SizedBox(
                width: 26,
                child: Semantics(
                    label: '順位 ${_value('順位') ?? '-'}',
                    excludeSemantics: true,
                    child: Text(_value('順位') ?? '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _muted,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)))),
            const SizedBox(width: 8),
            ExcludeSemantics(
                child: SizedBox(
                    width: 38,
                    height: 38,
                    child: logo == null
                        ? const _LogoPlaceholder()
                        : Image.network(logo.toString(),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const _LogoPlaceholder()))),
            const SizedBox(width: 10),
            Expanded(
                child: Text(team,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.5))),
            if (points != null) ...[
              const SizedBox(width: 10),
              Column(children: [
                const Text('勝点', style: TextStyle(color: _muted, fontSize: 10)),
                Text(points,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2))
              ])
            ]
          ]),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xffe2e8f0)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, constraints) {
              // Reflow at larger accessibility text sizes instead of clipping.
              final minWidth = MediaQuery.textScalerOf(context).scale(68);
              final columns =
                  (constraints.maxWidth / minWidth).floor().clamp(1, 4);
              return Wrap(runSpacing: 10, children: [
                for (final stat in stats)
                  SizedBox(
                      width: constraints.maxWidth / columns,
                      child: Semantics(
                          label: '$stat ${_value(stat)}',
                          excludeSemantics: true,
                          child: Column(children: [
                            Text(stat,
                                style: const TextStyle(
                                    color: _muted, fontSize: 10)),
                            Text(_value(stat)!,
                                style: const TextStyle(
                                    color: _ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700))
                          ])))
              ]);
            })
          ]
        ]));
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
      decoration: BoxDecoration(color: _background, shape: BoxShape.circle),
      child: Icon(Icons.shield_outlined, color: _muted, size: 24));
}
