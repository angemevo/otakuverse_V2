import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

/// Bannière + avatar du profil.
/// Utilisé dans le FlexibleSpaceBar du SliverAppBar.
class ProfileBanner extends StatelessWidget {
  final ProfileModel profile;
  final bool         isMe;
  final VoidCallback onEditAvatar;

  const ProfileBanner({
    super.key,
    required this.profile,
    required this.isMe,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),
        _buildBottomGradient(),
        Positioned(
          bottom: 12, left: 16,
          child: _buildAvatar(),
        ),
      ],
    );
  }

  // ─── Fond ────────────────────────────────────────────────────────

  Widget _buildBackground() {
    if (profile.hasBanner) {
      return Image.network(
        profile.bannerUrl!,
        fit:            BoxFit.cover,
        color:          Colors.black26,
        colorBlendMode: BlendMode.darken,
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.accent.withValues(alpha: 0.4),
            AppColors.bgPrimary,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.bgPrimary],
          ),
        ),
      ),
    );
  }

  // ─── Avatar ──────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(color: AppColors.bgPrimary, width: 3),
          boxShadow: [
            BoxShadow(
              color:        AppColors.primary.withValues(alpha: 0.3),
              blurRadius:   16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CachedAvatar(
          url:            profile.avatarUrl,
          radius:         38,
          fallbackLetter: profile.displayNameOrUsername,
        ),
      ),
      if (isMe)
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: onEditAvatar,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:  AppColors.primary,
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.bgPrimary, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.white, size: 13),
            ),
          ),
        ),
    ]);
  }
}