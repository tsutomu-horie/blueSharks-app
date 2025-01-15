import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/views/views/custom_image_view.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/app/views/views/full_screen_image_view_view.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/date_formatter.dart';
import 'package:photo_view/photo_view.dart';

import 'controllers/gallery_detail.controller.dart';

class GalleryDetailScreen extends GetView<GalleryDetailController> {
  const GalleryDetailScreen(this.albumData, this.name, {super.key});

  final Album? albumData;
  final String name;

  @override
  Widget build(BuildContext context) {
    final GalleryDetailController controller = Get.put(
        GalleryDetailController());

    controller.getGalleryList(albumData?.id ?? 0);

    return Scaffold(
        appBar: AppBar(
          title: const CustomTextView('Gallery', color: Colors.white,),
          backgroundColor: BrandColor.main,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            // Change this to your desired icon
            onPressed: () {
              Get.back();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child:  GestureDetector(
                        onTap: () {
                          if (albumData!.photo != null) {
                            List<String> galleryImages = controller.album.map((item) =>
                            item.galleries.photo ?? "").toList();

                            Get.to(() => FullScreenImageView(
                              imageUrls: galleryImages,
                              initialIndex: 0,
                            ));
                            // Get.to(() => FullScreenImageView(imageUrl: albumData!.photo!,));
                          }
                        },
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CustomImageView(
                                  customFit: BoxFit.fitWidth,
                                  radius: 0.r,
                                  image: controller.imageCompressor(albumData!.photo ?? "", true)),
                            ),
                            Container(
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent,
                                      ],
                                    ))),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.w,
                      left: 16.w,
                      right: 16.w,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: BrandColor.main,
                                  borderRadius:
                                  BorderRadius.circular(24.r),
                                ),
                                child: CustomTextView(
                                  name,
                                  color: Colors.white,
                                  type: TDSFontType.labelMedium,
                                ),
                              ),
                              SizedBox(width: 8.w,),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(8.r),
                                    color: Colors.white
                                ),
                                width: 4.w,
                                height: 4.w,
                              ),
                              SizedBox(width: 8.w,),
                              FutureBuilder<String>(
                                future: convertToJapaneseFormat(albumData!.date ??
                                    ""),
                                builder: (BuildContext context,
                                    AsyncSnapshot<String> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                      snapshot.hasError) {
                                    return const SizedBox();
                                  } else {
                                    return Row(
                                      children: [
                                        CustomTextView(
                                          snapshot.data!, color: Colors.white,
                                          type: TDSFontType.bodyTextMedium,),
                                      ],
                                    ); // Display the formatted date
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h,),
                          CustomTextView(
                            albumData!.name ?? "", type: TDSFontType.titleLarge,
                            color: Colors.white,)
                        ],
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: 8.h,),

              Obx(() {
                final itemCount = controller.album.length > 1 ? controller.album.length - 1 : 0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    mainAxisSpacing: 2.w,
                    crossAxisSpacing: 2.w,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    String imageUrl =controller.album[index + 1].galleries.photo ?? "";

                    return GestureDetector(
                      onTap: () {
                        List<String> galleryImages = controller.album.map((item) =>
                        item.galleries.photo ?? "").toList();

                        Get.to(() => FullScreenImageView(
                          imageUrls: galleryImages,
                          initialIndex: index + 1,
                        ));

                        // // Open the full-screen image on tap
                        // showFullScreenImageWithTransition(
                        //     context,  imageUrl);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomImageView(
                          radius: 0.r,
                          image: controller.imageCompressor(imageUrl, false),
                        ),
                      ),
                    );
                  },
                );
              })


            ],
          ),
        )
    );
  }
}