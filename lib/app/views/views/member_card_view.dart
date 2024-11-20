import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MemberCardView extends GetView {
  const MemberCardView(this.memberType, this.memberId, {super.key});

  final String memberType;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          SvgPicture.asset(
            "assets/vectors/member_card/${getIconName(memberType)}.svg",
            width: 343.w,
            height: 218.h,
          ),
          Positioned(
            bottom: 65.h,
            left: 15.w,
            child: CustomTextView(
              memberId,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          Positioned(
            bottom: 39.h,
            right: 16.w,
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  color: Colors.white,
                ),
                child: Center(
                  child: QrImageView(
                    data: memberId,
                    version: QrVersions.auto,
                    size: 60.w,
                  ),
                )),
          )
        ],
      ),
    );
  }

  String getIconName(String playerMember) {
    switch (playerMember) {
      case "ビギナー" : return "beginner";
      case "ワンシミズ" : return "one_shimz";
      case "ジュニア" : return "junior";
      case "江東区民" : return "koto";
      case "レギュラー" : return "regular";
      case "作成中" : return "premium";
      case "激推し会員" : return "beginner";
    }
    return "";
  }
}
