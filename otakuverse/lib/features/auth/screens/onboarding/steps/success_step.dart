import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';
import 'package:otakuverse/main.dart';
import '../widgets/summary_row.dart';

class SuccessStep extends StatelessWidget {
  final OnboardingController ctrl;
  const SuccessStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // ─ Icône succès ──────────────────────────────────────────
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient:     AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color:      AppColors.primary
                      .withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.white,
              size:  50,
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Bienvenue dans\nla tribu ! 🎌',
            style: AppTextStyles.h1.copyWith(
                height: 1.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Ton profil est personnalisé selon\n'
            'tes goûts. Profite de l\'expérience !',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ─ Récapitulatif ─────────────────────────────────────────
          if (ctrl.selectedGenres.isNotEmpty) ...[
            SummaryRow(
              icon:  Icons.local_fire_department_rounded,
              color: AppColors.accent,
              label: '${ctrl.selectedGenres.length}'
                  ' genres sélectionnés',
            ),
            const SizedBox(height: 8),
          ],
          if (ctrl.selectedAnimes.isNotEmpty) ...[
            SummaryRow(
              icon:  Icons.movie_outlined,
              color: AppColors.primary,
              label: '${ctrl.selectedAnimes.length}'
                  ' animes favoris',
            ),
            const SizedBox(height: 8),
          ],
          SummaryRow(
            icon:  Icons.emoji_events_rounded,
            color: AppColors.gold,
            label: 'Rang Novice Lv.1 — débloqué !',
          ),
          const SizedBox(height: 40),

          // ─ Bouton Explorer ───────────────────────────────────────
          GestureDetector(
            onTap: ctrl.isLoading.value
                ? null
                : () async {
                    final ok =
                        await ctrl.saveAndFinish();
                    if (ok) {
                      Get.offAllNamed(Routes.home);
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds: 200),
              height: 56,
              width:  double.infinity,
              decoration: BoxDecoration(
                gradient: ctrl.isLoading.value
                    ? null
                    : AppColors.primaryGradient,
                color: ctrl.isLoading.value
                    ? AppColors.primary
                        .withValues(alpha: 0.4)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: ctrl.isLoading.value
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: ctrl.isLoading.value
                    ? const SizedBox(
                        width: 24, height: 24,
                        child:
                            CircularProgressIndicator(
                          color:       AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            'Explorer Otakuverse',
                            style: AppTextStyles.button
                                .copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: AppColors.white,
                            size:  18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ));
  }
}