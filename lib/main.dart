import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/media/media.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';

import 'generated/locales.g.dart';
import 'infrastructure/navigation/navigation.dart';
import 'infrastructure/navigation/routes.dart';

void main() async {
  var initialRoute = await Routes.initialRoute;

  // Initialize Hive
  await Hive.initFlutter();

  // Register the Category adapter
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(MemberAdapter());
  Hive.registerAdapter(CombineMemberAdapter());
  Hive.registerAdapter(TitleAdapter());
  Hive.registerAdapter(CustomFieldAdapter());

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