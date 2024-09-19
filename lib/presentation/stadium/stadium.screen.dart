import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/stadium.controller.dart';

class StadiumScreen extends GetView<StadiumController> {
  const StadiumScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StadiumScreen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'StadiumScreen is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
