import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';

class PostsController extends GetxController {
  final _postService = PostService();

  // ─── State ───────────────────────────────────────────────────────
  final RxList<PostModel> posts           = <PostModel>[].obs;
  final RxBool            isLoading       = false.obs;
  final RxBool            isLoadingMore   = false.obs;
  final RxBool            hasMore         = true.obs;
  final RxBool            isDiscoveryFeed = false.obs;
  final RxString          errorMessage    = ''.obs;

  // ─── Pagination ──────────────────────────────────────────────────
  int              _offset   = 0;
  static const int _pageSize = 20;

  // ─── CHARGER le feed (première page) ─────────────────────────────
  Future<void> loadFeed() async {
    isLoading.value    = true;
    errorMessage.value = '';
    _offset            = 0;
    hasMore.value      = true;

    try {
      final result =
          await _postService.getFeed(offset: 0);
      posts.assignAll(result);

      // ✅ Détecter discovery feed
      final myId =
          Supabase.instance.client.auth.currentUser!.id;
      final following =
          await _postService.getFollowingIds(myId);
      isDiscoveryFeed.value = following.isEmpty;

      // ✅ Moins de 20 résultats → plus de pages
      if (result.length < _pageSize) {
        hasMore.value = false;
      }
      _offset = result.length;

    } catch (e) {
      errorMessage.value = 'Impossible de charger le feed';
      print('🔴 Erreur loadFeed : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CHARGER la page suivante ────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final result =
          await _postService.getFeed(offset: _offset);

      if (result.isEmpty || result.length < _pageSize) {
        hasMore.value = false;
      }

      posts.addAll(result);
      _offset += result.length;

    } catch (e) {
      print('🔴 Erreur loadMore : $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  Future<void> toggleLike(String postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    // ✅ Optimistic update
    final post    = posts[index];
    final isLiked = !post.isLiked;
    posts[index]  = post.copyWith(
      isLiked:    isLiked,
      likesCount: isLiked
          ? post.likesCount + 1
          : (post.likesCount - 1).clamp(0, 999999),
    );

    try {
      await _postService.toggleLike(postId);
    } catch (e) {
      // ✅ Rollback si erreur
      posts[index] = post;
      print('🔴 Erreur toggleLike : $e');
    }
  }

  // ─── CRÉER un post ───────────────────────────────────────────────
  // ✅ Recharge le feed depuis la DB au lieu d'insérer localement
  Future<bool> createPost({
    required String       caption,
    required List<String> mediaUrls,
    String?               location,
    bool                  allowComments = true,
  }) async {
    try {
      await _postService.createPost(
        caption:       caption,
        mediaUrls:     mediaUrls,
        location:      location,
        allowComments: allowComments,
      );

      // ✅ Recharger le feed complet
      await loadFeed();
      isDiscoveryFeed.value = false;
      return true;

    } catch (e) {
      errorMessage.value = 'Impossible de créer le post';
      print('🔴 Erreur createPost : $e');
      return false;
    }
  }

  // ─── METTRE À JOUR commentsCount ─────────────────────────────────
  void incrementCommentsCount(String postId) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post   = posts[index];
    posts[index] = post.copyWith(
        commentsCount: post.commentsCount + 1);
  }

  void decrementCommentsCount(String postId) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post   = posts[index];
    posts[index] = post.copyWith(
      commentsCount:
          (post.commentsCount - 1).clamp(0, 999999),
    );
  }
}