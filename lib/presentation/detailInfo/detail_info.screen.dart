import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/detail_info.controller.dart';

class DetailInfoScreen extends GetView<DetailInfoController> {
  const DetailInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DetailInfoScreen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'DetailInfoScreen is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
