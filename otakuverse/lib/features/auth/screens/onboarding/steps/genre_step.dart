import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';

class GenreStep extends StatelessWidget {
  final OnboardingController ctrl;
  const GenreStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 4),
      child: Wrap(
        spacing:    10,
        runSpacing: 10,
        children: OnboardingController.genres
            .map((g) => _GenreChip(
                  genre:    g.$1,
                  emoji:    g.$2,
                  selected: ctrl.selectedGenres
                      .contains(g.$1),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.toggleGenre(g.$1);
                  },
                ))
            .toList(),
      ),
    ));
  }
}

class _GenreChip extends StatelessWidget {
  final String       genre;
  final String       emoji;
  final bool         selected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.genre,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  Color _color() {
    switch (genre.toLowerCase()) {
      case 'shonen':
      case 'action':       return AppColors.accent;
      case 'romance':
      case 'shojo':        return AppColors.sakura;
      case 'thriller':
      case 'psychological':return AppColors.primary;
      case 'isekai':
      case 'fantasy':      return AppColors.neonBlue;
      case 'sci-fi':
      case 'mecha':        return AppColors.neonBlue;
      case 'horreur':      return AppColors.error;
      case 'sports':
      case 'comédie':      return AppColors.gold;
      default:             return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:      color.withValues(
                        alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              genre,
              style: AppTextStyles.bodySemiBold
                  .copyWith(
                color: selected
                    ? color
                    : AppColors.textSecondary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size:  14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}