import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper Supabase Auth — remplace l'ancien système de tokens manuels
class StorageService {
  final _supabase = Supabase.instance.client;

  /// Données de l'utilisateur connecté (depuis Supabase Auth)
  Map<String, dynamic>? getUserData() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return {'id': user.id, 'email': user.email};
  }

  /// Vérifie si une session active existe
  bool hasToken() => _supabase.auth.currentUser != null;

  /// Déconnexion + nettoyage session
  Future<void> clearAll() async {
    await _supabase.auth.signOut();
  }
}