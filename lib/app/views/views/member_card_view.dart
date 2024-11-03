import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';

class MemberCardView extends GetView {
  const MemberCardView(this.memberType, {super.key});

  final String memberType;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SvgPicture.asset("assets/vectors/member_card/$memberType.svg")
      ],
    );
  }
}
