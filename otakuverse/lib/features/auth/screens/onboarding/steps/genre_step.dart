import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/auth/controllers/onboarding_controller.dart';

class GenreStep extends StatelessWidget {
  final OnboardingController ctrl;
  const GenreStep({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ Extraction locale — règle GetX obligatoire
      final selectedGenres = ctrl.selectedGenres.toList();

      return Wrap(
        spacing:   8,
        runSpacing: 8,
        children: OnboardingController.genres.map((genre) {
          final isSelected = selectedGenres.contains(genre.$1);

          // ✅ FIX — params harmonisés : genre/emoji/selected/onTap
          return _GenreChip(
            genre:    genre.$1,
            emoji:    genre.$2,
            selected: isSelected,
            onTap:    () => ctrl.toggleGenre(genre.$1),
          );
        }).toList(),
      );
    });
  }
}

// ─── Genre chip ───────────────────────────────────────────────────────

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
      case 'action':        return AppColors.accent;
      case 'romance':
      case 'shojo':         return AppColors.sakura;
      case 'thriller':
      case 'psychological': return AppColors.primary;
      case 'isekai':
      case 'fantasy':
      case 'sci-fi':
      case 'mecha':         return AppColors.neonBlue;
      case 'horreur':       return AppColors.error;
      case 'sports':
      case 'comédie':       return AppColors.gold;
      // ✅ FIX — AppColors.primaryLight n'existe pas → AppColors.primary
      default:              return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // ✅ FIX — AppColors.border → AppColors.textMuted.withValues(alpha: 0.4)
            color: selected
                ? color
                : AppColors.textMuted.withValues(alpha: 0.4),
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              genre,
              style: AppTextStyles.bodySemiBold.copyWith(
                // ✅ FIX — AppColors.textSecondary → AppColors.textMuted
                color: selected ? color : AppColors.textMuted,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, color: color, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}