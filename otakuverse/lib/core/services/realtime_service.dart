import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';

class RealtimeService extends GetxService {
  static RealtimeService get to =>
      Get.find<RealtimeService>();

  final _supabase = Supabase.instance.client;

  RealtimeChannel? _postsChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _commentsChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _bookmarksChannel;
  VoidCallback? onNewPost;

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

    debugPrint(
        '✅ Realtime: tous les channels actifs');
  }

  // ─── POSTS ───────────────────────────────────────────────────────
  Future<void> _subscribePostsChannel() async {
    _postsChannel = _supabase
        .channel('public:posts')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'posts',
          callback: (_) {
            debugPrint('🆕 Realtime: nouveau post');
            _refreshFeed();
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'posts',
          callback: (_) {
            debugPrint('🆕 Realtime: nouveau post');
            // ✅ Notifier HomeScreen → afficher le badge
            onNewPost?.call();
            _refreshFeed();
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'posts',
          callback: (payload) {
            debugPrint('🗑 Realtime: post supprimé');
            // ✅ Retirer du feed immédiatement
            final deletedId =
                payload.oldRecord['id'] as String?;
            if (deletedId != null) {
              _removePostFromFeed(deletedId);
            }
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
        );

    await _postsChannel!.subscribe();
  }

  // ─── LIKES ───────────────────────────────────────────────────────
  Future<void> _subscribeLikesChannel() async {
    _likesChannel = _supabase
        .channel('public:likes')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'likes',
          callback: (payload) {
            final postId =
                payload.newRecord['post_id']
                    as String?;
            _updatePostLike(postId, delta: 1);
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'likes',
          callback: (payload) {
            final postId =
                payload.oldRecord['post_id']
                    as String?;
            _updatePostLike(postId, delta: -1);
          },
        );

    await _likesChannel!.subscribe();
  }

  // ─── COMMENTAIRES ────────────────────────────────────────────────
  Future<void> _subscribeCommentsChannel() async {
    _commentsChannel = _supabase
        .channel('public:comments')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'comments',
          callback: (payload) {
            final postId =
                payload.newRecord['post_id']
                    as String?;
            _updatePostComments(postId, delta: 1);
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'comments',
          callback: (payload) {
            final postId =
                payload.oldRecord['post_id']
                    as String?;
            _updatePostComments(postId, delta: -1);
          },
        );

    await _commentsChannel!.subscribe();
  }

  // ─── FOLLOWS ─────────────────────────────────────────────────────
  // ✅ Pas de ProfileController → le profil gère
  // lui-même son Realtime dans ProfileScreen
  Future<void> _subscribeFollowsChannel(
      String userId) async {
    _followsChannel = _supabase
        .channel('public:follows:$userId')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'follows',
          callback: (_) {
            debugPrint(
                '👤 Realtime: nouveau follow');
            // ✅ ProfileScreen gère le refresh
            // via son propre channel Realtime
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'follows',
          callback: (_) {
            debugPrint(
                '👤 Realtime: unfollow');
          },
        );

    await _followsChannel!.subscribe();
  }

  // ─── BOOKMARKS ───────────────────────────────────────────────────
  Future<void> _subscribeBookmarksChannel(
      String userId) async {
    _bookmarksChannel = _supabase
        .channel('public:bookmarks:$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'bookmarks',
          // ✅ PostgresChangeFilter — plus de String
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (_) {
            debugPrint(
                '🔖 Realtime: bookmark ajouté');
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
            debugPrint(
                '🔖 Realtime: bookmark retiré');
            _refreshBookmarks();
          },
        );

    await _bookmarksChannel!.subscribe();
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────
  void _refreshFeed() {
    try {
      Get.find<PostsController>().refreshFeed();
    } catch (_) {}
  }

  void _removePostFromFeed(String postId) {
    try {
      final ctrl = Get.find<PostsController>();
      ctrl.posts.removeWhere((p) => p.id == postId);
    } catch (_) {}
  }

  void _refreshBookmarks() {
    try {
      Get.find<PostsController>().refreshBookmarks();
    } catch (_) {}
  }

  void _updatePostLike(
      String? postId, {required int delta}) {
    if (postId == null) return;
    try {
      Get.find<PostsController>()
          .updatePostLikeCount(
              postId: postId, delta: delta);
    } catch (_) {}
  }

  void _updatePostComments(
      String? postId, {required int delta}) {
    if (postId == null) return;
    try {
      Get.find<PostsController>()
          .updatePostCommentCount(
              postId: postId, delta: delta);
    } catch (_) {}
  }

  // ─── DISPOSE ─────────────────────────────────────────────────────
  Future<void> disposeChannels() async {
    await _postsChannel?.unsubscribe();
    await _likesChannel?.unsubscribe();
    await _commentsChannel?.unsubscribe();
    await _followsChannel?.unsubscribe();
    await _bookmarksChannel?.unsubscribe();
    debugPrint('🔴 Realtime: channels fermés');
  }

  @override
  void onClose() {
    disposeChannels();
    super.onClose();
  }
}