import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';

class ProfileTabLikes extends StatelessWidget {
  final List<PostModel> likedPosts;
  final bool            isMe;
  final String          currentUserId;
  final Future<void>    Function(String postId) onDeletePost;

  const ProfileTabLikes({
    super.key,
    required this.likedPosts,
    required this.isMe,
    required this.currentUserId,
    required this.onDeletePost,
  });

  @override
  Widget build(BuildContext context) {
    // Seul le propriétaire voit ses likes
    if (!isMe) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Privé',
                style: GoogleFonts.poppins(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   16)),
          ],
        ),
      );
    }

    if (likedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Aucun post liké',
                style: GoogleFonts.poppins(
                    color:      AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize:   16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:   const EdgeInsets.only(top: 8),
      itemCount: likedPosts.length,
      itemBuilder: (context, index) {
        final post    = likedPosts[index];
        // Seul le propriétaire du post peut le supprimer
        final isOwner = post.userId == currentUserId;
        return PostCard(
          post:      post,
          isLiked:   true,
          isMe:      isOwner,
          onDelete:  isOwner
              ? () => _handleDelete(context, post.id)
              : null,
          onComment: () => showCommentsSheet(
            context,
            postId:     post.id,
            postAuthor: post.displayNameOrUsername,
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(
      BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(),
    );
    if (confirm == true) await onDeletePost(postId);
  }
}

// Réutilise le même dialog que ProfileTabPosts
class _DeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgPrimary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer ce post ?',
          style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600)),
      content: Text('Cette action est irréversible.',
          style: GoogleFonts.inter(
              color: AppColors.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Supprimer',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}