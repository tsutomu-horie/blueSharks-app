import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/presentation/menu/match/match_detail/match_member_count_header.dart';

class MatchRosterImage extends StatelessWidget {
  const MatchRosterImage({
    super.key,
    required this.label,
    required this.image,
  });

  final String label;
  final String image;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          MatchMemberCountHeader(label: label),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              child: CustomImageView(
                image: image,
                radius: 8.r,
                customFit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
}
