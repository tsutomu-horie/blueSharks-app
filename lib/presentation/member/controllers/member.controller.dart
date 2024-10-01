import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/data/api/member/member_provider.dart';

class MemberController extends GetxController {
  final selectedPosition = "All Position".obs;
  final MemberProvider memberProvider = MemberProvider();


  @override
  void onInit() {
    super.onInit();
    memberProvider.onInit();

  }
}
