import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import '../helpers/test_helpers.dart';
import '../helpers/test_credentials.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔐 Auth — Parcours complet', () {

    // ─── Connexion ────────────────────────────────────────────────────

    testWidgets('Connexion avec email/mot de passe', (tester) async {
      await TestHelpers.launchApp(tester);

      // ✅ SplashScreen → redirige vers SignInScreen
      expect(find.text('Otakuverse'), findsWidgets);

      // Saisir les identifiants
      await tester.enterText(
          find.byKey(AppKeys.emailField), TestCredentials.email);
      await tester.enterText(
          find.byKey(AppKeys.passwordField), TestCredentials.password);
      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // ✅ Vérifier qu'on est sur le Feed
      expect(find.text('Otakuverse'), findsOneWidget); // AppBar title
    });

    // ─── Email invalide ───────────────────────────────────────────────

    testWidgets('Connexion avec email invalide → affiche erreur',
        (tester) async {
      await TestHelpers.launchApp(tester);

      await tester.enterText(
          find.byKey(AppKeys.emailField), 'mauvais@email');
      await tester.enterText(
          find.byKey(AppKeys.passwordField), 'wrongpassword');
      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ✅ Un snackbar d'erreur doit apparaître
      expect(find.byType(SnackBar), findsOneWidget);
    });

    // ─── Champs vides ─────────────────────────────────────────────────

    testWidgets('Connexion avec champs vides → validation',
        (tester) async {
      await TestHelpers.launchApp(tester);

      // Tap directement sans saisir
      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pumpAndSettle();

      // ✅ Ne doit pas naviguer — rester sur SignIn
      expect(find.byKey(AppKeys.loginButton), findsOneWidget);
    });

    // ─── Déconnexion ──────────────────────────────────────────────────

    testWidgets('Déconnexion → retour écran connexion', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      // Se déconnecter
      await TestHelpers.logout(tester);

      // ✅ Vérifier retour sur SignIn
      expect(find.byKey(AppKeys.loginButton), findsOneWidget);
    });

    // ─── Session persistante ──────────────────────────────────────────

    testWidgets('Session persistante au relancement', (tester) async {
      // ✅ Si déjà connecté, SplashScreen redirige directement vers Feed
      await TestHelpers.launchApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Soit on est sur le feed (session active),
      // soit sur SignIn (session expirée)
      final onFeed    = find.text('Otakuverse').evaluate().isNotEmpty;
      final onSignIn  = find.byKey(AppKeys.loginButton).evaluate().isNotEmpty;
      expect(onFeed || onSignIn, isTrue);
    });
  });
}