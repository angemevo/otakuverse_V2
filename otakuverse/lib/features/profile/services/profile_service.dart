import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/utils/session_guard.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // ✅ FIX — SessionGuard au lieu de currentUser!
  String get _uid => SessionGuard.requiredUid;

  // ─── LECTURE ─────────────────────────────────────────────────────

  Future<ProfileModel?> getMyProfile() async {
    try {
      // ✅ FIX — maybeSingle() au lieu de single()
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      debugPrint('[ProfileService] getMyProfile error: $e');
      return null;
    }
  }

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      // ✅ FIX — maybeSingle() au lieu de single()
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('[ProfileService] getProfile error: $e');
      return null;
    }
  }

  // ─── MISE À JOUR ─────────────────────────────────────────────────

  Future<ProfileModel?> updateProfile({
    String?       username,
    String?       displayName,
    String?       bio,
    String?       website,
    String?       gender,
    String?       avatarUrl,
    String?       bannerUrl,
    String?       location,
    DateTime?     birthDate,
    bool?         isPrivate,
    List<String>? favoriteAnimes,
    List<String>? favoriteMangas,
    List<String>? favoriteGames,
    List<String>? favoriteGenres,
  }) async {
    final updates = <String, dynamic>{
      if (username    != null) 'username':     username.toLowerCase().trim(),
      if (displayName != null) 'display_name': displayName,
      if (bio         != null) 'bio':          bio,
      if (website     != null) 'website':      website,
      if (gender      != null) 'gender':       gender,
      if (avatarUrl   != null) 'avatar_url':   avatarUrl,
      if (bannerUrl   != null) 'banner_url':   bannerUrl,
      if (location    != null) 'location':     location,
      if (isPrivate   != null) 'is_private':   isPrivate,
      if (birthDate   != null)
        'birth_date': birthDate.toIso8601String().split('T').first,
      if (favoriteAnimes  != null) 'favorite_anime':  favoriteAnimes,
      if (favoriteMangas  != null) 'favorite_manga':  favoriteMangas,
      if (favoriteGames   != null) 'favorite_games':  favoriteGames,
      if (favoriteGenres  != null) 'favorite_genres': favoriteGenres,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (updates.length == 1) return getMyProfile();

    try {
      // ✅ FIX — maybeSingle() au lieu de single()
      final data = await _supabase
          .from('profiles')
          .update(updates)
          .eq('user_id', _uid)
          .select()
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } on SessionExpiredException {
      rethrow;
    } catch (e) {
      debugPrint('[ProfileService] updateProfile error: $e');
      rethrow;
    }
  }

  // ─── VIDER UN CHAMP ──────────────────────────────────────────────

  Future<ProfileModel?> clearField(String fieldName) async {
    try {
      final data = await _supabase
          .from('profiles')
          .update({fieldName: null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', _uid)
          .select()
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('[ProfileService] clearField error: $e');
      return null;
    }
  }

  // ─── UPLOAD AVATAR ───────────────────────────────────────────────

  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    // ✅ FIX — Uint8List au lieu de List<int> + bytes as dynamic
    final path = 'avatars/$_uid.$ext';
    await _supabase.storage.from('avatars').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  // ─── UPLOAD BANNIÈRE ─────────────────────────────────────────────

  Future<String> uploadBanner(Uint8List bytes, String ext) async {
    // ✅ FIX — Uint8List au lieu de List<int> + bytes as dynamic
    final path = 'banners/$_uid.$ext';
    await _supabase.storage.from('banners').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return _supabase.storage.from('banners').getPublicUrl(path);
  }

  // ─── RECHERCHE ───────────────────────────────────────────────────

  Future<List<ProfileModel>> searchProfiles(String query) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);
      return (data as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ProfileService] searchProfiles error: $e');
      return [];
    }
  }
}