/// ⚠️  IMPORTANT — Ne jamais committer ce fichier avec de vrais identifiants
/// Crée un compte de test dédié dans ton projet Supabase
/// et mets les credentials ici uniquement en local.
///
/// Pour CI/CD Codemagic : injecter via variables d'environnement.

class TestCredentials {
  // ─── Compte de test principal ────────────────────────────────────
  static const String email    = 'test@otakuverse.dev';
  static const String password = 'Test1234!';

  // ─── Second compte (pour tester la messagerie) ───────────────────
  static const String email2    = 'test2@otakuverse.dev';
  static const String password2 = 'Test1234!';

  // ─── ID utilisateur test (pré-rempli après premier run) ──────────
  // Récupérable depuis Supabase dashboard
  static const String userId  = 'af0cefd2-db61-4766-ac80-bd51c50d83d0';
  static const String userId2 = '33d921e8-f352-494a-ab15-c6c70b6b742e';
}