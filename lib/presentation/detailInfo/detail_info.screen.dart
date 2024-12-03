import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/default_header_title_view.dart';
import 'package:koto_blue_sharks/app/views/views/html_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:koto_blue_sharks/utils/map_id_to_categories.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controllers/detail_info.controller.dart';

class DetailInfoScreen extends GetView<DetailInfoController> {
  const DetailInfoScreen(this.onOpenDetail, this.selectedPost, {super.key});

  final Function() onOpenDetail;
  final Post? selectedPost;

  @override
  Widget build(BuildContext context) {
    final DetailInfoController controller = Get.put(DetailInfoController());

    if (selectedPost != null) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildDivider(),
              _buildContent(),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: DefaultHeaderTitleView(
        LocaleKeys.topics.tr,
        LocaleKeys.topics_en.tr.toUpperCase(),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: BorderColor.primary,
    );
  }

  Widget _buildContent() {
    final categoryData = mapCategoryIdsToNames(selectedPost!.categories);

    return Container(
      color: BackgroundColor.primary,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Column(
        children: [
          _buildDate(),
          SizedBox(height: 8.h),
          _buildCategories(categoryData),
          SizedBox(height: 8.h),
          _buildTitle(),
          SizedBox(height: 24.h),
          _buildHtmlContent(),
          SizedBox(height: 24.h),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildDate() {
    return FutureBuilder<String>(
      future: convertToJapaneseFormat(selectedPost!.date),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
          return const SizedBox();
        } else {
          return Row(
            children: [
              CustomTextView(snapshot.data!),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategories(List<String> categoryData) {
    return Row(
      children: categoryData.map((element) {
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: BrandColor.background,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: CustomTextView(
              element,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitle() {
    return CustomTextView(
      selectedPost!.title.rendered,
      type: TDSFontType.titleMedium,
      color: TextColor.primary,
    );
  }

  Widget _buildHtmlContent() {
    return HtmlWidget(
      onTapUrl: (url) async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch $url');
        }
        return true;
      },
      selectedPost!.content.rendered,
      customStylesBuilder: (element) {
        if (element.localName == 'figure' || element.localName == 'div') {
          return {
            'margin': '0',
            'padding': '0',
          };
        }
        return null;
      },
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: ButtonStyle(
          side: WidgetStateProperty.all(BorderSide(color: BrandColor.main)),
        ),
        onPressed: onOpenDetail,
        child: CustomTextView(
          LocaleKeys.back_to_list.tr,
          type: TDSFontType.titleSmall,
          color: BrandColor.main,
        ),
      ),
    );
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: BorderColor.disabled,
      highlightColor: BorderColor.subtle,
      child: Container(
        width: 320.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: BorderColor.disabled,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
      ),
    );
  }
}
