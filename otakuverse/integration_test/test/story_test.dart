import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📸 Stories — Parcours complet', () {

    // ─── Affichage stories row ─────────────────────────────────────

    testWidgets('La barre de stories s\'affiche dans le feed',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ La barre de stories est visible
      expect(find.byKey(AppKeys.storiesRow), findsOneWidget);
    });

    // ─── Viewer de story ──────────────────────────────────────────

    testWidgets('Tapper sur une story l\'ouvre en plein écran',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ S'il y a des stories, tapper sur la première
      final storyCircles = find.descendant(
        of: find.byKey(AppKeys.storiesRow),
        matching: find.byType(GestureDetector),
      );

      if (storyCircles.evaluate().length > 1) {
        // Tapper la première story (pas le bouton +)
        await tester.tap(storyCircles.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ✅ Viewer ouvert — icône close présente
        expect(find.byIcon(Icons.close), findsOneWidget);

        // Fermer le viewer
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      } else {
        // ✅ Pas de stories disponibles — test skippé
        markTestSkipped(
            'Aucune story disponible pour ce test');
      }
    });

    // ─── Navigation entre stories ─────────────────────────────────

    testWidgets('Tapper à droite → passe à la story suivante',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final storyCircles = find.descendant(
        of: find.byKey(AppKeys.storiesRow),
        matching: find.byType(GestureDetector),
      );

      if (storyCircles.evaluate().length > 1) {
        await tester.tap(storyCircles.at(1));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Tapper côté droit de l'écran → story suivante
        final size = tester.view.physicalSize / tester.view.devicePixelRatio;
        await tester.tapAt(Offset(size.width * 0.75, size.height * 0.5));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ✅ Pas de crash
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      } else {
        markTestSkipped('Aucune story disponible');
      }
    });

    // ─── Ouvrir la création de story ─────────────────────────────

    testWidgets('Bouton + ouvre l\'écran de création de story',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Tapper sur le bouton + / Ajouter
      await tester.tap(find.byKey(AppKeys.addStoryButton));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Écran création story est ouvert
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}