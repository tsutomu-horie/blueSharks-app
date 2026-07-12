import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'controllers/test.controller.dart';

class TestScreen extends GetView<TestController> {
  const TestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TestScreen'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'TestScreen is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
