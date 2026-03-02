import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class PostRepository {
  final _supabase = Supabase.instance.client;

  Future<List<PostModel>> getFeedPosts({int limit = 20, int offset = 0}) async {
    final response = await _supabase
        .from('posts')
        .select('*, profiles(*), likes_count, comments_count')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => PostModel.fromJson(e)).toList();
  }

  Future<PostModel> createPost(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('posts')
        .insert(data)
        .select()
        .single();
    return PostModel.fromJson(response);
  }

  Future<void> likePost(String postId) async {
    await _supabase.from('likes').insert({
      'post_id': postId,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  Future<void> unlikePost(String postId) async {
    await _supabase.from('likes').delete().match({
      'post_id': postId,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }
}