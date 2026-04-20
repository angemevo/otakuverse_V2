import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class PostService {
  SupabaseClient get _supabase => Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;
  static const _select =
      '*, profiles!inner(username, display_name, avatar_url)';

  // ─── ATTACHER LES LIKES ──────────────────────────────────────────
  // ✅ Une seule requête pour tous les posts
  Future<List<PostModel>> _attachLikes(
      List<PostModel> posts) async {
    if (posts.isEmpty) return posts;

    final postIds = posts.map((p) => p.id).toList();
    final data    = await _supabase
        .from('likes')
        .select('post_id')
        .eq('user_id', _uid)
        .inFilter('post_id', postIds);

    final likedIds = (data as List)
        .map((e) => e['post_id'] as String)
        .toSet();

    return posts
        .map((p) => p.copyWith(
            isLiked: likedIds.contains(p.id)))
        .toList();
  }

  // ─── CRÉER UN POST ───────────────────────────────────────────────
  Future<PostModel> createPost({
    required String       caption,
    required List<String> mediaUrls,
    String? location,
    bool    allowComments    = true,
    String? musicTitle,
    String? musicArtist,
    String? musicTrackId,
    String? musicPreviewUrl,
    String? musicImageUrl,
    String? pollQuestion,
    String? pollOptionA,
    String? pollOptionB,
    int?    pollDurationHours,
  }) async {
    final pollExpiresAt = pollDurationHours != null
        ? DateTime.now().add(Duration(hours: pollDurationHours)).toIso8601String()
        : null;

    final data = await _supabase.from('posts').insert({
      'user_id':       _uid,
      'caption':       caption,
      'media_urls':    mediaUrls,
      'location':      ?location,
      'allow_comments': allowComments,
      'music_title':      musicTitle,
      'music_artist':     musicArtist,
      'music_track_id':   musicTrackId,
      'music_preview_url': musicPreviewUrl,
      'music_image_url':  musicImageUrl,
      'poll_question':       ?pollQuestion,
      'poll_option_a':       ?pollOptionA,
      'poll_option_b':       ?pollOptionB,
      'poll_duration_hours': ?pollDurationHours,
      'poll_expires_at':     ?pollExpiresAt,
    }).select(_select).single();

    return PostModel.fromJson(data);
  }

  // ─── IDs DES GENS QUE JE SUIS ───────────────────────────────────
  Future<List<String>> getFollowingIds(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    return (data as List)
        .map((e) => e['following_id'] as String)
        .toList();
  }

  // ─── FEED PRINCIPAL ──────────────────────────────────────────────
  Future<List<PostModel>> getFeed({int offset = 0}) async {
    final followingIds = await getFollowingIds(_uid);
    if (!followingIds.contains(_uid)) {
      followingIds.add(_uid);
    }

    final data = await _supabase
        .from('posts')
        .select(_select)
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false)
        .range(offset, offset + 19);

    var posts = (data as List)
        .map((e) => PostModel.fromJson(e))
        .toList();

    // ✅ Feed vide à la première page → découverte
    if (posts.isEmpty && offset == 0) {
      return _getDiscoveryFeed(
          excludeIds: followingIds, offset: offset);
    }

    // ✅ Attacher les likes
    return _attachLikes(posts);
  }

  // ─── FEED DE DÉCOUVERTE ──────────────────────────────────────────
  Future<List<PostModel>> _getDiscoveryFeed({
    List<String> excludeIds = const [],
    int          offset     = 0,
  }) async {
    final data = await _supabase
        .from('posts')
        .select(_select)
        .not('user_id', 'in', '(${excludeIds.join(',')})')
        .order('likes_count', ascending: false)
        .order('created_at',  ascending: false)
        .range(offset, offset + 19);

    final posts = (data as List)
        .map((e) => PostModel.fromJson(e))
        .toList();

    // ✅ Attacher les likes
    return _attachLikes(posts);
  }

  // ─── POSTS D'UN USER ─────────────────────────────────────────────
  Future<List<PostModel>> getPostsByUser(
    String userId, {
    int offset = 0,
  }) async {
    final data = await _supabase
        .from('posts')
        .select(_select)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + 19);

    final posts = (data as List)
        .map((e) => PostModel.fromJson(e))
        .toList();

    // ✅ Attacher les likes
    return _attachLikes(posts);
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  // ✅ Plus de RPC — le trigger SQL gère les compteurs
  Future<bool> toggleLike(String postId) async {
    final existing = await _supabase
        .from('likes')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', _uid)
          .eq('post_id', postId);
      return false;
    } else {
      await _supabase.from('likes').insert({
        'user_id': _uid,
        'post_id': postId,
      });
      return true;
    }
  }

  // ─── VÉRIFIER SI LIKÉ ────────────────────────────────────────────
  Future<bool> hasLiked(String postId) async {
    final data = await _supabase
        .from('likes')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();
    return data != null;
  }

  // ─── POSTS LIKÉS PAR UN USER ─────────────────────────────────────
  Future<List<PostModel>> getLikedPosts(String userId) async {
    final data = await _supabase
        .from('likes')
        .select(
          // ✅ Inclure le JOIN profiles dans les posts imbriqués
          'post:posts!post_id(*, profiles!inner(username, display_name, avatar_url))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final posts = (data as List)
        .where((e) => e['post'] != null)
        .map((e) => PostModel.fromJson(
            e['post'] as Map<String, dynamic>))
        .toList();

    // ✅ Attacher les likes
    return _attachLikes(posts);
  }

  // ─── MODIFIER UN POST ────────────────────────────────────────────
  Future<PostModel> updatePost({
    required String postId,
    String?         caption,
    String?         location,
    bool?           allowComments,
  }) async {
    final data = await _supabase
        .from('posts')
        .update({
          'caption':        ?caption,
          'location':       ?location,
          'allow_comments': ?allowComments,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select(_select)
        .single();

    return PostModel.fromJson(data);
  }

  // ─── SUPPRIMER UN POST ───────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // ─── ÉPINGLER UN POST ────────────────────────────────────────────
  Future<void> pinPost(
      String postId, {required bool isPinned}) async {
    await _supabase
        .from('posts')
        .update({'is_pinned': isPinned})
        .eq('id', postId);
  }

  // ─── INCRÉMENTER COMMENTAIRES ────────────────────────────────────
  Future<void> incrementComments(String postId) async {
    await _supabase.rpc('increment_comments',
        params: {'post_id': postId});
  }
}
