import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';

import 'generated/locales.g.dart';
import 'infrastructure/navigation/navigation.dart';
import 'infrastructure/navigation/routes.dart';

void main() async {
  var initialRoute = await Routes.initialRoute;
  runApp(Main(initialRoute));
}

class Main extends StatelessWidget {
  final String initialRoute;
  Main(this.initialRoute);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: false,
      child: GetMaterialApp(
        translations:TranslationService(),  // Your translation class
        locale: const Locale('ja', 'JP'),
        fallbackLocale: const Locale('ja', 'JP'), // Fallback locale// Initial locale
        initialRoute: initialRoute,
        getPages: Nav.routes,
      ),
    );
  }
}

class TranslationService extends Translations {
  @override
  Map<String, Map<String, String>> get keys => AppTranslation.translations;
}