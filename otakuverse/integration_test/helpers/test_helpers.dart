import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/main.dart' as app;
import 'test_credentials.dart';

// ─── Helpers globaux ─────────────────────────────────────────────────

class TestHelpers {

  /// Lance l'app et attend le chargement initial
  static Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Connexion avec le compte de test
  static Future<void> login(WidgetTester tester) async {
    await _waitFor(tester, find.byKey(AppKeys.emailField),
        timeout: const Duration(seconds: 10));

    await tester.enterText(
        find.byKey(AppKeys.emailField), TestCredentials.email);
    await tester.enterText(
        find.byKey(AppKeys.passwordField), TestCredentials.password);
    await tester.tap(find.byKey(AppKeys.loginButton));

    // Attendre la navigation vers le feed
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }

  /// Déconnexion
  static Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.byKey(AppKeys.bottomNavProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.logoutButton));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Aller sur un onglet de la bottom nav
  static Future<void> goToTab(WidgetTester tester, Key tabKey) async {
    await tester.tap(find.byKey(tabKey));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Attendre qu'un widget apparaisse (avec timeout)
  static Future<void> _waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (finder.evaluate().isNotEmpty) return;
    }
    expect(finder, findsOneWidget,
        reason: 'Widget non trouvé dans le délai imparti');
  }

  /// Scroller vers le bas dans une liste
  static Future<void> scrollDown(
      WidgetTester tester, Finder list,
      {double pixels = 300}) async {
    await tester.drag(list, Offset(0, -pixels));
    await tester.pumpAndSettle();
  }

  /// Scroller vers le haut
  static Future<void> scrollUp(
      WidgetTester tester, Finder list,
      {double pixels = 300}) async {
    await tester.drag(list, Offset(0, pixels));
    await tester.pumpAndSettle();
  }

  /// Vérifier qu'un snackbar apparaît avec un texte donné
  static void expectSnackbar(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Appuyer sur le bouton retour
  static Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}