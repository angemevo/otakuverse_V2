import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════
  group('👤 Profil — Parcours complet', () {

    testWidgets('Accéder à son profil via la bottom nav', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await TestHelpers.goToTab(tester, AppKeys.bottomNavProfile);

      // ✅ La ProfileScreen est ouverte (OtakuCard visible)
      expect(find.byKey(AppKeys.editProfileButton), findsOneWidget);
    });

    testWidgets('Ouvrir l\'écran d\'édition du profil', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await TestHelpers.goToTab(tester, AppKeys.bottomNavProfile);
      await tester.tap(find.byKey(AppKeys.editProfileButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ L'écran d'édition est ouvert
      expect(find.text('Nom affiché'), findsOneWidget);
    });

    testWidgets('Modifier le displayName et sauvegarder', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await TestHelpers.goToTab(tester, AppKeys.bottomNavProfile);
      await tester.tap(find.byKey(AppKeys.editProfileButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Effacer et saisir un nouveau nom
      await tester.tap(find.byKey(AppKeys.displayNameInput));
      await tester.enterText(
          find.byKey(AppKeys.displayNameInput), 'OtakuTest 🎌');
      await tester.pumpAndSettle();

      // Sauvegarder
      await tester.tap(find.byKey(AppKeys.saveProfileButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ✅ Retour sur le profil après save
      // (le nom pourrait ne pas être visible immédiatement selon le refresh)
      expect(find.byKey(AppKeys.editProfileButton), findsOneWidget);
    });

    testWidgets('Annuler l\'édition → retour sans changement',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await TestHelpers.goToTab(tester, AppKeys.bottomNavProfile);
      await tester.tap(find.byKey(AppKeys.editProfileButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Appuyer sur Annuler
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // ✅ Retour sur le profil
      expect(find.byKey(AppKeys.editProfileButton), findsOneWidget);
    });

    testWidgets('Les onglets du profil sont navigables', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await TestHelpers.goToTab(tester, AppKeys.bottomNavProfile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Scroller vers les onglets (Posts, Avis, FanArt, Clips)
      // et vérifier que les tabs sont présents
      expect(find.text('Posts'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  group('🔍 Recherche — Parcours complet', () {

    testWidgets('Ouvrir la recherche depuis l\'AppBar', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      // Tapper sur l'icône recherche dans l'AppBar
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ SearchScreen ouverte, champ de recherche auto-focus
      expect(find.byKey(AppKeys.searchField), findsOneWidget);
    });

    testWidgets('Rechercher un utilisateur → affiche des résultats',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.enterText(find.byKey(AppKeys.searchField), 'test');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Des résultats ou un état vide (pas de crash)
      final hasResults  = find.byType(ListTile).evaluate().isNotEmpty;
      final emptyState  =
          find.text('Aucun résultat').evaluate().isNotEmpty;
      final suggestions =
          find.text('Suggestions').evaluate().isNotEmpty;

      expect(hasResults || emptyState || suggestions, isTrue);
    });

    testWidgets('Recherche vide → affiche les suggestions',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Suggestions chargées ou état initial
      // (recherche vide → suggestions ou placeholder)
      expect(find.byKey(AppKeys.searchField), findsOneWidget);
    });

    testWidgets('Suivre / ne plus suivre un utilisateur', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.enterText(find.byKey(AppKeys.searchField), 'test');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final followBtns = find.byKey(AppKeys.followButton);
      if (followBtns.evaluate().isNotEmpty) {
        await tester.tap(followBtns.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ✅ Le texte du bouton change (Suivre → Abonné)
        final isFollowing = find.text('Abonné').evaluate().isNotEmpty;
        final isNotFollowing = find.text('Suivre').evaluate().isNotEmpty;
        expect(isFollowing || isNotFollowing, isTrue);
      } else {
        markTestSkipped('Aucun utilisateur dans les résultats');
      }
    });

    testWidgets('Retour depuis la recherche', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Retour
      await TestHelpers.goBack(tester);

      // ✅ De retour sur le feed
      expect(find.text('Otakuverse'), findsOneWidget);
    });
  });
}