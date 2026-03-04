import 'package:get/get.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsController extends GetxController {
  final _postService = PostService();

  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isDiscoveryFeed = false.obs;

  // ─── CHARGER LE FEED ─────────────────────────────────────────────
  Future<void> loadFeed() async {
    isLoading.value = true;
    try {
      final result = await _postService.getFeed();
      posts.assignAll(result);

      // ✅ Détecter si c'est un feed de découverte
      // (aucun post de mes follows → discovery)
      final myId      = Supabase.instance.client.auth.currentUser!.id;
      final myFollows = await _postService.getFollowingIds(myId);
      isDiscoveryFeed.value = myFollows.isEmpty;

    } catch (e) {
      errorMessage.value = 'Impossible de charger le feed';
      print('🔴 Erreur loadFeed : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── POSTS D'UN USER ─────────────────────────────────────────────
  Future<void> loadUserPosts(String userId) async {
    isLoading.value = true;
    try {
      final result = await _postService.getPostsByUser(userId);
      posts.value = result;
    } catch (e) {
      errorMessage.value = 'Impossible de charger les posts';
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CRÉER UN POST ───────────────────────────────────────────────
  Future<bool> createPost({
    required String       caption,
    required List<String> mediaUrls,
    String?               location,
    bool                  allowComments = true,
  }) async {
    try {
      final post = await _postService.createPost(
        caption:       caption,
        mediaUrls:     mediaUrls,
        location:      location,
        allowComments: allowComments,
      );
      posts.insert(0, post); // ✅ Ajouter en tête de liste
      isDiscoveryFeed.value = false; // ✅ A maintenant un post
      return true;
    } catch (e) {
      errorMessage.value = 'Impossible de créer le post';
      print('🔴 Erreur createPost : $e');
      return false;
    }
  }

  // ─── TOGGLE LIKE (optimistic update) ─────────────────────────────
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
          : post.likesCount - 1,
    );

    try {
      await _postService.toggleLike(postId);
    } catch (e) {
      // ✅ Rollback
      posts[index] = post;
      print('🔴 Erreur toggleLike : $e');
    }
  }

  // ─── SUPPRIMER UN POST ───────────────────────────────────────────
  Future<bool> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      posts.removeWhere((p) => p.id == postId);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la suppression';
      return false;
    }
  }

  // ─── ÉPINGLER ────────────────────────────────────────────────────
  Future<void> pinPost(String postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final isPinned = !posts[index].isPinned;
    try {
      await _postService.pinPost(postId, isPinned: isPinned);
      posts[index] = posts[index].copyWith(isPinned: isPinned);
      posts.refresh();
    } catch (_) {}
  }
}