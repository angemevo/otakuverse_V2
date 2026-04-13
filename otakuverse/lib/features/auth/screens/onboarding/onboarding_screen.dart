import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'steps/genre_step.dart';
import 'steps/anime_step.dart';
import 'steps/success_step.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_footer.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OnboardingController>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // ─ Déco ──────────────────────────────────────────────────
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Obx(() => Column(
              children: [
                OnboardingHeader(ctrl: ctrl),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(
                        milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end:   Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                    child: _buildStep(
                        ctrl.currentStep.value, ctrl),
                  ),
                ),

                OnboardingFooter(ctrl: ctrl),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step,
      OnboardingController ctrl) {
    switch (step) {
      case 0:
        return GenreStep(
            key: const ValueKey(0), ctrl: ctrl);
      case 1:
        return AnimeStep(
            key: const ValueKey(1), ctrl: ctrl);
      case 2:
        return SuccessStep(
            key: const ValueKey(2), ctrl: ctrl);
      default:
        return const SizedBox.shrink();
    }
  }
}