import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class AnimeCard extends StatelessWidget {
  final String       name;
  final String       imageUrl;
  final bool         selected;
  final VoidCallback onTap;

  const AnimeCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:      AppColors.primary
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─ Cover ───────────────────────────────────────────
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(
                  color: AppColors.bgCard,
                  child: const Icon(
                    Icons.movie_outlined,
                    color: AppColors.textMuted,
                    size:  32,
                  ),
                ),
              ),

              // ─ Gradient bas ────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black
                            .withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // ─ Titre ───────────────────────────────────────────
              Positioned(
                bottom: 6, left: 6, right: 6,
                child: Text(
                  name,
                  style: AppTextStyles.captionBold
                      .copyWith(
                    color:    AppColors.white,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ─ Check ───────────────────────────────────────────
              if (selected)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size:  14,
                    ),
                  ),
                ),

              // ─ Overlay ─────────────────────────────────────────
              if (selected)
                Container(
                  color: AppColors.primary
                      .withValues(alpha: 0.15),
                ),
            ],
          ),
        ),
      ),
    );
  }
}