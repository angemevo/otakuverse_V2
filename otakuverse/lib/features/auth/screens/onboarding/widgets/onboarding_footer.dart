import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';

class OnboardingFooter extends StatelessWidget {
  final OnboardingController ctrl;
  const OnboardingFooter({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final step = ctrl.currentStep.value;

    // ✅ Étape succès → footer géré dans SuccessStep
    if (step == 2) return const SizedBox.shrink();

    final canProceed =
        step == 0
            ? ctrl.selectedGenres.length >= 3
            : true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─ Compteur sélection ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              step == 0
                  ? '${ctrl.selectedGenres.length} / 3 minimum'
                  : '${ctrl.selectedAnimes.length} sélectionné(s)',
              style: AppTextStyles.caption.copyWith(
                color: canProceed
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),

          // ─ Bouton suivant ────────────────────────────────────────
          GestureDetector(
            onTap: canProceed
                ? () {
                    HapticFeedback.lightImpact();
                    ctrl.nextStep();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds: 200),
              height: 52,
              width:  double.infinity,
              decoration: BoxDecoration(
                gradient: canProceed
                    ? AppColors.primaryGradient
                    : null,
                color: canProceed
                    ? null
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(14),
                boxShadow: canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    step == 1 ? 'Terminer' : 'Suivant',
                    style: AppTextStyles.button.copyWith(
                      color: canProceed
                          ? AppColors.white
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    step == 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: canProceed
                        ? AppColors.white
                        : AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}