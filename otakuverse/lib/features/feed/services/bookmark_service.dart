// ignore_for_file: unused_field

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class BookmarkService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  static const _select =
      '*, profiles!inner(username, display_name, avatar_url)';

  // ─── AJOUTER un bookmark ─────────────────────────────────────────
  Future<void> addBookmark(String postId) async {
    await _supabase.from('bookmarks').insert({
      'user_id': _uid,
      'post_id': postId,
    });
  }

  // ─── SUPPRIMER un bookmark ───────────────────────────────────────
  Future<void> removeBookmark(String postId) async {
    await _supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', _uid)
        .eq('post_id', postId);
  }

  // ─── TOGGLE bookmark ─────────────────────────────────────────────
  Future<bool> toggleBookmark(String postId) async {
    final existing = await _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      await removeBookmark(postId);
      return false;
    } else {
      await addBookmark(postId);
      return true;
    }
  }

  // ─── VÉRIFIER si bookmarké ───────────────────────────────────────
  Future<bool> isBookmarked(String postId) async {
    final data = await _supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();
    return data != null;
  }

  // ─── RÉCUPÉRER les posts bookmarkés ─────────────────────────────
  Future<List<PostModel>> getBookmarkedPosts({
    int offset = 0,
  }) async {
    final data = await _supabase
        .from('bookmarks')
        .select('post:posts!post_id(${'*, profiles!inner(username, display_name, avatar_url)'})')
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .range(offset, offset + 19);

    return (data as List)
        .where((e) => e['post'] != null)
        .map((e) => PostModel.fromJson(
            e['post'] as Map<String, dynamic>))
        .toList();
  }

  // ─── IDs des posts bookmarkés ────────────────────────────────────
  // ✅ Pour initialiser l'état isBookmarked en batch
  Future<Set<String>> getBookmarkedIds() async {
    final data = await _supabase
        .from('bookmarks')
        .select('post_id')
        .eq('user_id', _uid);

    return (data as List)
        .map((e) => e['post_id'] as String)
        .toSet();
  }
}
