import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';

class WatchlistPreview extends StatelessWidget {
  final int    count;
  final bool   isMe;
  final String username;

  const WatchlistPreview({
    super.key,
    required this.count,
    required this.isMe,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Header ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    size:  18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ma Watchlist',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        AppColors.primary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count animes',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─ Slots watchlist ────────────────────────────────────────
          if (count == 0)
            _EmptyWatchlist(isMe: isMe)
          else
            Row(
              children: [
                // ─ 3 slots covers ──────────────────────────────────
                ...List.generate(3, (i) => _AnimeSlot(index: i)),
                const SizedBox(width: 10),

                // ─ Voir tout ───────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO Sprint 3 — AniList
                    },
                    child: Container(
                      height:  60,
                      decoration: BoxDecoration(
                        color:        AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.textMuted,
                            size:  18,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Voir tout',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // ─ Onglets statuts ────────────────────────────────────────
          if (count > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusChip(
                    label: 'En cours',
                    color: AppColors.jade,
                    icon:  Icons.play_arrow_rounded),
                const SizedBox(width: 6),
                _StatusChip(
                    label: 'Complété',
                    color: AppColors.primary,
                    icon:  Icons.check_rounded),
                const SizedBox(width: 6),
                _StatusChip(
                    label: 'Planifié',
                    color: AppColors.neonBlue,
                    icon:  Icons.bookmark_outline_rounded),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SLOT ANIME (placeholder) ────────────────────────────────────────
class _AnimeSlot extends StatelessWidget {
  final int index;
  const _AnimeSlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  50, height: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color:        AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textDisabled,
          size:  20,
        ),
      ),
    );
    // ✅ Sprint 3 : remplacer par Image.network(anime.coverImage)
  }
}

// ─── CHIP STATUT ─────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ─── ÉTAT VIDE ───────────────────────────────────────────────────────
class _EmptyWatchlist extends StatelessWidget {
  final bool isMe;
  const _EmptyWatchlist({required this.isMe});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.add_circle_outline_rounded,
        color: AppColors.textMuted,
        size:  18,
      ),
      const SizedBox(width: 8),
      Text(
        isMe
            ? 'Ajoute tes animes favoris'
            : 'Watchlist vide',
        style: AppTextStyles.bodySmall,
      ),
    ],
  );
}
