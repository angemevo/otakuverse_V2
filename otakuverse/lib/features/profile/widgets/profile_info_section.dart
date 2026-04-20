import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

/// Sections textuelles sous le SliverAppBar :
/// nom + vérification, location/website, stats, bio, genres.
class ProfileInfoSection extends StatelessWidget {
  final ProfileModel profile;

  const ProfileInfoSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildStats(),
        _buildBio(),
        if (profile.favoriteGenres.isNotEmpty) _buildGenres(),
      ],
    );
  }

  // ─── NOM + LOCATION + WEBSITE ──────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              profile.displayNameOrUsername,
              style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontSize:   22,
                  fontWeight: FontWeight.bold),
            ),
            if (profile.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified,
                  color: AppColors.primary, size: 20),
            ],
          ]),
          if (profile.location != null || profile.website != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (profile.location != null) ...[
                const Icon(Icons.location_on_outlined,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(profile.location!,
                    style: GoogleFonts.inter(
                        color:    AppColors.textMuted,
                        fontSize: 13)),
                const SizedBox(width: 12),
              ],
              if (profile.website != null) ...[
                const Icon(Icons.link,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(profile.website!,
                    style: GoogleFonts.inter(
                      color:           AppColors.primary,
                      fontSize:        13,
                      decoration:      TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    )),
              ],
            ]),
          ],
        ],
      ),
    );
  }

  // ─── STATS ─────────────────────────────────────────────────────
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        _statItem('${profile.postsCount}',     'Posts'),
        const SizedBox(width: 20),
        _statItem('${profile.followersCount}', 'Abonnés'),
        const SizedBox(width: 20),
        _statItem('${profile.followingCount}', 'Abonnements'),
      ]),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count,
            style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize:   18)),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  // ─── BIO ───────────────────────────────────────────────────────
  Widget _buildBio() {
    if (!profile.hasBio) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        profile.bio!,
        style: GoogleFonts.inter(
            color:    AppColors.textDisabled,
            fontSize: 14,
            height:   1.5),
      ),
    );
  }

  // ─── GENRES ────────────────────────────────────────────────────
  Widget _buildGenres() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: profile.favoriteGenres
            .map((g) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAlpha(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryAlpha(0.4)),
                  ),
                  child: Text('#$g',
                      style: GoogleFonts.inter(
                        color:      AppColors.primaryLight,
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                      )),
                ))
            .toList(),
      ),
    );
  }
}
