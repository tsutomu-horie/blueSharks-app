import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/info/info_provider.dart';
import 'package:koto_blue_sharks/app/data/models/info/post.dart';
import 'package:koto_blue_sharks/app/services/analytics_service.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/utils/Constant.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuListController extends GetxController {
  PageController pageController = PageController();
  var selectedIndex = 0.obs; // Observable to track the selected tab index

  @override
  void onInit() {
    super.onInit();
    selectedIndex.value = 0;
    AnalyticsService.logPageView(Routes.INFO);

  }
  void changeTab(int index) async {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    await Future.delayed(const Duration(milliseconds: 300)); // Add delay of 200ms
    selectedIndex.value = index; // Update selected tab index after the delay
  }

  // Method to handle swipe between pages
  void onPageChanged(int index) {
    selectedIndex.value = index;
  }

  void launchInstagram() async {
    final Uri instagramUrl = Uri.parse(Constants.instagramUrl); // Replace with your profile URL
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl);
    } else {
      throw 'Could not launch $instagramUrl';
    }
  }

  void launchTwitter() async {
    final Uri instagramUrl = Uri.parse(Constants.xUrl); // Replace with your profile URL
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl);
    } else {
      throw 'Could not launch $instagramUrl';
    }
  }

  void launchPartner() async {
    final Uri instagramUrl = Uri.parse(Constants.partnerUrl); // Replace with your profile URL
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl);
    } else {
      throw 'Could not launch $instagramUrl';
    }
  }

  void launchTeam() async {
    final Uri instagramUrl = Uri.parse(Constants.teamUrl); // Replace with your profile URL
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl);
    } else {
      throw 'Could not launch $instagramUrl';
    }
  }

}
