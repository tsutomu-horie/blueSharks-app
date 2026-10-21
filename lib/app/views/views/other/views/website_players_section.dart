import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_player.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsitePlayersSection extends StatelessWidget {
  const WebsitePlayersSection({super.key, required this.data});
  final WebsitePlayers? data;

  @override
  Widget build(BuildContext context) {
    final content = data;
    if (content == null || content.players.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const RenewalHomeHeading('メンバー', 'MEMBER'),
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * .55).clamp(170.0, 260.0);
        final scaler = MediaQuery.textScalerOf(context);
        final textHeight = 48 + scaler.scale(12) * 2.6 + scaler.scale(16) * 2.6;
        return SizedBox(
            height: width * 1.5 + textHeight,
            child: ListView.separated(
                key: const ValueKey('website-players-list'),
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: content.players.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final player = content.players[index];
                  return SizedBox(
                      width: width,
                      child: Material(
                          color: RenewalHomeDesign.navy,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                              key: ValueKey('player-${player.url.path}'),
                              onTap: () => _open(context, player.url),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AspectRatio(
                                        aspectRatio: 2 / 3,
                                        child: Image.network(
                                            player.imageUrl.toString(),
                                            fit: BoxFit.cover,
                                            semanticLabel: player.name,
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                                    color: Color(0xfff2f2f2),
                                                    child: Center(
                                                        child: Icon(Icons
                                                            .person_outline))))),
                                    Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(children: [
                                          Text(player.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  height: 1.3,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(player.kana,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  height: 1.3,
                                                  fontWeight: FontWeight.w700)),
                                        ])),
                                  ]))));
                }));
      }),
      if (content.viewAllUrl != null)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RenewalViewAllButton(
                key: const ValueKey('website-players-view-all'),
                onPressed: () => _open(context, content.viewAllUrl!))),
    ]);
  }

  Future<void> _open(BuildContext context, Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep cards and links available so a failed handoff can be retried.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('選手ページを開けませんでした。')));
    }
  }
}
