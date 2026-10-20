import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/utils/map_id_to_categories.dart';
import 'renewal_home_design.dart';

class RenewalFeaturedTopics extends StatefulWidget {
  const RenewalFeaturedTopics(
      {super.key,
      required this.posts,
      required this.loadImage,
      required this.onOpen});
  final List<Post> posts;
  final Future<String> Function(Post) loadImage;
  final ValueChanged<Post> onOpen;

  @override
  State<RenewalFeaturedTopics> createState() => _RenewalFeaturedTopicsState();
}

class _RenewalFeaturedTopicsState extends State<RenewalFeaturedTopics> {
  final _pages = PageController(viewportFraction: .86);
  final _images = <String, Future<String>>{};
  int _current = 0;

  @override
  void didUpdateWidget(covariant RenewalFeaturedTopics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts.map((p) => p.id).join(',') !=
        widget.posts.map((p) => p.id).join(',')) {
      _images.clear();
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
    if (widget.posts.isEmpty) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    return Column(children: [
      LayoutBuilder(
          builder: (context, constraints) => SizedBox(
              height: constraints.maxWidth * .86 * 9 / 16 +
                  56 +
                  scaler.scale(12) * 2.6 +
                  scaler.scale(16) * 3.9,
              child: PageView.builder(
                  key: const ValueKey('renewal-featured-topics'),
                  controller: _pages,
                  itemCount: widget.posts.length,
                  onPageChanged: (index) => setState(() => _current = index),
                  itemBuilder: (context, index) {
                    final post = widget.posts[index];
                    final categories = mapCategoryIdsToNames(post.categories);
                    final image = _images.putIfAbsent(
                        '${post.id}-${post.featured_media}-${post.content.rendered.hashCode}',
                        () => widget.loadImage(post).then((value) {
                              if (value.isEmpty) {
                                _images.remove(
                                    '${post.id}-${post.featured_media}-${post.content.rendered.hashCode}');
                              }
                              return value;
                            }, onError: (Object error, StackTrace stack) {
                              _images.remove(
                                  '${post.id}-${post.featured_media}-${post.content.rendered.hashCode}');
                              Error.throwWithStackTrace(error, stack);
                            }));
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    const BorderSide(color: Color(0xffcccccc))),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                                key: ValueKey(
                                    'renewal-featured-topic-${post.id}'),
                                onTap: () => widget.onOpen(post),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: FutureBuilder<String>(
                                              future: image,
                                              builder: (context, snapshot) => snapshot
                                                          .hasData &&
                                                      snapshot.data!.isNotEmpty
                                                  ? Image.network(snapshot.data!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __,
                                                              ___) =>
                                                          const Icon(Icons
                                                              .image_outlined))
                                                  : const ColoredBox(
                                                      color:
                                                          Color(0xfff2f2f2)))),
                                      Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (categories.isNotEmpty)
                                                  Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 5),
                                                      decoration: BoxDecoration(
                                                          color:
                                                              RenewalHomeDesign
                                                                  .cyan,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5)),
                                                      child: Text(
                                                          categories
                                                              .join(' / '),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              height: 1.3,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                                const SizedBox(height: 10),
                                                Text(
                                                    html
                                                            .parse(post
                                                                .title.rendered)
                                                            .documentElement
                                                            ?.text ??
                                                        '',
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                        height: 1.3,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ])),
                                    ]))));
                  }))),
      RenewalPageDots(count: widget.posts.length, current: _current),
    ]);
  }
}
