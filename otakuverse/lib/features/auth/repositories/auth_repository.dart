import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/shared/models/user_model.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // ─── INSCRIPTION ─────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username':                    username.toLowerCase().trim(),
        'display_name':              ?displayName,
      },
    );

    if (authResponse.user == null) {
      throw Exception('Échec de la création du compte');
    }

    final userId = authResponse.user!.id;

    // ✅ Attente fixe de 1.5s — le trigger est rapide, pas besoin de retry complexe
    await Future.delayed(const Duration(milliseconds: 1500));

    // ✅ Une seule tentative propre
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data != null) {
      print('✅ Profil créé par le trigger');
      return UserModel.fromProfile(ProfileModel.fromJson(data));
    }

    // ─── Fallback : upsert si trigger trop lent ───────────────────
    print('⚠️ Fallback upsert');
    final fallback = await _supabase
        .from('profiles')
        .upsert(
          {
            'user_id':         userId,
            'username':        username.toLowerCase().trim(),
            'email':           email,
            'display_name':    displayName,
            'favorite_anime':  [],
            'favorite_manga':  [],
            'favorite_games':  [],
            'favorite_genres': [],
            'followers_count': 0,
            'following_count': 0,
            'posts_count':     0,
            'is_private':      false,
            'is_verified':     false,
            'created_at':      DateTime.now().toIso8601String(),
            'updated_at':      DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id',
        )
        .select()
        .single();

    return UserModel.fromProfile(ProfileModel.fromJson(fallback));
  }

  // ─── CONNEXION ───────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Email ou mot de passe incorrect');
    }

    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', authResponse.user!.id)
        .single();

    return UserModel.fromJson(profileData);
  }

  // ─── DÉCONNEXION ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── VÉRIFIER UNICITÉ USERNAME ───────────────────────────────────
  Future<bool> isUsernameTaken(String username) async {
    final data = await _supabase
        .from('profiles')
        .select('username')
        .eq('username', username.toLowerCase().trim())
        .maybeSingle();
    return data != null;
  }

  // ─── SESSION ─────────────────────────────────────────────────────
  bool  get isLoggedIn      => _supabase.auth.currentUser != null;
  User? get currentAuthUser => _supabase.auth.currentUser;
}