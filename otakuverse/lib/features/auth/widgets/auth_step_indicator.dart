import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class AuthStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AuthStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─ Texte ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Étape $currentStep sur $totalSteps',
              style: AppTextStyles.label,
            ),
            Text(
              '${((currentStep / totalSteps) * 100).toInt()}%',
              style: AppTextStyles.statSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ─ Barres ────────────────────────────────────────────
        Row(
          children: List.generate(totalSteps, (i) {
            final done    = i < currentStep;
            final active  = i == currentStep - 1;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve:    Curves.easeOut,
                height:   4,
                margin:   EdgeInsets.only(
                    right: i < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: done || active
                      ? AppColors.primary
                      : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}