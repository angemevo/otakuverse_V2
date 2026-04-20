import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class ProfileTabAbout extends StatelessWidget {
  final ProfileModel profile;

  const ProfileTabAbout({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _aboutSection('Informations', [
          if (profile.location != null)
            _aboutItem(Icons.location_on_outlined,
                'Localisation', profile.location!),
          if (profile.website != null)
            _aboutItem(Icons.link, 'Site web',
                profile.website!, isLink: true),
          if (profile.gender != null)
            _aboutItem(Icons.person_outline, 'Genre',
                _genderLabel(profile.gender!)),
        ]),
        const SizedBox(height: 16),
        _aboutSection('Statistiques', [
          _aboutItem(Icons.article_outlined, 'Posts',
              '${profile.postsCount}'),
          _aboutItem(Icons.people_outline, 'Abonnés',
              '${profile.followersCount}'),
          _aboutItem(Icons.person_add_outlined, 'Abonnements',
              '${profile.followingCount}'),
        ]),
      ],
    );
  }

  Widget _aboutSection(String title, List<Widget> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.textMuted
                    .withValues(alpha: 0.3)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _aboutItem(IconData icon, String label, String value,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 14)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: GoogleFonts.inter(
                color: isLink
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontSize:        14,
                fontWeight:      FontWeight.w500,
                decoration:
                    isLink ? TextDecoration.underline : null,
                decorationColor: AppColors.primary,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  String _genderLabel(String gender) {
    const labels = {
      'male':              'Homme',
      'female':            'Femme',
      'other':             'Autre',
      'prefer_not_to_say': 'Préfère ne pas dire',
    };
    return labels[gender] ?? gender;
  }
}
