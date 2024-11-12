import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/views/views/member/views/memberlist_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/match+extensions.dart';

import 'controllers/member.controller.dart';

class MemberScreen extends GetView<MemberController> {
  const MemberScreen(this.onSet, {super.key});
  final Function(String, String)? onSet;

  @override
  Widget build(BuildContext context) {
    final MemberController memberController = Get.put(MemberController());
    final ScrollController scrollController = ScrollController();

    return Scaffold(
      backgroundColor: BackgroundColor.primary,
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            Container(
              color: const Color(0xfffafafa),
              child: DefaultHeaderTitleView(
                LocaleKeys.member.tr,
                LocaleKeys.member_en.tr.toUpperCase(),
              ),
            ),
            Container(
              height: 1.h,
              color: BorderColor.primary,
            ),
            MemberListView(
              memberController,
              isSetWallpaper: false,
              onSet: onSet,
              scrollController: scrollController, // Pass the scroll controller
            ),
          ],
        ),
      ),
    );
  }
}
