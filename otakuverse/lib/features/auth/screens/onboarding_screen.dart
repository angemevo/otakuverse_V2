import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/features/auth/screens/onboarding/step1_basic_info.dart';
import 'package:otakuverse/features/auth/screens/onboarding/step2_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Obx(() => _buildProgressBar(controller.currentStep.value)),
        actions: [
          // Bouton "Passer" — toujours disponible
          TextButton(
            onPressed: () => Get.offAllNamed('/home'),
            child: Text(
              'Passer',
              style: GoogleFonts.inter(
                color: AppColors.mediumGray,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: controller.currentStep.value == 0
              ? const Step1BasicInfo()
              : const Step2Preferences(),
        );
      }),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(2, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: index <= step
                  ? AppColors.crimsonRed
                  : AppColors.mediumGray.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}