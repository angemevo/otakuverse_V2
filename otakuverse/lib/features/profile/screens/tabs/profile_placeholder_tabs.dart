import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Onglets placeholder — contenu à venir.
class ProfileReviewsTab extends StatelessWidget {
  const ProfileReviewsTab({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
    icon:  Icons.rate_review_outlined,
    label: 'Avis à venir',
  );
}

class ProfileFanArtTab extends StatelessWidget {
  const ProfileFanArtTab({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
    icon:  Icons.brush_outlined,
    label: 'Fan Art à venir',
  );
}

class ProfileClipsTab extends StatelessWidget {
  const ProfileClipsTab({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
    icon:  Icons.videocam_outlined,
    label: 'Clips à venir',
  );
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(color: AppColors.textMuted)),
    ]),
  );
}
