import 'package:get/get.dart';
import 'package:otakuverse/core/services/push_notification_service.dart';
import 'package:otakuverse/features/auth/repositories/auth_repository.dart';
import 'package:otakuverse/shared/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final AuthRepository _repository;
  AuthController(this._repository);

  final isLoading    = false.obs;
  final errorMessage = ''.obs;
  final currentUser  = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  void _checkSession() {
    if (_repository.isLoggedIn) Get.offAllNamed('/home');
  }

  // ─── INSCRIPTION ─────────────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      // ✅ Vérifier unicité username avant d'appeler Supabase
      final taken = await _repository.isUsernameTaken(username);
      if (taken) {
        errorMessage.value = 'Ce nom d\'utilisateur est déjà pris';
        return;
      }

      currentUser.value = await _repository.signUp(
        email:       email,
        password:    password,
        username:    username,
        displayName: displayName,
      );

      Get.offAllNamed('/onboarding');
    } catch (e) {
      errorMessage.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── CONNEXION ───────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      currentUser.value = await _repository.signIn(
        email:    email,
        password: password,
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = _parseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── DÉCONNEXION ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await PushNotificationService.deleteToken();
    await Supabase.instance.client.auth.signOut();
    Get.offAllNamed('/login');
  }

  // ─── PARSE ERREURS SUPABASE ──────────────────────────────────────
  String _parseError(dynamic e) {
    print('🔴 ERREUR BRUTE : $e'); // ← retirer en production
    final msg = e.toString();
    if (msg.contains('Invalid login credentials'))  return 'Email ou mot de passe incorrect';
    if (msg.contains('User already registered'))    return 'Un compte existe déjà avec cet email';
    if (msg.contains('Email already in use'))       return 'Un compte existe déjà avec cet email';
    if (msg.contains('Password should be'))         return 'Mot de passe trop court (6 caractères minimum)';
    if (msg.contains('Username already taken'))     return 'Ce nom d\'utilisateur est déjà pris';
    if (msg.contains('NetworkException'))           return 'Pas de connexion internet';
    if (msg.contains('over_email_send_rate_limit'))      return 'Trop de tentatives. Réessaie dans une heure';
    if (msg.contains('rate limit'))                      return 'Trop de tentatives. Réessaie dans quelques minutes';
    if (msg.contains('23505'))                       return 'Un compte existe déjà avec ces informations';

    return 'Une erreur est survenue, réessaie';
  }
}