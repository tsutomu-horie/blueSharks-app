import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/app/providers/home/website_video_provider.dart';

class WebsiteStandingsSection extends StatelessWidget {
  const WebsiteStandingsSection(
      {super.key, required this.standings, this.loadRankings});
  final WebsiteStandings? standings;
  final Future<WebsiteRankingsTable> Function(Uri)? loadRankings;

  @override
  Widget build(BuildContext context) {
    final data = standings;
    if (data == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(data.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  columns: data.headers
                      .map((text) => DataColumn(label: Text(text)))
                      .toList(),
                  rows: [
                    DataRow(
                        cells: data.values
                            .map((text) => DataCell(Text(text)))
                            .toList())
                  ])),
          SizedBox(
              width: double.infinity,
              child: TextButton(
                  key: const ValueKey('website-rank-link'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => WebsiteRankingsScreen(
                              url: data.rankingsUrl,
                              expectedSeasonTitle: data.title,
                              loadTable: loadRankings))),
                  child: data.bannerImageUrl == null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(data.bannerLabel))
                      : AspectRatio(
                          aspectRatio: data.bannerAspectRatio ?? 585 / 200,
                          child: Image.network(data.bannerImageUrl.toString(),
                              fit: BoxFit.contain,
                              semanticLabel: data.bannerLabel,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Text(data.bannerLabel,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)))))),
        ]));
  }
}

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

  void _reload() {
    final next = _load();
    setState(() {
      _table = next;
    });
  }

  @override
  void dispose() {
    _provider?.httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('順位表'), actions: [
        IconButton(
            tooltip: '更新', onPressed: _reload, icon: const Icon(Icons.refresh))
      ]),
      body: FutureBuilder<WebsiteRankingsTable>(
          future: _table,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (snapshot.hasError || data == null) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('順位表を取得できませんでした。'),
                TextButton(onPressed: _reload, child: const Text('再試行'))
              ]));
            }
            return SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(data.title,
                          style: const TextStyle(fontSize: 18))),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                          headingRowHeight: 64,
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 96,
                          columns: data.headers
                              .map((text) => DataColumn(label: Text(text)))
                              .toList(),
                          rows: data.rows
                              .map((row) => DataRow(
                                  cells: row
                                      .map((text) => DataCell(Text(text)))
                                      .toList()))
                              .toList()))
                ]));
          }));
}
