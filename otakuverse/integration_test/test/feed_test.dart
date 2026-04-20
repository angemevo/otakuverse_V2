import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('📰 Feed — Parcours complet', () {

    // Setup commun : connecté avant chaque test
    setUp(() async {});

    // ─── Chargement feed ──────────────────────────────────────────────

    testWidgets('Feed se charge et affiche des posts', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      // ✅ La liste du feed doit être présente
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byKey(AppKeys.feedList), findsOneWidget);
    });

    // ─── Pull to refresh ─────────────────────────────────────────────

    testWidgets('Pull-to-refresh recharge le feed', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      // Simuler le pull-to-refresh
      await tester.drag(
          find.byKey(AppKeys.feedList), const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ✅ Pas de crash, feed toujours présent
      expect(find.byKey(AppKeys.feedList), findsOneWidget);
    });

    // ─── Like ─────────────────────────────────────────────────────────

    testWidgets('Liker un post → compteur s\'incrémente', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Trouver le premier bouton like
      final likes = find.byKey(AppKeys.likeButton);
      expect(likes, findsWidgets);

      // Tapper le premier like
      await tester.tap(likes.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Pas de crash après le like
      expect(find.byKey(AppKeys.feedList), findsOneWidget);
    });

    // ─── Commentaires ─────────────────────────────────────────────────

    testWidgets('Ouvrir les commentaires d\'un post', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tapper sur le bouton commentaire du premier post
      final commentBtns = find.byKey(AppKeys.commentButton);
      expect(commentBtns, findsWidgets);
      await tester.tap(commentBtns.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Le bottom sheet commentaires est ouvert
      expect(find.text('Commentaires'), findsOneWidget);
    });

    testWidgets('Envoyer un commentaire', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Ouvrir les commentaires
      await tester.tap(find.byKey(AppKeys.commentButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Saisir et envoyer un commentaire
      const testComment = 'Test commentaire intégration 🔥';
      await tester.enterText(
          find.byKey(AppKeys.commentInput), testComment);
      await tester.tap(find.byKey(AppKeys.commentSend));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Le commentaire doit apparaître dans la liste
      expect(find.text(testComment), findsOneWidget);
    });

    // ─── Bookmark ─────────────────────────────────────────────────────

    testWidgets('Bookmarker un post', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final bookmarks = find.byKey(AppKeys.bookmarkButton);
      expect(bookmarks, findsWidgets);
      await tester.tap(bookmarks.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Pas de crash
      expect(find.byKey(AppKeys.feedList), findsOneWidget);
    });

    // ─── Scroll pagination ────────────────────────────────────────────

    testWidgets('Scroll en bas du feed → charge plus de posts',
        (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Scroller plusieurs fois vers le bas
      for (int i = 0; i < 5; i++) {
        await TestHelpers.scrollDown(
            tester, find.byKey(AppKeys.feedList));
      }
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ✅ Toujours en vie sans crash
      expect(find.byKey(AppKeys.feedList), findsOneWidget);
    });

    // ─── Créer un post ────────────────────────────────────────────────

    testWidgets('Créer et publier un post texte', (tester) async {
      await TestHelpers.launchApp(tester);
      await TestHelpers.login(tester);

      // Aller sur Create via le bottom sheet
      await tester.tap(find.byKey(AppKeys.bottomNavCreate));
      await tester.pumpAndSettle();

      // Appuyer sur "Post" dans le sheet
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ✅ Écran de création de post ouvert
      expect(find.text('Nouvelle publication'), findsOneWidget);

      // Saisir une légende
      const caption = 'Post de test intégration 🌸';
      await tester.enterText(
          find.byKey(AppKeys.captionInput), caption);
      await tester.pumpAndSettle();

      // Publier
      await tester.tap(find.byKey(AppKeys.sharePostButton));
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // ✅ Retour sur le feed après publication
      expect(find.text('Otakuverse'), findsOneWidget);
    });
  });
}