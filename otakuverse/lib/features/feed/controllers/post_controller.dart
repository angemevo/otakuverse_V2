import 'package:flutter/foundation.dart';
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

  // ─── CHARGER LE FEED (première page) ─────────────────────────────
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

      if (result.length < _pageSize) {
        hasMore.value = false;
      }
      _offset = result.length;
    } catch (e) {
      errorMessage.value =
          'Impossible de charger le feed';
      debugPrint('🔴 loadFeed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CHARGER LA PAGE SUIVANTE ────────────────────────────────────
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
      debugPrint('🔴 loadMore: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  Future<void> toggleLike(String postId) async {
    final index =
        posts.indexWhere((p) => p.id == postId);
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
      debugPrint('🔴 toggleLike: $e');
    }
  }

  // ─── CRÉER UN POST ───────────────────────────────────────────────
  Future<bool> createPost({
    required String       caption,
    required List<String> mediaUrls,
    String?               location,
    bool                  allowComments  = true,
    String?               musicTitle,
    String?               musicArtist,
    String?               musicTrackId,
    String?               musicPreviewUrl,
    String?               musicImageUrl,
  }) async {
    try {
      await _postService.createPost(
        caption:         caption,
        mediaUrls:       mediaUrls,
        location:        location,
        allowComments:   allowComments,
        musicTitle:      musicTitle,
        musicArtist:     musicArtist,
        musicTrackId:    musicTrackId,
        musicPreviewUrl: musicPreviewUrl,
        musicImageUrl:   musicImageUrl,
      );

      await loadFeed();
      isDiscoveryFeed.value = false;
      return true;
    } catch (e) {
      errorMessage.value =
          'Impossible de créer le post';
      debugPrint('🔴 createPost: $e');
      return false;
    }
  }

  // ─── COMPTEURS COMMENTAIRES ──────────────────────────────────────
  void incrementCommentsCount(String postId) {
    final index =
        posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post   = posts[index];
    posts[index] = post.copyWith(
        commentsCount: post.commentsCount + 1);
  }

  void decrementCommentsCount(String postId) {
    final index =
        posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post   = posts[index];
    posts[index] = post.copyWith(
      commentsCount:
          (post.commentsCount - 1).clamp(0, 999999),
    );
  }

  // ─── REFRESH FEED (Realtime) ─────────────────────────────────────
  // ✅ Utilise getFeed() qui existe déjà dans PostService
  Future<void> refreshFeed() async {
    try {
      final newPosts =
          await _postService.getFeed(offset: 0);

      // ✅ Merge intelligent
      for (final newPost in newPosts) {
        final index =
            posts.indexWhere((p) => p.id == newPost.id);
        if (index != -1) {
          // Mettre à jour si existant
          posts[index] = newPost;
        } else {
          // Nouveau post → insérer en tête
          posts.insert(0, newPost);
        }
      }

      // ✅ Retirer les posts supprimés
      // uniquement parmi les N premiers
      if (newPosts.isNotEmpty) {
        posts.removeWhere((p) =>
            !newPosts.any((n) => n.id == p.id) &&
            posts.indexOf(p) < newPosts.length);
      }

      debugPrint(
          '✅ refreshFeed: ${posts.length} posts');
    } catch (e) {
      debugPrint('❌ refreshFeed: $e');
    }
  }

  // ─── UPDATE LIKES (Realtime optimiste) ──────────────────────────
  void updatePostLikeCount({
    required String postId,
    required int    delta,
  }) {
    final index =
        posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    posts[index] = post.copyWith(
      likesCount: (post.likesCount + delta)
          .clamp(0, 999999),
    );
  }

  // ─── UPDATE COMMENTAIRES (Realtime optimiste) ────────────────────
  void updatePostCommentCount({
    required String postId,
    required int    delta,
  }) {
    final index =
        posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    posts[index] = post.copyWith(
      commentsCount: (post.commentsCount + delta)
          .clamp(0, 999999),
    );
  }

  // ─── REFRESH BOOKMARKS (Realtime) ───────────────────────────────
  // ✅ Émet juste un signal — ProfileTabBookmarks
  // se recharge lui-même via son propre state
  final RxInt bookmarksRefreshTrigger = 0.obs;

  void refreshBookmarks() {
    bookmarksRefreshTrigger.value++;
    debugPrint('✅ bookmarks refresh trigger');
  }
}