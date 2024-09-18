import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:get/get.dart';

class HtmlTextView extends GetView {
  const HtmlTextView(this.htmlContent, {super.key, required this.style});

  final String htmlContent;
  final Style style;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: htmlContent,
      style: {
        // Customize your HTML styles here if needed
        "html": style, // Adjust font size
      },
    );
  }
}
