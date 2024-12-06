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

import 'controllers/gallery_screen_detail.controller.dart';

class GalleryScreenDetailScreen extends GetView<GalleryScreenDetailController> {
  const GalleryScreenDetailScreen(this.albumData, this.name, {super.key});

  final Album? albumData;
  final String name;

  @override
  Widget build(BuildContext context) {
    final GalleryScreenDetailController controller = Get.put(
        GalleryScreenDetailController());

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
                            Get.to(() => FullScreenImageView(imageUrl: albumData!.photo!,));
                          }
                        },
                        child: CustomImageView(
                            customFit: BoxFit.contain,
                            radius: 0.r,
                            image: albumData!.photo ?? ""),
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
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 2.w,
                    crossAxisSpacing: 2.w,
                  ),
                  itemCount: controller.album.length,
                  itemBuilder: (context, playerIndex) {
                    String imageUrl = controller.album[playerIndex].galleries?.photo ?? "";

                    return GestureDetector(
                      onTap: () {
                        Get.to(() => FullScreenImageView(imageUrl: imageUrl,));
                        // // Open the full-screen image on tap
                        // showFullScreenImageWithTransition(
                        //     context,  imageUrl);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomImageView(
                          radius: 0.r,
                          image: imageUrl,
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