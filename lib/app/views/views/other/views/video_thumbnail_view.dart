import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_video.dart';
import 'package:koto_blue_sharks/presentation/home/widgets/renewal_home_design.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoThumbnailView extends StatefulWidget {
  const VideoThumbnailView({super.key, this.videos = const []});
  final List<WebsiteVideo> videos;

  @override
  State<VideoThumbnailView> createState() => _VideoThumbnailViewState();
}

class _VideoThumbnailViewState extends State<VideoThumbnailView> {
  final _pages = PageController(viewportFraction: .86);
  int _current = 0;

  @override
  void didUpdateWidget(covariant VideoThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videos.map((v) => v.url).join(',') !=
        widget.videos.map((v) => v.url).join(',')) {
      _current = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      LayoutBuilder(
          builder: (context, constraints) => SizedBox(
              height: constraints.maxWidth * .86 * 9 / 16,
              child: PageView.builder(
                key:
                    ValueKey(widget.videos.map((video) => video.url).join(',')),
                controller: _pages,
                itemCount: widget.videos.length,
                onPageChanged: (index) => setState(() => _current = index),
                itemBuilder: (context, index) => Semantics(
                  label:
                      '動画 ${index + 1}/${widget.videos.length}: ${widget.videos[index].title}',
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _card(widget.videos[index])),
                ),
              ))),
      RenewalPageDots(count: widget.videos.length, current: _current),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RenewalViewAllButton(
              onPressed: () =>
                  _open(Uri.parse('https://www.youtube.com/@KotoBlueSharks')))),
    ]);
  }

  Widget _card(WebsiteVideo video) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xffcccccc))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(video.url),
        child:
            Stack(alignment: Alignment.center, fit: StackFit.expand, children: [
          Image.network(video.thumbnailUrl.toString(),
              fit: BoxFit.contain,
              semanticLabel: video.title,
              errorBuilder: (_, __, ___) => const SizedBox.expand()),
          Center(
              child: SvgPicture.asset('assets/vectors/ic_youtube.svg',
                  width: 44, height: 44)),
        ]),
      ));

  Future<void> _open(Uri url) async {
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A failed handoff can be retried.
    }
    _failed();
  }

  void _failed() {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('動画を開けませんでした。')));
    }
  }
}
