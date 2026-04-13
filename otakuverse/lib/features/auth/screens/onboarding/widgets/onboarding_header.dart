import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/main.dart';

class OnboardingHeader extends StatelessWidget {
  final OnboardingController ctrl;
  const OnboardingHeader({super.key, required this.ctrl});

  static const _titles = [
    'Tes genres favoris',
    'Tes animes favoris',
    'C\'est parti !',
  ];

  static const _subtitles = [
    'Choisis au moins 3 genres pour personnaliser ton feed',
    'Sélectionne les animes qui te définissent',
    'Ton profil est prêt',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Logo + Skip ───────────────────────────────────────────
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OTAKUVERSE',
                style: AppTextStyles.appBarTitle,
              ),
              if (ctrl.currentStep.value < 2)
                TextButton(
                  onPressed: () =>
                      Get.offAllNamed(Routes.home),
                  style: TextButton.styleFrom(
                    padding:       EdgeInsets.zero,
                    minimumSize:   Size.zero,
                    tapTargetSize: MaterialTapTargetSize
                        .shrinkWrap,
                  ),
                  child: Text(
                    'Passer',
                    style: AppTextStyles.bodySmall
                        .copyWith(
                            color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ─ Barres de progression ─────────────────────────────────
          Row(
            children: List.generate(
              OnboardingController.totalSteps,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(
                      right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= ctrl.currentStep.value
                        ? AppColors.primary
                        : AppColors.bgElevated,
                    borderRadius:
                        BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─ Titre + Sous-titre ────────────────────────────────────
          Text(
            _titles[ctrl.currentStep.value],
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 4),
          Text(
            _subtitles[ctrl.currentStep.value],
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}