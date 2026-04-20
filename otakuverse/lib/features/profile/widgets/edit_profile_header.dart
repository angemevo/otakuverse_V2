import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

/// Header de l'écran d'édition du profil.
/// Contient la bannière cliquable, l'avatar avec bouton caméra,
/// et les boutons de navigation (retour + modifier bannière).
class EditProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final Uint8List?   avatarPreview;
  final Uint8List?   bannerPreview;
  final VoidCallback onPickAvatar;
  final VoidCallback onPickBanner;
  final VoidCallback onBack;

  const EditProfileHeader({
    super.key,
    required this.profile,
    required this.avatarPreview,
    required this.bannerPreview,
    required this.onPickAvatar,
    required this.onPickBanner,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBanner(),
          _buildBottomGradient(),
          _buildTopButtons(),
          _buildAvatar(),
          _buildNameHint(),
        ],
      ),
    );
  }

  // ─── Bannière ────────────────────────────────────────────────────

  Widget _buildBanner() {
    return GestureDetector(
      onTap: onPickBanner,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          key:    ValueKey(bannerPreview),
          width:  double.infinity,
          height: 200,
          child: bannerPreview != null
              ? Image.memory(bannerPreview!, fit: BoxFit.cover, width: double.infinity)
              : profile.hasBanner
                  ? Image.network(profile.bannerUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 80, left: 0, right: 0,
      child: Container(
        height: 120,
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

  // ─── Boutons haut ────────────────────────────────────────────────

  Widget _buildTopButtons() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EditProfileNavBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
              EditProfileNavBtn(
                icon:  Icons.photo_outlined,
                label: 'Bannière',
                onTap: onPickBanner,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avatar ──────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Positioned(
      bottom: 0, left: 20,
      child: GestureDetector(
        onTap: onPickAvatar,
        child: Stack(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              border: Border.all(color: AppColors.bgPrimary, width: 4),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: CircleAvatar(
                key:             ValueKey(avatarPreview?.length),
                radius:          41,
                backgroundColor: AppColors.bgCard,
                backgroundImage: avatarPreview != null
                    ? MemoryImage(avatarPreview!) as ImageProvider
                    : profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                child: avatarPreview == null && profile.avatarUrl == null
                    ? Text(
                        profile.displayNameOrUsername[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color:      Colors.white,
                          fontSize:   28,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          // ─ Bouton caméra ────────────────────────────────────
          Positioned(
            bottom: 2, right: 2,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:  AppColors.primary,
                shape:  BoxShape.circle,
                border: Border.all(color: AppColors.bgPrimary, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Nom / username en bas à droite ──────────────────────────────

  Widget _buildNameHint() {
    return Positioned(
      bottom: 6, left: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayNameOrUsername,
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize:   16,
            ),
          ),
          Text(
            '@${profile.username}',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton navigation transparent ───────────────────────────────────

class EditProfileNavBtn extends StatelessWidget {
  final IconData     icon;
  final String?      label;
  final VoidCallback onTap;

  const EditProfileNavBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:        Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(label != null ? 20 : 12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label!,
                style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ]),
      ),
    );
  }
}
