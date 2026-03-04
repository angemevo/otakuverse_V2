import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class ExploreService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  static const _select =
      '*, profiles!inner(username, display_name, avatar_url)';

  // ─── POSTS TENDANCE ──────────────────────────────────────────────
  Future<List<PostModel>> getTrendingPosts({
    int    offset = 0,
    String? genre,
  }) async {
    var query = _supabase
        .from('posts')
        .select(_select);

    // ✅ Filtre par genre si sélectionné
    if (genre != null && genre.isNotEmpty) {
      query = query.ilike('caption', '%$genre%');
    }

    final data = await query
        .order('likes_count',  ascending: false)
        .order('created_at',   ascending: false)
        .range(offset, offset + 19);

    final posts = (data as List)
        .map((e) => PostModel.fromJson(e))
        .toList();

    return _attachLikes(posts);
  }

  // ─── ATTACHER LES LIKES ──────────────────────────────────────────
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
}