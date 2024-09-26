import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoThumbnailView extends GetView {
  const VideoThumbnailView({super.key});
  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: () => launchURL(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.w),
        color: Colors.black,
        child: Image.asset("assets/images/video_thumbnail.png"),
      ),
    );
  }

  void launchURL(BuildContext context) async {
    if (await canLaunch(Constants.videoUrl)) {
      await launch(Constants.videoUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $Constants.videoUrl')),
      );
    }
  }
}
