import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/screens/edit_profile_screen.dart';

class ProfileTabAnimes extends StatelessWidget {
  final ProfileModel profile;
  final bool         isMe;
  final VoidCallback onProfileUpdated;

  const ProfileTabAnimes({
    super.key,
    required this.profile,
    required this.isMe,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = profile.favoriteAnime.isNotEmpty ||
        profile.favoriteManga.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                color: AppColors.mediumGray, size: 48),
            const SizedBox(height: 12),
            Text('Aucun animé/manga favori',
                style: GoogleFonts.inter(
                    color: AppColors.mediumGray)),
            if (isMe) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(profile: profile),
                    ),
                  );
                  onProfileUpdated();
                },
                child: Text('Ajouter des favoris',
                    style: GoogleFonts.inter(
                        color:      AppColors.crimsonRed,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile.favoriteAnime.isNotEmpty) ...[
          Text('Animés favoris',
              style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize:   16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: profile.favoriteAnime
                .map((a) => _chip(a))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (profile.favoriteManga.isNotEmpty) ...[
          Text('Mangas favoris',
              style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize:   16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: profile.favoriteManga
                .map((m) => _chip(m))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.crimsonWithOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.crimsonWithOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color:      AppColors.lightCrimson,
              fontSize:   13,
              fontWeight: FontWeight.w500)),
    );
  }
}