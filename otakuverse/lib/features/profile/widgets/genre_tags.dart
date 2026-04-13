import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class GenreTags extends StatelessWidget {
  final List<String> genres;
  final bool         wrap;
  final VoidCallback? onTap;

  const GenreTags({
    super.key,
    required this.genres,
    this.wrap  = true,
    this.onTap,
  });

  // ─── Couleur par genre ───────────────────────────────────────────
  static Color _color(String genre) {
    final g = genre.toLowerCase();
    if (g.contains('action')  || g.contains('shonen'))  return AppColors.accent;
    if (g.contains('romance') || g.contains('slice'))   return AppColors.sakura;
    if (g.contains('psycho')  || g.contains('thriller'))return AppColors.primary;
    if (g.contains('isekai')  || g.contains('fantasy')) return AppColors.neonBlue;
    if (g.contains('horror')  || g.contains('dark'))    return AppColors.error;
    if (g.contains('comedy')  || g.contains('ecchi'))   return AppColors.gold;
    if (g.contains('sport')   || g.contains('mecha'))   return AppColors.jade;
    return AppColors.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    final tags = genres.map((g) => _Tag(
      label: g,
      color: _color(g),
      onTap: onTap,
    )).toList();

    if (!wrap) {
      return SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount:       tags.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: 6),
          itemBuilder: (_, i) => tags[i],
        ),
      );
    }

    return Wrap(
      spacing:  8,
      runSpacing: 6,
      children: tags,
    );
  }
}

class _Tag extends StatelessWidget {
  final String   label;
  final Color    color;
  final VoidCallback? onTap;

  const _Tag({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
              color: color),
        ),
      ),
    );
  }
}