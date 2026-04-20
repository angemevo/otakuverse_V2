import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class RankBadge extends StatelessWidget {
  final String rank;
  final int    level;
  final bool   large;
  final bool   showProgress;
  final double progress; // 0.0 à 1.0

  const RankBadge({
    super.key,
    required this.rank,
    required this.level,
    this.large        = false,
    this.showProgress = false,
    this.progress     = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rankColor(rank);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─ Badge principal ─────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 14 : 10,
            vertical:   large ? 6  : 4,
          ),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─ Hexagone icône ──────────────────────────────────
              _RankIcon(rank: rank, color: color,
                  size: large ? 16 : 12),
              const SizedBox(width: 6),

              // ─ Titre + niveau ──────────────────────────────────
              Text(
                rank,
                style: (large
                        ? AppTextStyles.labelLarge
                        : AppTextStyles.label)
                    .copyWith(color: color),
              ),
              const SizedBox(width: 4),
              Text(
                'Lv.$level',
                style: (large
                        ? AppTextStyles.level
                        : AppTextStyles.statSmall)
                    .copyWith(color: color),
              ),
            ],
          ),
        ),

        // ─ Barre de progression ─────────────────────────────────
        if (showProgress) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 140,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           progress,
                    minHeight:       4,
                    backgroundColor: AppColors.bgElevated,
                    valueColor:
                        AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(progress * 100).toInt()}% vers Lv.${level + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── ICÔNE HEXAGONE ──────────────────────────────────────────────────
class _RankIcon extends StatelessWidget {
  final String rank;
  final Color  color;
  final double size;

  const _RankIcon({
    required this.rank,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _rankIcon(rank);
    return Icon(icon, color: color, size: size);
  }

  IconData _rankIcon(String rank) {
    switch (rank.toLowerCase()) {
      case 'kami':    return Icons.auto_awesome;
      case 'mangaka': return Icons.brush_rounded;
      case 'sensei':  return Icons.school_rounded;
      case 'senpai':  return Icons.star_rounded;
      case 'otaku':   return Icons.local_fire_department_rounded;
      default:        return Icons.lens_rounded;
    }
  }
}
