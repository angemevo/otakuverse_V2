import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class PostCardHeader extends StatelessWidget {
  final PostModel    post;
  final VoidCallback onProfileTap;
  final VoidCallback onMenuTap;

  const PostCardHeader({
    super.key,
    required this.post,
    required this.onProfileTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // ─ Avatar ──────────────────────────────────────────────
          GestureDetector(
            onTap: onProfileTap,
            child: CachedAvatar(
              url:            post.avatarUrl,
              radius:         18,
              fallbackLetter: post.displayNameOrUsername,
            ),
          ),
          const SizedBox(width: 10),

          // ─ Nom + location ──────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap:    onProfileTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      post.displayNameOrUsername,
                      style: GoogleFonts.inter(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
                      ),
                    ),
                    if (post.isPinned) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        HeroiconsOutline.mapPin,
                        color: AppColors.primary,
                        size:  13,
                      ),
                    ],
                  ]),
                  if (post.hasLocation)
                    Row(children: [
                      const Icon(
                        HeroiconsOutline.mapPin,
                        color: AppColors.textMuted,
                        size:  10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        post.location!,
                        style: GoogleFonts.inter(
                          color:    AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),

          // ─ Menu ────────────────────────────────────────────────
          GestureDetector(
            onTap: onMenuTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                HeroiconsOutline.ellipsisHorizontal,
                color: AppColors.textPrimary,
                size:  22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}