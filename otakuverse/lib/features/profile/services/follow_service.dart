import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ─── SUIVRE ──────────────────────────────────────────────────────
  Future<void> follow(String targetUserId) async {
    await _supabase.from('follows').insert({
      'follower_id':  _uid,
      'following_id': targetUserId,
    });
  }

  // ─── SE DÉSABONNER ───────────────────────────────────────────────
  Future<void> unfollow(String targetUserId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id',  _uid)
        .eq('following_id', targetUserId);
  }

  // ─── EST-CE QUE JE SUIS ? ────────────────────────────────────────
  Future<bool> isFollowing(String targetUserId) async {
    final data = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id',  _uid)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return data != null;
  }

  // ─── TOGGLE (follow/unfollow en un appel) ────────────────────────
  Future<bool> toggleFollow(String targetUserId) async {
    final following = await isFollowing(targetUserId);
    if (following) {
      await unfollow(targetUserId);
      return false; // maintenant non-suivi
    } else {
      await follow(targetUserId);
      return true; // maintenant suivi
    }
  }

  // ─── LISTE — qui je suis ─────────────────────────────────────────
  Future<List<String>> getFollowingIds() async {
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', _uid);

    return (data as List)
        .map((e) => e['following_id'] as String)
        .toList();
  }

  // ─── LISTE — mes abonnés ─────────────────────────────────────────
  Future<List<String>> getFollowerIds(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);

    return (data as List)
        .map((e) => e['follower_id'] as String)
        .toList();
  }
}