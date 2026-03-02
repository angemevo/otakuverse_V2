import 'package:get/get.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/post_service.dart';

class PostsController extends GetxController {
  final _postService = PostService();

  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ─── CHARGER LE FEED ─────────────────────────────────────────────
  Future<void> loadFeed() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _postService.getFeed();
      posts.value = result;
    } catch (e) {
      errorMessage.value = 'Impossible de charger le feed';
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
    required String caption,
    required List<String> mediaUrls,
    String? location,
    bool allowComments = true,
  }) async {
    isLoading.value = true;
    try {
      final post = await _postService.createPost(
        caption: caption,
        mediaUrls: mediaUrls,
        location: location,
        allowComments: allowComments,
      );
      posts.insert(0, post);
      return true;
    } catch (e) {
      errorMessage.value = 'Erreur lors de la publication';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── TOGGLE LIKE (optimistic update) ─────────────────────────────
  Future<void> toggleLike(String postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final wasLiked = posts[index].isLiked;
    // Mise à jour optimiste immédiate
    posts[index] = posts[index].copyWith(
      isLiked: !wasLiked,
      likesCount: posts[index].likesCount + (wasLiked ? -1 : 1),
    );
    posts.refresh();

    try {
      await _postService.toggleLike(postId);
    } catch (_) {
      // Rollback si erreur
      posts[index] = posts[index].copyWith(
        isLiked: wasLiked,
        likesCount: posts[index].likesCount + (wasLiked ? 1 : -1),
      );
      posts.refresh();
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