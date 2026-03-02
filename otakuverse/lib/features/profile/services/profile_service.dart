import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<ProfileModel> getMyProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
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

  Future<ProfileModel> updateProfile({
    String? displayName,
    String? bio,
    String? website,
    String? gender,
    String? avatarUrl,
    String? bannerUrl,
    String? location,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase.from('profiles').update({
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      if (gender != null) 'gender': gender,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (location != null) 'location': location,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).select().single();

    return ProfileModel.fromJson(data);
  }
}