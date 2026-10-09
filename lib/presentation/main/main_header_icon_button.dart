import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';

class MainHeaderIconButton extends StatelessWidget {
  const MainHeaderIconButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    super.key,
  });

  final Widget icon;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40.w, 48.h),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          icon,
          CustomTextView(
            text,
            style: TextStyle(fontSize: 10.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
