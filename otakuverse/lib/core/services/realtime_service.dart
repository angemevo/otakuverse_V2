import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';

class RealtimeService extends GetxService {
  static RealtimeService get to => Get.find<RealtimeService>();

  final _supabase = Supabase.instance.client;

  RealtimeChannel? _postsChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _commentsChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _bookmarksChannel;
  RealtimeChannel? _profileChannel;

  // ✅ Callbacks publics écoutés par les screens
  VoidCallback?                                     onNewPost;
  void Function(String rank, int level, int points)? onRankUpdated;

  // ─── INITIALISER ─────────────────────────────────────────────────

  Future<void> initialize() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    debugPrint('🔴 Realtime: initialisation...');

    await _subscribePostsChannel();
    await _subscribeLikesChannel();
    await _subscribeCommentsChannel();
    await _subscribeFollowsChannel(userId);
    await _subscribeBookmarksChannel(userId);
    await _subscribeProfileChannel(userId);

    debugPrint('✅ Realtime: tous les channels actifs');
  }

  // ─── POSTS ───────────────────────────────────────────────────────

  Future<void> _subscribePostsChannel() async {
    _postsChannel = _supabase
        .channel('realtime:posts')
        // ✅ FIX : un seul onInsert qui fait les deux actions
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'posts',
          callback: (_) {
            debugPrint('🆕 Realtime: nouveau post');
            onNewPost?.call();  // badge HomeScreen
            _refreshFeed();
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'posts',
          callback: (payload) {
            debugPrint('🗑 Realtime: post supprimé');
            final deletedId = payload.oldRecord['id'] as String?;
            if (deletedId != null) _removePostFromFeed(deletedId);
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.update,
          schema:   'public',
          table:    'posts',
          callback: (_) {
            debugPrint('✏️ Realtime: post modifié');
            _refreshFeed();
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 posts channel: $status ${error ?? ""}');
        });
  }

  // ─── LIKES ───────────────────────────────────────────────────────

  Future<void> _subscribeLikesChannel() async {
    _likesChannel = _supabase
        .channel('realtime:likes')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'likes',
          callback: (payload) {
            final postId = payload.newRecord['post_id'] as String?;
            _updatePostLike(postId, delta: 1);
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'likes',
          callback: (payload) {
            final postId = payload.oldRecord['post_id'] as String?;
            _updatePostLike(postId, delta: -1);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 likes channel: $status ${error ?? ""}');
        });
  }

  // ─── COMMENTAIRES ────────────────────────────────────────────────

  Future<void> _subscribeCommentsChannel() async {
    _commentsChannel = _supabase
        .channel('realtime:comments')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'comments',
          callback: (payload) {
            final postId = payload.newRecord['post_id'] as String?;
            _updatePostComments(postId, delta: 1);
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'comments',
          callback: (payload) {
            final postId = payload.oldRecord['post_id'] as String?;
            _updatePostComments(postId, delta: -1);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 comments channel: $status ${error ?? ""}');
        });
  }

  // ─── FOLLOWS ─────────────────────────────────────────────────────
  // ✅ ProfileScreen gère son propre channel follows pour le compteur
  // Ce channel reste pour les notifications globales si nécessaire

  Future<void> _subscribeFollowsChannel(String userId) async {
    _followsChannel = _supabase
        .channel('realtime:follows:$userId')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'follows',
          callback: (_) => debugPrint('👤 Realtime: nouveau follow'),
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'follows',
          callback: (_) => debugPrint('👤 Realtime: unfollow'),
        )
        .subscribe((status, [error]) {
          debugPrint('📡 follows channel: $status ${error ?? ""}');
        });
  }

  // ─── BOOKMARKS ───────────────────────────────────────────────────

  Future<void> _subscribeBookmarksChannel(String userId) async {
    _bookmarksChannel = _supabase
        .channel('realtime:bookmarks:$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'bookmarks',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (_) {
            debugPrint('🔖 Realtime: bookmark ajouté');
            _refreshBookmarks();
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.delete,
          schema: 'public',
          table:  'bookmarks',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (_) {
            debugPrint('🔖 Realtime: bookmark retiré');
            _refreshBookmarks();
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 bookmarks channel: $status ${error ?? ""}');
        });
  }

  // ─── PROFIL RANG ─────────────────────────────────────────────────
  // ✅ Source unique de vérité pour le rang
  // ProfileScreen écoute onRankUpdated — pas besoin de son propre channel

  Future<void> _subscribeProfileChannel(String userId) async {
    _profileChannel = _supabase
        // ✅ Nom unique — différent du channel de ProfileScreen
        .channel('realtime:profile:$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'profiles',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (payload) {
            final newRank  = payload.newRecord['otaku_rank']   as String?;
            final newLevel = payload.newRecord['otaku_level']  as int?;
            final newPts   = payload.newRecord['otaku_points'] as int?;

            if (newRank == null) return;

            debugPrint(
                '🏆 Realtime: rang → $newRank Lv.$newLevel ($newPts pts)');

            onRankUpdated?.call(newRank, newLevel ?? 0, newPts ?? 0);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 profile channel: $status ${error ?? ""}');
        });
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────

  void _refreshFeed() {
    try { Get.find<PostsController>().refreshFeed(); } catch (_) {}
  }

  void _removePostFromFeed(String postId) {
    try {
      Get.find<PostsController>().posts.removeWhere((p) => p.id == postId);
    } catch (_) {}
  }

  void _refreshBookmarks() {
    try { Get.find<PostsController>().refreshBookmarks(); } catch (_) {}
  }

  void _updatePostLike(String? postId, {required int delta}) {
    if (postId == null) return;
    try {
      Get.find<PostsController>()
          .updatePostLikeCount(postId: postId, delta: delta);
    } catch (_) {}
  }

  void _updatePostComments(String? postId, {required int delta}) {
    if (postId == null) return;
    try {
      Get.find<PostsController>()
          .updatePostCommentCount(postId: postId, delta: delta);
    } catch (_) {}
  }

  // ─── DISPOSE ─────────────────────────────────────────────────────

  Future<void> disposeChannels() async {
    await _postsChannel?.unsubscribe();
    await _likesChannel?.unsubscribe();
    await _commentsChannel?.unsubscribe();
    await _followsChannel?.unsubscribe();
    await _bookmarksChannel?.unsubscribe();
    await _profileChannel?.unsubscribe();
    debugPrint('🔴 Realtime: channels fermés');
  }

  @override
  void onClose() {
    disposeChannels();
    super.onClose();
  }
}
