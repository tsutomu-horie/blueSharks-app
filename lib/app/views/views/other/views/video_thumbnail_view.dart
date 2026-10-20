import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:koto_blue_sharks/app/data/models/home/website_video.dart';
import 'package:koto_blue_sharks/utils/constant.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoThumbnailView extends StatelessWidget {
  const VideoThumbnailView({super.key, this.videos = const []});

  final List<WebsiteVideo> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _card(context);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: PageView.builder(
        key: ValueKey(videos.map((video) => video.url).join(',')),
        itemCount: videos.length,
        itemBuilder: (context, index) => Semantics(
          label: '動画 ${index + 1}/${videos.length}: ${videos[index].title}',
          child: _card(context, video: videos[index]),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {WebsiteVideo? video}) {
    return GestureDetector(
      onTap: () => _launchURL(context, video),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.w),
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: video == null
                  ? Image.asset('assets/images/video_thumbnail.png')
                  : Image.network(
                      video.thumbnailUrl.toString(),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      semanticLabel: video.title,
                      errorBuilder: (_, __, ___) => const SizedBox.expand(),
                    ),
            ),
            SvgPicture.asset(
              'assets/vectors/ic_youtube.svg',
              width: 40.w,
              height: 40.h,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, WebsiteVideo? video) async {
    try {
      if (video == null) {
        // Preserve the existing platform behavior for the production/fallback
        // video (including Safari View Controller on iOS).
        // ignore: deprecated_member_use
        if (await canLaunch(Constants.videoUrl)) {
          // ignore: deprecated_member_use
          await launch(Constants.videoUrl);
          return;
        }
      } else if (await launchUrl(video.url,
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Display the same recoverable failure for an unavailable video app.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動画を開けませんでした。')),
      );
    }
  }
}
