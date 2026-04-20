import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';

class StoryCircle extends StatelessWidget {
  final StoryGroup   group;
  final VoidCallback onTap;

  const StoryCircle({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // ─ Anneau gradient (non vue) ou grisé (vue) ──
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: group.hasUnviewed
                        ? const LinearGradient(
                            colors: [Color(0xFFE01A3C), Color(0xFFFF6B35)],
                            begin:  Alignment.topLeft,
                            end:    Alignment.bottomRight,
                          )
                        : null,
                    color: group.hasUnviewed
                        ? null
                        : AppColors.textMuted.withValues(alpha: 0.4),
                  ),
                ),
                // ─ Séparateur blanc ───────────────────────────
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bgPrimary,
                      width: 2.5,
                    ),
                  ),
                ),
                // ─ Avatar ─────────────────────────────────────
                CachedAvatar(
                  url:            group.avatarUrl,
                  radius:         26,
                  fallbackLetter: group.displayNameOrUsername,
                ),
                // ─ Bouton + (mes stories) ─────────────────────
                if (group.isMe)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color:  AppColors.primary,
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: AppColors.bgPrimary,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            // ─ Nom ────────────────────────────────────────────
            Text(
              group.isMe ? 'Ma story' : group.displayNameOrUsername,
              style: GoogleFonts.inter(
                color: group.hasUnviewed
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontSize:   11,
                fontWeight: group.hasUnviewed
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // ─ Badge Découverte ───────────────────────────────
            if (group.isDiscovery) _badge(
              label: 'Découverte',
              color: AppColors.primary,
            ),

            // ─ Badge Sponsorisé ───────────────────────────────
            if (group.isSponsored) _badge(
              label: 'Sponsorisé',
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String label, required Color color}) {
    return Container(
      margin:  const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border:       Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color:      color,
          fontSize:   8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
