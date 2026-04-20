import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/profile/controllers/follow_controller.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class ProfileSliverAppBar extends StatelessWidget {
  final ProfileModel  profile;
  final bool          isMe;
  final String        targetId;
  final VoidCallback  onSettingsTap;
  final VoidCallback  onEditProfile;
  final VoidCallback  onToggleFollow;

  const ProfileSliverAppBar({
    super.key,
    required this.profile,
    required this.isMe,
    required this.targetId,
    required this.onSettingsTap,
    required this.onEditProfile,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SliverAppBar(
      expandedHeight:            200,
      backgroundColor:           AppColors.bgPrimary,
      automaticallyImplyLeading: false,
      pinned:                    true,
      elevation:                 0,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        profile.displayNameOrUsername,
        style: GoogleFonts.poppins(
            color:      AppColors.textPrimary,
            fontWeight: FontWeight.w600),
      ),
      actions: [
        if (isMe)
          IconButton(
            icon: const Icon(Icons.menu,
                color: AppColors.textPrimary),
            onPressed: onSettingsTap,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ─ Bannière ────────────────────────────────────────
            profile.hasBanner
                ? CachedImage(
                    url:    profile.bannerUrl,
                    width:  double.infinity,
                    height: double.infinity,
                    fit:    BoxFit.cover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient)),
            DecoratedBox(
              decoration: BoxDecoration(
                  gradient: AppColors.overlayGradient),
            ),

            // ─ Avatar + bouton action ──────────────────────────
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Stack(children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary,
                            width: 3),
                      ),
                      child: CachedAvatar(
                        url:            profile.avatarUrl,
                        radius:         36,
                        fallbackLetter:
                            profile.displayNameOrUsername,
                      ),
                    ),
                    if (isMe)
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: onEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.textPrimary,
                                size:  12),
                          ),
                        ),
                      ),
                  ]),

                  const Spacer(),

                  if (isMe)
                    _buildActionButton('Modifier',
                        onTap:    onEditProfile,
                        outlined: true)
                  else
                    _buildFollowButton(targetId, onToggleFollow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOUTON MODIFIER (isMe) ───────────────────────────────────
  Widget _buildActionButton(String label,
      {required VoidCallback onTap, bool outlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: outlined
                ? AppColors.textPrimary
                : AppColors.primary,
            width: 2,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize:   14)),
      ),
    );
  }

  // ─── BOUTON FOLLOW ────────────────────────────────────────────
  Widget _buildFollowButton(
      String targetId, VoidCallback onToggle) {
    final followCtrl = Get.find<FollowController>();

    return Obx(() {
      final following = followCtrl.isFollowing(targetId);
      final loading   = followCtrl.isLoading.value;

      return GestureDetector(
        onTap: loading ? null : onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve:    Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: following
                ? Colors.transparent
                : AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: following
                  ? AppColors.textPrimary.withValues(alpha: 0.5)
                  : AppColors.primary,
              width: 2,
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      following
                          ? Icons.check
                          : Icons.person_add_outlined,
                      color: AppColors.textPrimary,
                      size:  16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      following ? 'Abonné' : 'Suivre',
                      style: GoogleFonts.inter(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
