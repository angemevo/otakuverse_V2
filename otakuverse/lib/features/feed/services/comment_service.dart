import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';

class CommentService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  static const _select =
      '*, profiles(username, display_name, avatar_url)';

  // ─── RÉCUPÉRER les commentaires d'un post ────────────────────────
  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _supabase
        .from('comments')
        .select(_select)
        .eq('post_id', postId)
        .isFilter('parent_id', null) // ✅ Seulement les commentaires racine
        .order('created_at', ascending: true);

    final comments = (data as List)
        .map((e) => CommentModel.fromJson(e))
        .toList();

    // ✅ Charger les likes pour chaque commentaire
    return _attachLikes(comments);
  }

  // ─── RÉCUPÉRER les réponses d'un commentaire ─────────────────────
  Future<List<CommentModel>> getReplies(String parentId) async {
    final data = await _supabase
        .from('comments')
        .select(_select)
        .eq('parent_id', parentId)
        .order('created_at', ascending: true);

    final replies = (data as List)
        .map((e) => CommentModel.fromJson(e))
        .toList();

    return _attachLikes(replies);
  }

  // ─── AJOUTER un commentaire ───────────────────────────────────────
  Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final data = await _supabase
        .from('comments')
        .insert({
          'post_id':   postId,
          'user_id':   _uid,
          'content':   content.trim(),
          if (parentId != null) 'parent_id': parentId,
        })
        .select(_select)
        .single();

    return CommentModel.fromJson(data);
  }

  // ─── SUPPRIMER un commentaire ────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    await _supabase
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', _uid);
  }

  // ─── LIKER un commentaire ─────────────────────────────────────────
  Future<void> likeComment(String commentId) async {
    await _supabase.from('comment_likes').insert({
      'comment_id': commentId,
      'user_id':    _uid,
    });
  }

  // ─── UNLIKER un commentaire ───────────────────────────────────────
  Future<void> unlikeComment(String commentId) async {
    await _supabase
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id',    _uid);
  }

  // ─── VÉRIFIER si j'ai liké ───────────────────────────────────────
  Future<bool> hasLiked(String commentId) async {
    final data = await _supabase
        .from('comment_likes')
        .select('id')
        .eq('comment_id', commentId)
        .eq('user_id',    _uid)
        .maybeSingle();

    return data != null;
  }

  // ─── ATTACHER les likes à chaque commentaire ─────────────────────
  Future<List<CommentModel>> _attachLikes(
      List<CommentModel> comments) async {
    if (comments.isEmpty) return comments;

    final ids = comments.map((c) => c.id).toList();

    final liked = await _supabase
        .from('comment_likes')
        .select('comment_id')
        .eq('user_id', _uid)
        .inFilter('comment_id', ids);

    final likedIds = (liked as List)
        .map((e) => e['comment_id'] as String)
        .toSet();

    return comments.map((c) => c.copyWith(
      isLiked: likedIds.contains(c.id),
    )).toList();
  }
}