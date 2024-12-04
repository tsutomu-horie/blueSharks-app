import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class CustomImageView extends GetView {
  const CustomImageView({super.key,required this.image,
    this.radius,
    this.customFit});

  final String image;
  final double? radius;
  final BoxFit? customFit;

  @override
  Widget build(BuildContext context) {
    print("load image ${image.toString()}");
    if (image != null && image != "") {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius != null ? radius! : 20.r),
        child: CachedNetworkImage(
          imageUrl:  image,
          fit: customFit ?? BoxFit.cover,
          placeholder: (context, url) =>
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                ),
              ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    } else {
      return SizedBox();
    }
  }
}
