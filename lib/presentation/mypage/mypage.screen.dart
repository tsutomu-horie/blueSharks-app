import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/mypage.controller.dart';

class MypageScreen extends GetView<MypageController> {
  const MypageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final MypageController controller = Get.put(MypageController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MypageScreen'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(onPressed: (){
          controller.logout();
        }, child: Text("Logout"))
      ),
    );
  }
}
