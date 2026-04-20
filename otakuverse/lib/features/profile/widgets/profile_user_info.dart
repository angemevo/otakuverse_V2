import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/widgets/genre_tags.dart';
import 'package:otakuverse/features/profile/widgets/rank_badge.dart';
import 'package:otakuverse/features/profile/widgets/watchlist_preview.dart';
import 'profile_action_button.dart';

/// Section infos utilisateur sous la bannière :
/// nom, rang, bio, genres, stats, boutons d'action, watchlist.
class ProfileUserInfo extends StatelessWidget {
  final ProfileModel profile;
  final bool         isMe;
  final bool         isFollowing;
  final bool         isOpeningChat;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpenChat;
  final VoidCallback onEditProfile;

  const ProfileUserInfo({
    super.key,
    required this.profile,
    required this.isMe,
    required this.isFollowing,
    required this.isOpeningChat,
    required this.onToggleFollow,
    required this.onOpenChat,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameRow(),
          Text('@${profile.username}', style: AppTextStyles.bodySmall),
          const SizedBox(height: 14),
          _buildRankSection(),
          const SizedBox(height: 14),
          if (profile.hasBio) ...[
            Text(profile.bio!, style: AppTextStyles.body),
            const SizedBox(height: 10),
          ],
          if (profile.favoriteGenres.isNotEmpty) ...[
            GenreTags(genres: profile.favoriteGenres, wrap: false),
            const SizedBox(height: 12),
          ],
          _buildStats(),
          const SizedBox(height: 14),
          _buildActions(),
          const SizedBox(height: 16),
          WatchlistPreview(
            count:    profile.watchlistCount,
            isMe:     isMe,
            username: profile.username,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Nom + badge vérifié ─────────────────────────────────────────

  Widget _buildNameRow() {
    return Row(children: [
      Text(profile.displayNameOrUsername, style: AppTextStyles.h2),
      if (profile.isVerified) ...[
        const SizedBox(width: 6),
        const Icon(Icons.verified_rounded,
            color: AppColors.primary, size: 18),
      ],
    ]);
  }

  // ─── Rang + progression ──────────────────────────────────────────

  Widget _buildRankSection() {
    final color = AppColors.rankColor(profile.otakuRank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RankBadge(
                  rank: profile.otakuRank,
                  level: profile.otakuLevel,
                  large: true),
              if (isMe)
                Text('${profile.otakuPoints} pts',
                    style: AppTextStyles.statSmall.copyWith(color: color)),
            ],
          ),
          if (isMe) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           profile.levelProgress,
                minHeight:       5,
                backgroundColor: AppColors.bgElevated,
                valueColor:      AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${profile.otakuPoints} pts actuels',
                    style: AppTextStyles.caption.copyWith(color: color)),
                Text('${profile.pointsForNextLevel} pts → Lv.${profile.otakuLevel + 1}',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Stats ───────────────────────────────────────────────────────

  Widget _buildStats() {
    return Row(children: [
      ProfileStatItem(value: _fmt(profile.postsCount),      label: 'Posts'),
      const ProfileStatSeparator(),
      ProfileStatItem(value: _fmt(profile.followersCount),  label: 'Abonnés',      onTap: () {}),
      const ProfileStatSeparator(),
      ProfileStatItem(value: _fmt(profile.followingCount),  label: 'Abonnements',  onTap: () {}),
      const ProfileStatSeparator(),
      ProfileStatItem(value: _fmt(profile.reviewsCount),    label: 'Avis'),
    ]);
  }

  // ─── Actions ─────────────────────────────────────────────────────

  Widget _buildActions() {
    if (isMe) {
      return Row(children: [
        Expanded(
          child: ProfileActionButton(
            key:      AppKeys.editProfileButton,
            label:    'Modifier le profil',
            icon:     Icons.edit_outlined,
            outlined: true,
            onTap:    onEditProfile,
          ),
        ),
        const SizedBox(width: 10),
        ProfileActionButton(icon: Icons.share_outlined, onTap: () {}),
      ]);
    }

    return Row(children: [
      Expanded(
        child: ProfileActionButton(
          label:    isFollowing ? 'Abonné' : 'Suivre',
          icon:     isFollowing
              ? Icons.person_remove_outlined
              : Icons.person_add_outlined,
          primary:  !isFollowing,
          outlined: isFollowing,
          onTap:    onToggleFollow,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ProfileActionButton(
          label:    'Message',
          icon:     Icons.mail_outline_rounded,
          outlined: true,
          loading:  isOpeningChat,
          onTap:    onOpenChat,
        ),
      ),
      const SizedBox(width: 10),
      ProfileActionButton(icon: Icons.more_horiz, onTap: () {}),
    ]);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
