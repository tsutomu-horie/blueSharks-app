import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_player.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
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
      const DefaultHeaderTitleView('選手情報', 'TOP PLAYERS'),
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * .55).clamp(170.0, 260.0);
        final scaler = MediaQuery.textScalerOf(context);
        final textHeight = 32 + scaler.scale(12) * 2.6 + scaler.scale(16) * 2.6;
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
                          color: Colors.white,
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
                                    const SizedBox(height: 8),
                                    Text(player.kana,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12, height: 1.3)),
                                    const SizedBox(height: 4),
                                    Text(player.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.3,
                                            fontWeight: FontWeight.bold)),
                                  ]))));
                }));
      }),
      if (content.viewAllUrl != null)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
                key: const ValueKey('website-players-view-all'),
                onPressed: () => _open(context, content.viewAllUrl!),
                child: const Text('VIEW ALL'))),
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
