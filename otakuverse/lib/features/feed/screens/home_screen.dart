import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/text_styles.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/explore/screens/explore_screen.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/screens/comments_sheet.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/search/screens/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.posts.isEmpty) controller.loadFeed();
    });

    return ConnectivityWrapper(
      onRetry: controller.loadFeed,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo/otakuverse_logo.png'),
          ),
          title: Text('Otakuverse', style: AppTextStyles.appBarTitle),
          actions: [
            // ✅ Explorer
            IconButton(
              icon: const Icon(
                HeroiconsOutline.sparkles,
                color: AppColors.pureWhite,
                size:  24,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExploreScreen(),
                ),
              ),
            ),
            // ✅ Recherche
            IconButton(
              icon: const Icon(
                HeroiconsOutline.magnifyingGlass,
                color: AppColors.pureWhite,
                size:  24,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Obx(() {
          // ─ Chargement initial ──────────────────────────────────────
          if (controller.isLoading.value && controller.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.crimsonRed),
            );
          }
      
          // ─ Erreur ─────────────────────────────────────────────────
          if (controller.errorMessage.value.isNotEmpty &&
              controller.posts.isEmpty) {
            return _buildError(controller);
          }
      
          return RefreshIndicator(
            color:           AppColors.crimsonRed,
            backgroundColor: AppColors.deepBlack,
            onRefresh:       controller.loadFeed,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
      
                // ─ Feed vide (aucun post même en découverte) ─────────
                if (controller.posts.isEmpty)
                  const SliverFillRemaining(child: _EmptyFeed())
      
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // ─ Index 0 → bandeau découverte ──────────────
                        if (index == 0) {
                          return Obx(() {
                            if (!controller.isDiscoveryFeed.value) {
                              return const SizedBox.shrink();
                            }
                            return _DiscoveryBanner();
                          });
                        }
      
                        // ─ Posts (index - 1 car bandeau en index 0) ──
                        final post = controller.posts[index - 1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: PostCard(
                            post:      post,
                            isLiked:   post.isLiked,
                            onLike:    () =>
                                controller.toggleLike(post.id),
                            onComment: () => showCommentsSheet(
                              context,
                              postId:     post.id,
                              postAuthor: post.displayNameOrUsername,
                            ),
                          ),
                        );
                      },
                      // ✅ +1 pour le bandeau découverte
                      childCount: controller.posts.length + 1,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── ERREUR ──────────────────────────────────────────────────────
  Widget _buildError(PostsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: controller.loadFeed,
            child: const Text('Réessayer',
                style: TextStyle(color: AppColors.crimsonRed)),
          ),
        ],
      ),
    );
  }
}

// ─── BANDEAU DÉCOUVERTE ──────────────────────────────────────────────
class _DiscoveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.explore_outlined,
            color: AppColors.crimsonRed, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feed de découverte',
                style: GoogleFonts.poppins(
                  color:      AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                ),
              ),
              Text(
                'Suis des utilisateurs pour personnaliser ton feed',
                style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── EMPTY FEED ──────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dynamic_feed_outlined,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucun post pour le moment',
            style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   16),
          ),
          const SizedBox(height: 8),
          Text(
            'Sois le premier à publier quelque chose !',
            style: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}