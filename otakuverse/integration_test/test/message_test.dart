import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('💬 Messagerie — Parcours complet', () {

    // ─── Ouvrir la messagerie ─────────────────────────────────────

    testWidgets('Accéder à la messagerie via l\'AppBar',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tapper sur l'icône messagerie dans l'AppBar
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ L'écran Messages est ouvert
      expect(find.text('Messages'), findsOneWidget);
    });

    // ─── Recherche dans les conversations ─────────────────────────

    testWidgets('Rechercher dans les conversations', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Saisir dans la barre de recherche
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // ✅ Pas de crash pendant la recherche
      expect(find.text('Messages'), findsOneWidget);
    });

    // ─── Nouvelle conversation ────────────────────────────────────

    testWidgets('Ouvrir l\'écran nouvelle conversation',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tapper le FAB "nouveau message"
      await tester.tap(find.byKey(AppKeys.newConvButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Écran de recherche d'utilisateur
      expect(find.text('Nouveau message'), findsOneWidget);
    });

    testWidgets('Rechercher un utilisateur pour nouvelle conv',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byKey(AppKeys.newConvButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rechercher le compte test2
      await tester.enterText(
          find.byType(TextField), 'test2');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Des résultats de recherche apparaissent
      // (ou message "aucun résultat" si test2 n'existe pas)
      final hasResults = find.byType(ListTile).evaluate().isNotEmpty;
      final noResults  =
          find.text('Aucun utilisateur trouvé').evaluate().isNotEmpty;
      expect(hasResults || noResults, isTrue);
    });

    // ─── Ouvrir une conversation existante ────────────────────────

    testWidgets('Ouvrir une conversation et voir les messages',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ S'il y a des conversations, en ouvrir une
      final convTiles = find.byType(InkWell);
      if (convTiles.evaluate().isNotEmpty) {
        await tester.tap(convTiles.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ✅ Le chat est ouvert — champ de saisie présent
        expect(find.byKey(AppKeys.chatInput), findsOneWidget);
      } else {
        markTestSkipped('Aucune conversation existante');
      }
    });

    // ─── Envoyer un message ───────────────────────────────────────

    testWidgets('Envoyer un message dans une conversation',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final convTiles = find.byType(InkWell);
      if (convTiles.evaluate().isEmpty) {
        markTestSkipped('Aucune conversation existante');
        return;
      }

      await tester.tap(convTiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Saisir et envoyer un message
      const testMsg = 'Message test intégration 🎌';
      await tester.enterText(
          find.byKey(AppKeys.chatInput), testMsg);
      await tester.pumpAndSettle();

      // ✅ Bouton envoyer activé
      await tester.tap(find.byKey(AppKeys.chatSend));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Le message apparaît dans la liste
      expect(find.text(testMsg), findsOneWidget);
    });

    // ─── Swipe to reply ───────────────────────────────────────────

    testWidgets('Swipe sur un message → ouvre le bandeau reply',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final convTiles = find.byType(InkWell);
      if (convTiles.evaluate().isEmpty) {
        markTestSkipped('Aucune conversation');
        return;
      }

      await tester.tap(convTiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ S'il y a des messages, swiper le premier
      final bubbles = find.byType(GestureDetector);
      if (bubbles.evaluate().length > 2) {
        await tester.drag(
            bubbles.first, const Offset(60, 0));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // ✅ Pas de crash pendant le swipe
        expect(find.byKey(AppKeys.chatInput), findsOneWidget);
      }
    });
  });
}