import 'package:get/get.dart';
import 'package:otakuverse/features/auth/repositories/auth_repository.dart';
import 'package:otakuverse/shared/models/user_model.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;

  AuthController(this._repository);

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentUser = Rxn<UserModel>();  // ✅ user observable partout

  @override
  void onInit() {
    super.onInit();
    _checkSession();  // ✅ vérif session au démarrage
  }

  // Vérification session existante
  void _checkSession() {
    if (_repository.isLoggedIn) {
      Get.offAllNamed('/home');
    }
  }

  // Connexion
  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      currentUser.value = await _repository.signIn(
        email: email,
        password: password,
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Inscription
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      currentUser.value = await _repository.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      Get.offAllNamed('/signup-success');
    } catch (e) {
      errorMessage.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _repository.signOut();
      currentUser.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      errorMessage.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Nettoyer les messages d'erreur lisibles
  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email';
    }
    if (msg.contains('Password should be')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return 'Une erreur est survenue, réessaie';
  }
}