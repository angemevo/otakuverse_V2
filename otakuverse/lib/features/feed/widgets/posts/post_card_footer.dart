import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/widgets/posts/expandable_text.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_music_player.dart';

class PostCardFooter extends StatelessWidget {
  final PostModel     post;
  final bool          isLiked;
  final VoidCallback? onComment;

  const PostCardFooter({
    super.key,
    required this.post,
    required this.isLiked,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLikesCount(),
        _buildCaption(),
        // ✅ Badge musique — affiché si une musique est associée
        if (post.musicTitle != null) PostCardMusicPlayer(post: post),
        if (post.commentsCount > 0) _buildCommentsPreview(),
        _buildTimestamp(),
        const SizedBox(height: 4),
      ],
    );
  }

  // ─── COMPTEUR LIKES ──────────────────────────────────────────────
  Widget _buildLikesCount() {
    final displayCount =
        (isLiked && post.likesCount == 0) ? 1 : post.likesCount;
    if (displayCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 2),
      child: Text(
        _formatCount(displayCount),
        style: GoogleFonts.inter(
          color:      AppColors.pureWhite,
          fontWeight: FontWeight.w600,
          fontSize:   14,
        ),
      ),
    );
  }

  // ─── CAPTION ─────────────────────────────────────────────────────
  Widget _buildCaption() {
    if (post.caption.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      child: ExpandableText(
        username: post.displayNameOrUsername,
        caption:  post.caption,
      ),
    );
  }

  // ─── APERÇU COMMENTAIRES ─────────────────────────────────────────
  Widget _buildCommentsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 2),
      child: GestureDetector(
        onTap: onComment,
        child: Text(
          'Voir les ${post.commentsCount} commentaires',
          style: GoogleFonts.inter(
              color:    AppColors.mediumGray,
              fontSize: 13),
        ),
      ),
    );
  }

  // ─── TIMESTAMP ───────────────────────────────────────────────────
  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      child: Text(
        _formatDate(post.createdAt),
        style: GoogleFonts.inter(
          color:    AppColors.mediumGray
              .withValues(alpha: 0.7),
          fontSize: 11,
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60)
      return 'À l\'instant';
    if (diff.inMinutes < 60)
      return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)
      return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7)
      return 'il y a ${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M j\'aime';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k j\'aime';
    }
    return '$count j\'aime';
  }
}