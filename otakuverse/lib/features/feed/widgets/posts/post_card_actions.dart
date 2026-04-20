import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/features/feed/controllers/bookmark_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class PostCardActions extends StatelessWidget {
  final PostModel     post;
  final bool          isLiked;
  final VoidCallback  onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCardActions({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final bookmarkCtrl = Get.isRegistered<BookmarkController>()
        ? Get.find<BookmarkController>()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(children: [
        // ─ Like ─────────────────────────────────────────────────
        _actionIconButton(
          key:   AppKeys.likeButton,
          icon:  isLiked
              ? HeroiconsSolid.heart
              : HeroiconsOutline.heart,
          color: isLiked ? AppColors.primary : AppColors.textPrimary,
          onPressed: onLike,
          animate:   true,
        ),

        // ─ Commentaire ───────────────────────────────────────────
        _actionIconButton(
          key:       AppKeys.commentButton,
          icon:      HeroiconsOutline.chatBubbleOvalLeft,
          color:     AppColors.textPrimary,
          onPressed: onComment,
        ),

        // ─ Partage ───────────────────────────────────────────────
        _actionIconButton(
          icon:      HeroiconsOutline.paperAirplane,
          color:     AppColors.textPrimary,
          onPressed: onShare,
        ),

        const Spacer(),

        // ─ Bookmark ──────────────────────────────────────────────
        bookmarkCtrl != null
            ? Obx(() {
                final saved = bookmarkCtrl.isBookmarked(post.id);
                return _actionIconButton(
                  key:  AppKeys.bookmarkButton,
                  icon: saved
                      ? HeroiconsSolid.bookmark
                      : HeroiconsOutline.bookmark,
                  color: saved
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  onPressed: () => bookmarkCtrl.toggleBookmark(post.id),
                  animate: true,
                );
              })
            : _actionIconButton(
                key:       AppKeys.bookmarkButton,
                icon:      HeroiconsOutline.bookmark,
                color:     AppColors.textPrimary,
                onPressed: null,
              ),
      ]),
    );
  }

  Widget _actionIconButton({
    Key?          key,
    required IconData icon,
    required Color    color,
    VoidCallback?     onPressed,
    bool              animate = false,
  }) {
    return IconButton(
      key:       key,
      onPressed: onPressed,
      icon: animate
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(icon,
                  key: ValueKey(icon), color: color, size: 26),
            )
          : Icon(icon, color: color, size: 24),
    );
  }
}
