import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  static const _webClientId =
      '454205633639-nq9867mh55krd66hk5dqqa703rih1bel.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes:         ['email', 'profile'],
    serverClientId: _webClientId,
  );

  /// Connexion Google → Supabase.
  ///
  /// Retourne [null] si l'utilisateur annule le sélecteur de compte.
  /// Lance une exception en cas d'erreur réelle.
  Future<AuthResponse?> signInWithGoogle() async {
    // 1. Ouvrir le sélecteur de compte Google
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // annulé par l'utilisateur

    // 2. Récupérer les tokens OAuth
    final googleAuth = await googleUser.authentication;

    final idToken     = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception(
        'Google Sign-In : idToken manquant. '
        'Vérifie la configuration OAuth dans Google Cloud Console '
        '(clientId web requis dans google-services.json).',
      );
    }

    // 3. Authentifier avec Supabase via le token Google
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider:    OAuthProvider.google,
      idToken:     idToken,
      accessToken: accessToken,
    );

    return response;
  }

  /// Déconnexion Google (à appeler en complément de Supabase.auth.signOut)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  bool get isSignedIn => _googleSignIn.currentUser != null;
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
