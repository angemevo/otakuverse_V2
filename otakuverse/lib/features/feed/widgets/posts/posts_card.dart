import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_actions.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_footer.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_header.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_media.dart';
import 'package:otakuverse/features/feed/widgets/posts/post_card_menu.dart';
import 'package:otakuverse/features/profile/screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel     post;
  final bool          isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDelete; // FIX : était bool, jamais utilisé
  final bool          isMe;

  const PostCard({
    super.key,
    required this.post,
    this.isLiked  = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onDelete,
    required this.isMe,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _isLiked = widget.isLiked;
    }
  }

  // ─── NAVIGATION ──────────────────────────────────────────────────
  void _goToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: widget.post.userId),
      ),
    );
  }

  // ─── LIKE ────────────────────────────────────────────────────────
  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    widget.onLike?.call();
  }

  void _onDoubleTap() {
    if (!_isLiked) _toggleLike();
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  // ─── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color:        AppColors.bgCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostCardHeader(
            post:          widget.post,
            onProfileTap:  _goToProfile,
            onMenuTap: () => showPostMenu(
              context:   context,
              post:      widget.post,
              isMe:      widget.isMe,
              onProfile: _goToProfile,
              onDelete:  widget.onDelete,
            ),
          ),
          if (widget.post.mediaUrls.isNotEmpty)
            PostCardMedia(
              post:        widget.post,
              showHeart:   _showHeart,
              onDoubleTap: _onDoubleTap,
            ),
          PostCardActions(
            post:      widget.post,
            isLiked:   _isLiked,
            onLike:    _toggleLike,
            onComment: widget.onComment,
            onShare:   widget.onShare,
          ),
          PostCardFooter(
            post:      widget.post,
            isLiked:   _isLiked,
            onComment: widget.onComment,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
