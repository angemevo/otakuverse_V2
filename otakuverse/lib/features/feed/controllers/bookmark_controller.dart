import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/services/bookmark_service.dart';

class BookmarkController extends GetxController {
  final _service = BookmarkService();

  // ─── State ───────────────────────────────────────────────────────
  final RxSet<String>     bookmarkedIds  = <String>{}.obs;
  final RxList<PostModel> bookmarkedPosts = <PostModel>[].obs;
  final RxBool            isLoading      = false.obs;
  final RxBool            isLoadingMore  = false.obs;
  final RxBool            hasMore        = true.obs;

  // ─── Pagination ──────────────────────────────────────────────────
  int              _offset   = 0;
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    _loadBookmarkedIds();
  }

  // ─── CHARGER les IDs au démarrage ────────────────────────────────
  // ✅ Pour savoir quels posts sont bookmarkés sans charger tous les posts
  Future<void> _loadBookmarkedIds() async {
    try {
      final ids = await _service.getBookmarkedIds();
      bookmarkedIds.assignAll(ids);
    } catch (e) {
      debugPrint('🔴 Erreur _loadBookmarkedIds : $e');
    }
  }

  // ─── CHARGER les posts bookmarkés ────────────────────────────────
  Future<void> loadBookmarks() async {
    isLoading.value = true;
    _offset         = 0;
    hasMore.value   = true;

    try {
      final result =
          await _service.getBookmarkedPosts(offset: 0);
      bookmarkedPosts.assignAll(result);
      if (result.length < _pageSize) hasMore.value = false;
      _offset = result.length;
    } catch (e) {
      debugPrint('🔴 Erreur loadBookmarks : $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CHARGER la page suivante ────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final result = await _service.getBookmarkedPosts(
          offset: _offset);
      if (result.isEmpty || result.length < _pageSize) {
        hasMore.value = false;
      }
      bookmarkedPosts.addAll(result);
      _offset += result.length;
    } catch (e) {
      debugPrint('🔴 Erreur loadMore bookmarks : $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── TOGGLE bookmark ─────────────────────────────────────────────
  Future<void> toggleBookmark(String postId) async {
    // ✅ Optimistic update
    final wasBookmarked = bookmarkedIds.contains(postId);

    if (wasBookmarked) {
      bookmarkedIds.remove(postId);
      bookmarkedPosts.removeWhere((p) => p.id == postId);
    } else {
      bookmarkedIds.add(postId);
    }

    try {
      await _service.toggleBookmark(postId);
    } catch (e) {
      // ✅ Rollback
      if (wasBookmarked) {
        bookmarkedIds.add(postId);
      } else {
        bookmarkedIds.remove(postId);
        bookmarkedPosts.removeWhere((p) => p.id == postId);
      }
      debugPrint('🔴 Erreur toggleBookmark : $e');
    }
  }

  // ✅ Vérifier si un post est bookmarké
  bool isBookmarked(String postId) =>
      bookmarkedIds.contains(postId);
}
