import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/info.controller.dart';

class InfoScreen extends GetView<InfoController> {
  const InfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfoScreen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'InfoScreen is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
