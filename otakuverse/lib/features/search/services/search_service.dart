import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class SearchService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ─── RECHERCHE UTILISATEURS ──────────────────────────────────────
  Future<List<ProfileModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final data = await _supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .neq('user_id', _uid) // ✅ Exclure soi-même
        .limit(20);

    return (data as List)
        .map((e) => ProfileModel.fromJson(e))
        .toList();
  }

  // ─── SUGGESTIONS — utilisateurs populaires ───────────────────────
  Future<List<ProfileModel>> getSuggestions() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .neq('user_id', _uid)
        .order('followers_count', ascending: false)
        .limit(10);

    return (data as List)
        .map((e) => ProfileModel.fromJson(e))
        .toList();
  }
}