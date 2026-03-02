import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/constants/text_styles.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart';
import 'package:otakuverse/features/feed/widgets/stories/story_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PostsController>();

    // Charger le feed au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.posts.isEmpty) controller.loadFeed();
    });

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo/otakuverse_logo.png'),
        ),
        title: Text('Otakuverse', style: AppTextStyles.appBarTitle),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.crimsonRed),
          );
        }

        if (controller.errorMessage.value.isNotEmpty && controller.posts.isEmpty) {
          return _buildError(controller);
        }

        return RefreshIndicator(
          color: AppColors.crimsonRed,
          backgroundColor: AppColors.deepBlack,
          onRefresh: controller.loadFeed,
          child: CustomScrollView(
            slivers: [
              // Stories (vide pour l'instant — Phase 2)
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),

              if (controller.posts.isEmpty)
                const SliverFillRemaining(child: _EmptyFeed())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = controller.posts[index];
                      return PostCard(
                        post: post,
                        isLiked: post.isLiked,
                        onLike: () => controller.toggleLike(post.id),
                        onComment: () {
                          // TODO: ouvrir écran commentaires
                        },
                      );
                    },
                    childCount: controller.posts.length,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildError(PostsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: controller.loadFeed,
            child: const Text('Réessayer', style: TextStyle(color: AppColors.crimsonRed)),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dynamic_feed_outlined, color: AppColors.mediumGray, size: 48),
          SizedBox(height: 12),
          Text('Aucun post pour le moment', style: TextStyle(color: AppColors.mediumGray)),
          SizedBox(height: 8),
          Text(
            'Suis des utilisateurs pour voir leur contenu',
            style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
          ),
        ],
      ),
    );
  }
}