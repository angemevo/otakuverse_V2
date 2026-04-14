import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/auth/controllers/auth_controller.dart';
import 'package:otakuverse/features/auth/repositories/auth_repository.dart';
import 'package:otakuverse/shared/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

// ─── Stub configurable ────────────────────────────────────────────────────────
// Évite les problèmes de null-safety de mockito avec les String non-nullables.

class _StubAuthRepository implements AuthRepository {
  UserModel?  returnUser;
  Exception?  throwError;
  bool        usernameTaken = false;

  @override
  bool  get isLoggedIn      => false;
  @override
  User? get currentAuthUser => null;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (throwError != null) throw throwError!;
    return returnUser!;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    if (throwError != null) throw throwError!;
    return returnUser!;
  }

  @override
  Future<bool> isUsernameTaken(String username) async => usernameTaken;

  @override
  Future<void> signOut() async {}
}

// ─── Helper ──────────────────────────────────────────────────────────────────

UserModel _fakeUser({String id = 'user-001', String username = 'testuser'}) =>
    UserModel(
      id:             id,
      username:       username,
      createdAt:      DateTime(2024),
      updatedAt:      DateTime(2024),
      followersCount: 0,
      followingCount: 0,
      postsCount:     0,
      isVerified:     false,
      isPrivate:      false,
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // Required so Get.offAllNamed does not crash outside of a Flutter app
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late _StubAuthRepository stub;
  late AuthController      ctrl;

  setUp(() {
    Get.testMode = true;
    stub = _StubAuthRepository();
    ctrl = AuthController(stub);
  });

  tearDown(Get.reset);

  // ─── État initial ─────────────────────────────────────────────────

  group('état initial', () {
    test('isLoading est false', () {
      expect(ctrl.isLoading.value, isFalse);
    });

    test('errorMessage est vide', () {
      expect(ctrl.errorMessage.value, '');
    });

    test('currentUser est null', () {
      expect(ctrl.currentUser.value, isNull);
    });
  });

  // ─── signIn ───────────────────────────────────────────────────────

  group('signIn', () {
    test('succès → currentUser mis à jour, erreur vide', () async {
      stub.returnUser = _fakeUser();

      await ctrl.signIn(email: 'test@example.com', password: 'password123');

      expect(ctrl.currentUser.value, equals(stub.returnUser));
      expect(ctrl.errorMessage.value, '');
      expect(ctrl.isLoading.value,    isFalse);
    });

    test('succès → isLoading revient à false', () async {
      stub.returnUser = _fakeUser();
      await ctrl.signIn(email: 'x@x.com', password: 'pass');
      expect(ctrl.isLoading.value, isFalse);
    });

    test('credentials invalides → message d\'erreur approprié', () async {
      stub.throwError = Exception('Invalid login credentials');

      await ctrl.signIn(email: 'bad@example.com', password: 'wrong');

      expect(ctrl.errorMessage.value, 'Email ou mot de passe incorrect');
      expect(ctrl.currentUser.value,  isNull);
      expect(ctrl.isLoading.value,    isFalse);
    });

    test('erreur réseau → message réseau', () async {
      stub.throwError = Exception('NetworkException: no connection');

      await ctrl.signIn(email: 'x@x.com', password: 'pass');

      expect(ctrl.errorMessage.value, 'Pas de connexion internet');
    });

    test('erreur inconnue → message générique', () async {
      stub.throwError = Exception('some unexpected error xyz');

      await ctrl.signIn(email: 'x@x.com', password: 'pass');

      expect(ctrl.errorMessage.value, 'Une erreur est survenue, réessaie');
    });

    test('erreur rate limit → message rate limit', () async {
      stub.throwError = Exception('rate limit exceeded');

      await ctrl.signIn(email: 'x@x.com', password: 'pass');

      expect(ctrl.errorMessage.value,
          'Trop de tentatives. Réessaie dans quelques minutes');
    });
  });

  // ─── signUp ───────────────────────────────────────────────────────

  group('signUp', () {
    test('username disponible → currentUser mis à jour', () async {
      stub.returnUser    = _fakeUser(username: 'newuser');
      stub.usernameTaken = false;

      await ctrl.signUp(
        email:    'new@example.com',
        password: 'securepass',
        username: 'newuser',
      );

      expect(ctrl.currentUser.value, isNotNull);
      expect(ctrl.errorMessage.value, '');
    });

    test('username déjà pris → errorMessage, pas d\'appel signUp', () async {
      stub.usernameTaken = true;
      // returnUser intentionnellement null pour détecter tout appel à signUp

      await ctrl.signUp(
        email:    'new@example.com',
        password: 'pass',
        username: 'takenuser',
      );

      expect(ctrl.errorMessage.value, 'Ce nom d\'utilisateur est déjà pris');
      expect(ctrl.currentUser.value,  isNull);
    });

    test('erreur rate limit → message approprié', () async {
      stub.usernameTaken = false;
      stub.throwError    = Exception('over_email_send_rate_limit');

      await ctrl.signUp(
        email: 'x@x.com', password: 'pass', username: 'user',
      );

      expect(ctrl.errorMessage.value,
          'Trop de tentatives. Réessaie dans une heure');
    });

    test('"User already registered" → message compte existant', () async {
      stub.usernameTaken = false;
      stub.throwError    = Exception('User already registered');

      await ctrl.signUp(
        email: 'x@x.com', password: 'pass', username: 'user',
      );

      expect(ctrl.errorMessage.value, 'Un compte existe déjà avec cet email');
    });

    test('isLoading revient à false après erreur', () async {
      stub.usernameTaken = false;
      stub.throwError    = Exception('Error');

      await ctrl.signUp(
        email: 'x@x.com', password: 'pass', username: 'user',
      );

      expect(ctrl.isLoading.value, isFalse);
    });
  });

  // ─── _parseError — tous les cas ───────────────────────────────────

  group('_parseError (tous les cas via signIn)', () {
    Future<String> errorFor(String raw) async {
      stub.throwError = Exception(raw);
      await ctrl.signIn(email: 'x@x.com', password: 'x');
      return ctrl.errorMessage.value;
    }

    test('Invalid login credentials', () async {
      expect(await errorFor('Invalid login credentials'),
          'Email ou mot de passe incorrect');
    });

    test('User already registered', () async {
      expect(await errorFor('User already registered'),
          'Un compte existe déjà avec cet email');
    });

    test('Email already in use', () async {
      expect(await errorFor('Email already in use'),
          'Un compte existe déjà avec cet email');
    });

    test('Password should be', () async {
      expect(await errorFor('Password should be at least 6 chars'),
          'Mot de passe trop court (6 caractères minimum)');
    });

    test('Username already taken', () async {
      expect(await errorFor('Username already taken'),
          'Ce nom d\'utilisateur est déjà pris');
    });

    test('NetworkException', () async {
      expect(await errorFor('NetworkException: unreachable'),
          'Pas de connexion internet');
    });

    test('over_email_send_rate_limit', () async {
      expect(await errorFor('over_email_send_rate_limit'),
          'Trop de tentatives. Réessaie dans une heure');
    });

    test('rate limit', () async {
      expect(await errorFor('rate limit exceeded'),
          'Trop de tentatives. Réessaie dans quelques minutes');
    });

    test('23505 duplicate key', () async {
      expect(await errorFor('ERROR: 23505 duplicate key'),
          'Un compte existe déjà avec ces informations');
    });

    test('erreur inconnue → fallback générique', () async {
      expect(await errorFor('totally unknown error abc'),
          'Une erreur est survenue, réessaie');
    });
  });
}
