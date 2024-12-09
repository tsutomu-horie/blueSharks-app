import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:koto_blue_sharks/app/data/api/auth/AuthToken.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';
import 'package:koto_blue_sharks/app/data/models/match/match_result.dart';
import 'package:koto_blue_sharks/app/data/models/member/member.dart';
import 'package:koto_blue_sharks/app/services/AnalyticsService.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/screens.dart';
import 'package:koto_blue_sharks/utils/my_shared_pref.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  RxString version = "".obs;
  RxString isFirstOpen = "".obs;

  final MemberProvider memberProvider = MemberProvider();
  final RxList<Category> allCategories = <Category>[].obs;
  final RxMap<int, List<Member>> categoryPlayers = <int, List<Member>>{}.obs;
  final RxBool isLoading = false.obs;

  Box<Category>? categoryBox;
  Box<Member>? playerBox;

  @override
  void onInit() async {
    super.onInit();
    getAppVersion();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String bundleID = packageInfo.packageName;
    print("Bundle ID: $bundleID");

    AnalyticsService.logPageView(Routes.SPLASH);

    final isOpen = MySharedPref.getFirstOpen();
    isFirstOpen.value = "${MySharedPref.getFirstOpen()}";

    await Future.delayed(const Duration(seconds: 2));

    if (isOpen != null && isOpen != "") {
      Get.offAll(() => const MainScreen());
    } else {
      Get.offAndToNamed('/wallpaper');
    }
  }

  void getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version.value = packageInfo.version;
  }
}
