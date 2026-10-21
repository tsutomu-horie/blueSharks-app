import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';
import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_standings.dart';
import 'package:koto_blue_sharks/presentation/home/website_rankings.screen.dart';

export 'package:koto_blue_sharks/presentation/home/website_rankings.screen.dart';

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
          Align(
              alignment: Alignment.centerLeft,
              child: Text(data.title,
                  style: const TextStyle(
                      color: RenewalHomeDesign.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900))),
          const SizedBox(height: 12),
          Table(
              border: TableBorder.all(color: const Color(0xffcccccc)),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                    decoration:
                        const BoxDecoration(color: RenewalHomeDesign.navy),
                    children: [
                      for (final header in data.headers)
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 4),
                            child: Text(header,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700))),
                    ]),
                TableRow(children: [
                  for (final value in data.values)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 4),
                        child: Text(value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 26,
                                fontWeight: FontWeight.w900))),
                ]),
              ]),
          const SizedBox(height: 20),
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
