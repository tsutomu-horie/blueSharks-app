import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/auth/auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MemberCardView extends GetView {
  const MemberCardView(this.memberType, this.memberId,
      {this.qualification, super.key});

  final String memberType;
  final String memberId;
  final MemberQualification? qualification;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              SvgPicture.asset(
                "assets/vectors/member_card/${getIconName(memberType)}.svg",
                width: 343.w,
                height: 218.h,
              ),
              Positioned(
                bottom: 63.h,
                left: 15.w,
                child: Text(
                  "No. $memberId",
                  style:
                      TextStyle(fontWeight: FontWeight.w400, fontSize: 16.sp),
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
          if (qualification != null)
            MemberQualificationSummary(qualification: qualification!),
        ],
      ),
    );
  }

  String getIconName(String playerMember) {
    switch (playerMember) {
      case "ビギナー":
        return "beginner";
      case "ワンシミズ":
        return "one_shimz";
      case "ジュニア":
        return "junior";
      case "江東区民":
        return "koto";
      case "レギュラー":
        return "regular";
      case "プレミア":
        return "premium";
      case "激推し":
        return "geki_oshi";
      case "メルマガ":
        return "free";
    }
    return "beginner";
  }
}

class MemberQualificationSummary extends StatelessWidget {
  const MemberQualificationSummary({required this.qualification, super.key});

  final MemberQualification qualification;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343.w,
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('資格状態：${_statusLabel(qualification.status)}'),
          SizedBox(height: 4.h),
          Text(
            '開始日：${_dateLabel(qualification.validFrom)} / '
            '有効期限：${_dateLabel(qualification.validTo)}',
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'active' => '有効',
        'pending' => '開始前',
        'expired' => '期限切れ',
        'inactive' => '資格なし',
        _ => '未確認',
      };

  String _dateLabel(String? value) {
    if (value == null || value.isEmpty) return '未登録';
    final date = DateTime.tryParse(value);
    if (date == null) return '未登録';
    return DateFormat('yyyy/MM/dd').format(date);
  }
}
