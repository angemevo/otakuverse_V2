import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/shared/models/user_model.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // ─── INSCRIPTION ────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    // 1. Créer le compte Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Échec de la création du compte');
    }

    final userId = authResponse.user!.id;
    final now = DateTime.now().toIso8601String();

    // 2. Créer le profil dans la table profiles
    final profileData = await _supabase
        .from('profiles')
        .insert({
          'id': userId,
          'email': email,
          'username': username,
          'display_name': displayName,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return UserModel.fromJson(profileData);
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

    // Récupérer le profil complet depuis la table profiles
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', authResponse.user!.id)
        .single();

    return UserModel.fromJson(profileData);
  }

  // ─── DÉCONNEXION ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── SESSION ─────────────────────────────────────────────────────
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // User Supabase Auth (pas le profil complet)
  User? get currentAuthUser => _supabase.auth.currentUser;
}