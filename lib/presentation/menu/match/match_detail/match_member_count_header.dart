import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class MatchMemberCountHeader extends StatelessWidget {
  const MatchMemberCountHeader({
    super.key,
    required this.label,
    this.count,
  });

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 16.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: BrandColor.main,
          ),
          child: CustomTextView(
            count == null ? label : '$label $count',
            style: TextStyle(
              fontSize: 14.sp,
              color: TextColor.inverse,
            ),
          ),
        ),
        SizedBox(width: 16.w),
      ],
    );
  }
}
