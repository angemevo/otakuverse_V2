import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/controllers/bookmark_controller.dart';
import 'package:otakuverse/features/feed/screens/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';

class ProfileTabBookmarks extends StatelessWidget {
  final String       currentUserId;
  final Future<void> Function(String postId) onDeletePost;

  const ProfileTabBookmarks({
    super.key,
    required this.currentUserId,
    required this.onDeletePost,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<BookmarkController>()
        ? Get.find<BookmarkController>()
        : null;

    if (ctrl == null) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.crimsonRed),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.bookmarkedPosts.isEmpty &&
          !ctrl.isLoading.value) {
        ctrl.loadBookmarks();
      }
    });

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
              color: AppColors.crimsonRed),
        );
      }

      if (ctrl.bookmarkedPosts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(HeroiconsOutline.bookmark,
                  color: AppColors.mediumGray, size: 48),
              const SizedBox(height: 12),
              Text('Aucune sauvegarde',
                  style: GoogleFonts.poppins(
                      color:      AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                      fontSize:   16)),
              const SizedBox(height: 6),
              Text(
                'Bookmark des posts pour les retrouver ici',
                style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding:   const EdgeInsets.only(top: 8),
        itemCount: ctrl.bookmarkedPosts.length + 1,
        itemBuilder: (context, index) {
          // ─ Footer loader / "tout vu" ──────────────────────
          if (index == ctrl.bookmarkedPosts.length) {
            if (ctrl.isLoadingMore.value) {
              return const Padding(
                padding:
                    EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:       AppColors.crimsonRed),
                ),
              );
            }
            if (!ctrl.hasMore.value) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24),
                child: Center(
                  child: Text('Tu as tout vu ! 🎉',
                      style: GoogleFonts.inter(
                          color:    AppColors.mediumGray,
                          fontSize: 13)),
                ),
              );
            }
            return const SizedBox(height: 20);
          }

          final post    = ctrl.bookmarkedPosts[index];
          // Seul le propriétaire du post peut le supprimer
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
    });
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

class _DeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkGray,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer ce post ?',
          style: GoogleFonts.poppins(
              color:      AppColors.pureWhite,
              fontWeight: FontWeight.w600)),
      content: Text('Cette action est irréversible.',
          style: GoogleFonts.inter(
              color: AppColors.mediumGray)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Annuler',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimsonRed,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Supprimer',
              style: GoogleFonts.inter(
                  color: AppColors.pureWhite)),
        ),
      ],
    );
  }
}