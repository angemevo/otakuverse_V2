import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';

class ProfileTabPosts extends StatelessWidget {
  final List<PostModel> posts;
  final String          currentUserId;
  final bool            isMe;

  /// Reçoit l'id du post → confirme + supprime côté parent.
  final Future<void> Function(String postId) onDeletePost;

  const ProfileTabPosts({
    super.key,
    required this.posts,
    required this.currentUserId,
    required this.isMe,
    required this.onDeletePost,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.post_add,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Aucun post',
                style: GoogleFonts.poppins(
                    color:      AppColors.textPrimary,
                    fontSize:   16,
                    fontWeight: FontWeight.w600)),
            if (isMe) ...[
              const SizedBox(height: 8),
              Text('Crée ton premier post !',
                  style: GoogleFonts.inter(
                      color:    AppColors.textMuted,
                      fontSize: 13)),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding:   const EdgeInsets.only(top: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        // FIX : propriétaire réel du post, pas _isMe de l'écran
        final isOwner = post.userId == currentUserId;
        return PostCard(
          post:      post,
          isLiked:   post.isLiked,
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

// ─── DIALOG CONFIRMATION ─────────────────────────────────────────
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
