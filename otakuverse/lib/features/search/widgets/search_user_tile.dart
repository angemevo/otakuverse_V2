import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';

/// Tuile utilisateur affichée dans les résultats et suggestions de recherche.
class SearchUserTile extends StatelessWidget {
  final ProfileModel     profile;
  final FollowController followController;

  const SearchUserTile({
    super.key,
    required this.profile,
    required this.followController,
  });

  @override
  Widget build(BuildContext context) {
    followController.loadFollowState(profile.userId);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: profile.userId)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          CachedAvatar(
            url:            profile.avatarUrl,
            radius:         24,
            fallbackLetter: profile.displayNameOrUsername,
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildInfo()),
          _buildFollowButton(),
        ]),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            profile.displayNameOrUsername,
            style: GoogleFonts.inter(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   14,
            ),
          ),
          if (profile.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppColors.primary, size: 14),
          ],
        ]),
        const SizedBox(height: 2),
        Text('@${profile.username}',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 12)),
        if (profile.followersCount > 0) ...[
          const SizedBox(height: 2),
          Text(
            '${Helpers.formatNumber(profile.followersCount)} abonnés',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildFollowButton() {
    return Obx(() {
      final isFollowing = followController.isFollowing(profile.userId);
      final isLoading   = followController.isLoading.value;

      // ✅ Key sur le GestureDetector du bouton follow
      return GestureDetector(
        key:   AppKeys.followButton,
        onTap: isLoading
            ? null
            : () => followController.toggleFollow(profile.userId),
        child: AnimatedContainer(
          duration:  const Duration(milliseconds: 250),
          curve:     Curves.easeOutCubic,
          padding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFollowing
                  ? AppColors.textPrimary.withValues(alpha: 0.4)
                  : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  isFollowing ? 'Abonné' : 'Suivre',
                  style: GoogleFonts.inter(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                ),
        ),
      );
    });
  }
}
