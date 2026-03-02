import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Se connecter avec Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🔵 Début Google Sign-In...');

      // Déclencher le flow de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️  Connexion Google annulée');
        return null;
      }

      print('✅ Utilisateur Google: ${googleUser.email}');

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('✅ Token Google obtenu');

      // Retourner les infos utilisateur
      return {
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      return null;
    }
  }

  /// Se déconnecter de Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Déconnexion Google réussie');
    } catch (e) {
      print('❌ Erreur déconnexion Google: $e');
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Obtenir l'utilisateur actuel
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}