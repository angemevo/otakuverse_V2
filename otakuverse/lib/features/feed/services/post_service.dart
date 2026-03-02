import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class PostService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ─── CRÉER UN POST ───────────────────────────────────────────────
  Future<PostModel> createPost({
    required String caption,
    required List<String> mediaUrls,
    String? location,
    bool allowComments = true,
  }) async {
    final data = await _supabase.from('posts').insert({
      'user_id': _uid,
      'caption': caption,
      'media_urls': mediaUrls,
      if (location != null) 'location': location,
      'allow_comments': allowComments,
    }).select().single();

    return PostModel.fromJson(data);
  }

  // ─── FEED PRINCIPAL (tous les posts) ─────────────────────────────
  Future<List<PostModel>> getFeed({int limit = 20, int offset = 0}) async {
    final data = await _supabase
        .from('posts')
        .select('*, profiles(username, avatar_url)') // ← join
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ─── POSTS D'UN USER ─────────────────────────────────────────────
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final data = await _supabase
        .from('posts')
        .select('*, profiles(username, avatar_url)') // ← join
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => PostModel.fromJson(e)).toList();
  }

  // ─── TOGGLE LIKE ─────────────────────────────────────────────────
  /// Retourne true si liké, false si unliké
  Future<bool> toggleLike(String postId) async {
    final existing = await _supabase
        .from('likes')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('likes')
          .delete()
          .eq('user_id', _uid)
          .eq('post_id', postId);
      await _supabase.rpc('decrement_likes', params: {'post_id': postId});
      return false;
    } else {
      await _supabase.from('likes').insert({
        'user_id': _uid,
        'post_id': postId,
      });
      await _supabase.rpc('increment_likes', params: {'post_id': postId});
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

  // ─── POSTS LIKÉS PAR UN USER ──────────────────────────────────────
  Future<List<PostModel>> getLikedPosts(String userId) async {
    final data = await _supabase
        .from('likes')
        .select('posts(*)')
        .eq('user_id', userId);

    return (data as List)
        .where((e) => e['posts'] != null)
        .map((e) => PostModel.fromJson(e['posts'] as Map<String, dynamic>))
        .toList();
  }

  // ─── MODIFIER UN POST ─────────────────────────────────────────────
  Future<PostModel> updatePost({
    required String postId,
    String? caption,
    String? location,
    bool? allowComments,
  }) async {
    final data = await _supabase.from('posts').update({
      if (caption != null) 'caption': caption,
      if (location != null) 'location': location,
      if (allowComments != null) 'allow_comments': allowComments,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId).select().single();

    return PostModel.fromJson(data);
  }

  // ─── SUPPRIMER UN POST ────────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // ─── ÉPINGLER UN POST ─────────────────────────────────────────────
  Future<void> pinPost(String postId, {required bool isPinned}) async {
    await _supabase.from('posts')
        .update({'is_pinned': isPinned})
        .eq('id', postId);
  }

  // ─── INCRÉMENTER COMMENTAIRES ────────────────────────────────────
  Future<void> incrementComments(String postId) async {
    await _supabase.rpc('increment_comments', params: {'post_id': postId});
  }
}