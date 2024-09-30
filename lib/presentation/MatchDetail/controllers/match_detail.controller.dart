import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/media/media_provider.dart';

class MatchDetailController extends GetxController {
  var selectedIndex = 0.obs; // Observable to track the selected tab index
  final MediaProvider mediaProvider = MediaProvider();

  @override
  void onInit() {
    super.onInit();

    mediaProvider.onInit();
  }

  void changeTab(int index) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Add delay of 200ms
    selectedIndex.value = index; // Update selected tab index after the delay
  }

  void onPageChanged(int index) {
    selectedIndex.value = index;
  }

  Future<String> getImage(String mediaId) async {
    final imageData = await mediaProvider.fetchMedia(mediaId);
    final image = imageData.media_details.sizes.thumbnail.source_url;
    return image;
  }
}
