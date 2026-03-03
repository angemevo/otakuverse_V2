import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ─── LECTURE ─────────────────────────────────────────────────────
  Future<ProfileModel> getMyProfile() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', _uid)
        .single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> getProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return ProfileModel.fromJson(data);
  }

  // ─── MISE À JOUR COMPLÈTE ────────────────────────────────────────
  Future<ProfileModel> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? website,
    String? gender,
    String? avatarUrl,
    String? bannerUrl,
    String? location,
    DateTime? birthDate,
    bool? isPrivate,
    List<String>? favoriteAnimes,
    List<String>? favoriteMangas,
    List<String>? favoriteGames,
    List<String>? favoriteGenres,
  }) async {
    // ✅ Construit uniquement les champs non-null
    final updates = <String, dynamic>{
      if (username != null)       'username':       username.toLowerCase().trim(),
      if (displayName != null)    'display_name':   displayName,
      if (bio != null)            'bio':            bio,
      if (website != null)        'website':        website,
      if (gender != null)         'gender':         gender,
      if (avatarUrl != null)      'avatar_url':     avatarUrl,
      if (bannerUrl != null)      'banner_url':     bannerUrl,
      if (location != null)       'location':       location,
      if (isPrivate != null)      'is_private':     isPrivate,
      if (birthDate != null)
        'birth_date': birthDate.toIso8601String().split('T').first,
      if (favoriteAnimes != null) 'favorite_anime':  favoriteAnimes,
      if (favoriteMangas != null) 'favorite_manga':  favoriteMangas,
      if (favoriteGames != null)  'favorite_games':  favoriteGames,
      if (favoriteGenres != null) 'favorite_genres': favoriteGenres,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (updates.length == 1) {
      // Seulement updated_at — rien à faire
      return getMyProfile();
    }

    final data = await _supabase
        .from('profiles')
        .update(updates)
        .eq('user_id', _uid)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }

  // ─── VIDER UN CHAMP (ex: supprimer la bio) ───────────────────────
  Future<ProfileModel> clearField(String fieldName) async {
    final data = await _supabase
        .from('profiles')
        .update({
          fieldName:    null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', _uid)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }

  // ─── RECHERCHE PAR USERNAME ──────────────────────────────────────
  Future<List<ProfileModel>> searchProfiles(String query) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);
    return (data as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}