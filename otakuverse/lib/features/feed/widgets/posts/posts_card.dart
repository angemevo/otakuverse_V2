import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/widgets/posts/expandable_text.dart';
import 'package:otakuverse/features/feed/widgets/posts/heart_animation.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  bool _showHeart  = false;
  int  _currentPage = 0;
  final PageController _pageController = PageController();

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      color: AppColors.deepBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          // ✅ mediaUrls.isNotEmpty au lieu de hasMedia
          if (widget.post.mediaUrls.isNotEmpty) _buildMedia(),
          _buildActions(),
          _buildLikesCount(),
          _buildCaption(),
          if (widget.post.commentsCount > 0) _buildCommentsPreview(),
          _buildTimestamp(),
          const SizedBox(height: 8),
          // const Divider(color: Color(0xFF1A1A1A), height: 1),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // ─ Avatar ───────────────────────────────────────────────
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkGray,
            backgroundImage: widget.post.avatarUrl != null &&
                    widget.post.avatarUrl!.isNotEmpty
                ? NetworkImage(widget.post.avatarUrl!)
                : null,
            child: (widget.post.avatarUrl == null ||
                    widget.post.avatarUrl!.isEmpty)
                ? Text(
                    // ✅ Initiale du username
                    widget.post.displayNameOrUsername.isNotEmpty
                        ? widget.post.displayNameOrUsername[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // ─ Username + location ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ✅ displayNameOrUsername
                    Text(
                      widget.post.displayNameOrUsername,
                      style: GoogleFonts.inter(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.post.isPinned) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.push_pin,
                        color: AppColors.crimsonRed,
                        size: 13,
                      ),
                    ],
                  ],
                ),
                // ✅ hasLocation depuis PostModel
                if (widget.post.hasLocation)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.mediumGray, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        widget.post.location!,
                        style: GoogleFonts.inter(
                          color: AppColors.mediumGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ─ Menu ─────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.pureWhite),
            onPressed: () => _showPostMenu(context),
          ),
        ],
      ),
    );
  }

  // ─── MEDIA ───────────────────────────────────────────────────────
  Widget _buildMedia() {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: widget.post.isCarousel
                ? _buildCarousel()
                : _buildSingleImage(widget.post.mediaUrls.first),
          ),

          // Badge carrousel
          if (widget.post.isCarousel)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1}/${widget.post.mediaCount}',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ),

          // Animation cœur
          if (_showHeart)
            const Positioned.fill(child: HeartAnimation()),
        ],
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.darkGray,
          child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.crimsonRed),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.darkGray,
        child: const Icon(Icons.broken_image,
            color: AppColors.mediumGray, size: 48),
      ),
    );
  }

  Widget _buildCarousel() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.post.mediaUrls.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) =>
              _buildSingleImage(widget.post.mediaUrls[i]),
        ),

        // Dots indicateurs
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.post.mediaUrls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.crimsonRed
                      : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          // Like
          _actionIconButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? AppColors.crimsonRed : AppColors.pureWhite,
            onPressed: _toggleLike,
            animate: true,
          ),

          // Commentaire
          _actionIconButton(
            icon: Icons.chat_bubble_outline,
            color: AppColors.pureWhite,
            onPressed: widget.onComment,
          ),

          // Partage
          _actionIconButton(
            icon: Icons.send_outlined,
            color: AppColors.pureWhite,
            onPressed: widget.onShare,
          ),

          const Spacer(),

          // Sauvegarder
          _actionIconButton(
            icon: Icons.bookmark_border,
            color: AppColors.pureWhite,
            onPressed: () {
              // TODO: Implémenter la sauvegarde
            },
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool animate = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: animate
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: color,
                size: 26,
              ),
            )
          : Icon(icon, color: color, size: 24),
    );
  }

  // ─── COMPTEUR LIKES ──────────────────────────────────────────────
  Widget _buildLikesCount() {
    final count = widget.post.likesCount;
    if (count == 0 && !_isLiked) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Text(
        _formatCount(count),
        style: GoogleFonts.inter(
          color: AppColors.pureWhite,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  // ─── CAPTION ─────────────────────────────────────────────────────
  Widget _buildCaption() {
    if (widget.post.caption.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpandableText(
        // ✅ displayNameOrUsername
        username: widget.post.displayNameOrUsername,
        caption:  widget.post.caption,
      ),
    );
  }

  // ─── APERÇU COMMENTAIRES ─────────────────────────────────────────
  Widget _buildCommentsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: GestureDetector(
        onTap: widget.onComment,
        child: Text(
          'Voir les ${widget.post.commentsCount} commentaires',
          style: GoogleFonts.inter(
              color: AppColors.mediumGray, fontSize: 13),
        ),
      ),
    );
  }

  // ─── TIMESTAMP ───────────────────────────────────────────────────
  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        _formatDate(widget.post.createdAt),
        style: GoogleFonts.inter(
          color: AppColors.mediumGray.withValues(alpha: 0.7),
          fontSize: 11,
        ),
      ),
    );
  }

  // ─── MENU CONTEXTUEL ─────────────────────────────────────────────
  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _menuItem(Icons.bookmark_border, 'Sauvegarder', () {}),
          _menuItem(Icons.person_outline, 'Voir le profil', () {}),
          _menuItem(Icons.link, 'Copier le lien', () {}),
          const Divider(color: AppColors.mediumGray, height: 1),
          _menuItem(
            Icons.flag_outlined, 'Signaler', () {},
            color: AppColors.crimsonRed,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.pureWhite, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
            color: color ?? AppColors.pureWhite, fontSize: 15),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7)     return 'il y a ${diff.inDays} j';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCount(int count) {
    if (count >= 1000000)
      return '${(count / 1000000).toStringAsFixed(1)}M j\'aime';
    if (count >= 1000)
      return '${(count / 1000).toStringAsFixed(1)}k j\'aime';
    return '$count j\'aime';
  }
}