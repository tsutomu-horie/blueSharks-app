import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:koto_blue_sharks/app/views/views/custom_text_view.dart';
import 'package:koto_blue_sharks/generated/locales.g.dart';
import 'package:koto_blue_sharks/presentation/FanClubConfirmation/fan_club_confirmation.screen.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';
import 'package:koto_blue_sharks/utils/utils.dart';
import 'controllers/register_member_fanclub.controller.dart';

class RegisterMemberFanclubScreen
    extends GetView<RegisterMemberFanclubController> {
  const RegisterMemberFanclubScreen({
    super.key,
    required this.email,
    required this.otpId,
    required this.selectedPlayer,
    required this.selectedPlayerName,
  });

  final String email;
  final String otpId;
  final String selectedPlayer;
  final String selectedPlayerName;

  @override
  Widget build(BuildContext context) {
    final globalKey = GlobalKey<FormState>();
    final registerController = Get.put(RegisterMemberFanclubController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleSection(),
                _buildForm(globalKey, registerController),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          _buildBottomBar(globalKey, context, registerController),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: SvgPicture.asset(
        "assets/vectors/app_logo.svg",
        width: 56.w,
        height: 56.h,
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: IconColor.primary,
        ),
        onPressed: () {
          Get.back();
        },
      ),
      actions: [
        Row(
          children: [
            CustomTextView(
              "${LocaleKeys.step.tr} : ",
              type: TDSFontType.bodyTextMedium,
              color: TextColor.secondary,
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: BrandColor.surface,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: CustomTextView(
                "2/3",
                type: TDSFontType.labelLarge,
                color: BrandColor.main,
              ),
            ),
            SizedBox(width: 16.w),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextView(
          LocaleKeys.register_email_title.tr,
          type: TDSFontType.headlineSmall,
          color: BrandColor.main,
        ),
        SizedBox(height: 8.h),
        CustomTextView(
          LocaleKeys.register_email_desc.tr,
          type: TDSFontType.bodyTextMedium,
          color: TextColor.secondary,
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: BorderColor.primary, width: 1.w),
          ),
          child: CustomTextView(
            LocaleKeys.registered_email.trParams({"email": email}),
            type: TDSFontType.bodyTextSmall,
            color: TextColor.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(GlobalKey<FormState> globalKey,
      RegisterMemberFanclubController controller) {
    return Form(
      key: globalKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: LocaleKeys.fanclub_member_id.tr,
            isRequired: true,
            controller: controller.idTextFieldController,
            hintText: 'ID cannot be empty',
          ),
          SizedBox(height: 24.h),
          _buildPasswordField(controller),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomTextView(label,
                type: TDSFontType.bodyTextSmall, color: TextColor.secondary),
            if (isRequired)
              CustomTextView(" *",
                  type: TDSFontType.bodyTextMedium, color: DangerColor.main),
          ],
        ),
        TextFormField(
          controller: controller,
          validator: (value) => value!.isEmpty ? hintText : null,
          decoration: InputDecoration(
            errorMaxLines: 1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: BorderColor.secondary),
            ),
            hintStyle: TextStyle(color: TextColor.placeholder),
            contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
            hintText: hintText,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(RegisterMemberFanclubController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomTextView(LocaleKeys.password.tr,
                type: TDSFontType.labelLarge, color: TextColor.secondary),
            CustomTextView(" *",
                type: TDSFontType.labelLarge, color: TextColor.error),
          ],
        ),
        SizedBox(height: 4.h),
        Obx(
          () => TextFormField(
            obscureText: controller.isPasswordHidden.value,
            validator: (value) {
              if (value!.isEmpty) return 'Password is required';
              if (value.length < 8)
                return 'Password must be at least 8 characters long';
              return null;
            },
            controller: controller.passwordTextFieldController,
            decoration: InputDecoration(
              errorMaxLines: 1,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: BorderColor.secondary),
              ),
              hintStyle: TextStyle(color: TextColor.placeholder),
              contentPadding: EdgeInsets.only(top: 2.h, left: 16.w),
              hintText: LocaleKeys.password_placeholder
                  .trParams({"example": "Your password"}),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordHidden.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: TextColor.placeholder,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ),
        ),
        CustomTextView(LocaleKeys.password_desc.tr,
            type: TDSFontType.bodyTextMedium, color: TextColor.tertiary),
      ],
    );
  }

  Widget _buildBottomBar(GlobalKey<FormState> globalKey, BuildContext context,
      RegisterMemberFanclubController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: BrandColor.main),
          onPressed: () {
            if (globalKey.currentState!.validate()) {
              controller.onRegister(
                otpId,
                email,
                    () => Utils.showError(
                    context,
                    LocaleKeys.membership_dialog_title,
                    LocaleKeys.membership_dialog_message),
                    () {
                  // Navigate to confirmation screen
                  // Get.offAll(() => FanClubConfirmationScreen(email: email, id: "", selectedPlayer: selectedPlayer));
                },
                selectedPlayer,
                selectedPlayerName,
                context
              );
            }
          },
          child: CustomTextView(LocaleKeys.certification.tr,
              color: BrandColor.content),
        ),
      ),
    );
  }
}
