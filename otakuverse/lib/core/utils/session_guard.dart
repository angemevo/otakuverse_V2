import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utilitaire pour accéder à currentUser de façon sécurisée.
///
/// Remplace tous les `.currentUser!.id` par
/// `SessionGuard.uid` avec redirection automatique si session expirée.
class SessionGuard {
  static final _supabase = Supabase.instance.client;

  /// Retourne l'UID courant ou null si non connecté.
  static String? get uid => _supabase.auth.currentUser?.id;

  /// Retourne l'UID ou lève une exception métier + redirige vers login.
  /// ✅ À utiliser dans les services qui NE PEUVENT PAS fonctionner sans session.
  static String get requiredUid {
    final id = uid;
    if (id == null) {
      // ✅ Redirection vers login sans crash
      _redirectToLogin();
      // ✅ Exception propre (pas un NPE brutal)
      throw const SessionExpiredException();
    }
    return id;
  }

  /// Vérifie si une session active est présente.
  static bool get isLoggedIn => uid != null;

  /// Redirige vers login si pas de session.
  static void requireAuth() {
    if (!isLoggedIn) _redirectToLogin();
  }

  static void _redirectToLogin() {
    // ✅ Ferme toutes les routes et retourne au splash/login
    if (Get.context != null) {
      Get.offAllNamed('/');
    }
  }
}

/// Exception propre pour session expirée (vs NullPointerException).
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Session expirée']);

  @override
  String toString() => 'SessionExpiredException: $message';
}
