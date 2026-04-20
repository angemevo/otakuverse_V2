import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/explore/controller/explore_controller.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/screens/comments/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ExploreController());

    _scrollController.addListener(() {
      final position  = _scrollController.position;
      final threshold = position.maxScrollExtent * 0.85;
      if (position.pixels >= threshold) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Get.delete<ExploreController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      onRetry: _controller.loadPosts,
      child: Scaffold(
        backgroundColor: AppColors.bgCard,
        appBar: AppBar(
          backgroundColor:           AppColors.bgCard,
          elevation:                 0,
          automaticallyImplyLeading: false,
          titleSpacing:              0,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  HeroiconsOutline.arrowLeft,
                  color: AppColors.textPrimary,
                  size:  22,
                ),
              ),
              const SizedBox(width: 12),
              Text('Explorer',
                  style: GoogleFonts.poppins(
                      color:      AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        body: Column(
          children: [
            // ─ Filtres genres ─────────────────────────────────
            _buildGenreFilters(),
            const Divider(color: Color(0xFF1F1F1F), height: 1),

            // ─ Feed tendance ──────────────────────────────────
            Expanded(
              child: Obx(() {
                // ─ Loading initial ────────────────────────────
                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                // ─ Erreur ─────────────────────────────────────
                if (_controller.errorMessage.value.isNotEmpty) {
                  return _buildError();
                }

                // ─ Empty state ────────────────────────────────
                if (_controller.posts.isEmpty) {
                  return _buildEmpty();
                }

                // ─ Liste posts ────────────────────────────────
                return RefreshIndicator(
                  color:           AppColors.primary,
                  backgroundColor: AppColors.bgCard,
                  onRefresh:       _controller.loadPosts,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding:    const EdgeInsets.only(top: 8),
                    itemCount:  _controller.posts.length + 1,
                    itemBuilder: (context, index) {

                      // ─ Footer ✅ Pas de Obx imbriqué ────────
                      if (index == _controller.posts.length) {
                        // Loading more
                        if (_controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        // Fin de liste
                        if (!_controller.hasMore.value &&
                            _controller.posts.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24),
                            child: Center(
                              child: Text(
                                'Tu as tout vu ! 🎉',
                                style: GoogleFonts.inter(
                                  color:    AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 20);
                      }

                      // ─ Post ─────────────────────────────────
                      final post = _controller.posts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: PostCard(
                          post:      post,
                          isLiked:   post.isLiked,
                          onLike:    () => _toggleLike(post.id),
                          onComment: () => showCommentsSheet(
                            context,
                            postId:     post.id,
                            postAuthor: post.displayNameOrUsername,
                          ), isMe: false,
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTRES GENRES ──────────────────────────────────────────────
  Widget _buildGenreFilters() {
    return SizedBox(
      height: 52,
      child: Obx(() {
        // ✅ Observable accédé DIRECTEMENT dans le scope Obx
        final currentGenre = _controller.selectedGenre.value;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          itemCount:   ExploreController.genres.length,
          itemBuilder: (_, index) {
            final genre    = ExploreController.genres[index];
            // ✅ On utilise currentGenre — pas .value dans le callback
            final selected = currentGenre == genre;

            return GestureDetector(
              onTap: () => _controller.selectGenre(genre),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:  const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  genre,
                  style: GoogleFonts.inter(
                    color: selected
                        ? Colors.white
                        : AppColors.textMuted,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  void _toggleLike(String postId) {
    final index =
        _controller.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post    = _controller.posts[index];
    final isLiked = !post.isLiked;

    _controller.updateLike(
      postId,
      isLiked:    isLiked,
      likesCount: isLiked
          ? post.likesCount + 1
          : (post.likesCount - 1).clamp(0, 999999),
    );

    if (Get.isRegistered<PostsController>()) {
      Get.find<PostsController>().toggleLike(postId);
    }
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(HeroiconsOutline.sparkles,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            _controller.selectedGenre.value.isEmpty
                ? 'Aucun post tendance'
                : 'Aucun post pour '
                  '"${_controller.selectedGenre.value}"',
            style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (_controller.selectedGenre.value.isNotEmpty)
            TextButton(
              onPressed: () => _controller.selectGenre(
                  _controller.selectedGenre.value),
              child: Text('Voir tous les posts',
                  style: GoogleFonts.inter(
                      color:      AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ─── ERREUR ──────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(HeroiconsOutline.exclamationCircle,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage.value,
            style: GoogleFonts.inter(
                color:    AppColors.textMuted,
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _controller.loadPosts,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Réessayer',
                  style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
