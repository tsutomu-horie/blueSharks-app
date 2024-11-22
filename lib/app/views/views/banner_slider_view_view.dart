
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class BannerSliderView extends StatefulWidget {
  final List<CustomBanner> banners;

  const BannerSliderView({
    super.key,
    required this.banners,
  });

  @override
  State<BannerSliderView> createState() => _BannerSliderViewState();
}

class _BannerSliderViewState extends State<BannerSliderView> {
  final PageController _pageController = PageController(
    viewportFraction: 0.8, // This will show part of prev/next images
    initialPage: 0,
  );
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll();
    });
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (_currentPage < widget.banners.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _autoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 160.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  width: 300.w,
                  height: 160.h,
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CustomImageView(
                      image: widget.banners[index].photo ?? "",
                      radius: 0,
                      customFit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),  // Space between banner and indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
                (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? BrandColor.main
                    :  RGBA.rgba(217, 217, 217, 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}