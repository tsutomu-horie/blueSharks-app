import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/mypage.controller.dart';

class MypageScreen extends GetView<MypageController> {
  const MypageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MypageScreen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'MypageScreen is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
