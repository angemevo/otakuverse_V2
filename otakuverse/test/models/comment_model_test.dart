import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import '../helpers/fixtures.dart';

void main() {
  group('CommentModel', () {
    // ─── fromJson ────────────────────────────────────────────────────

    group('fromJson', () {
      test('parse un commentaire complet avec profil JOIN', () {
        final model = CommentModel.fromJson(commentJson());

        expect(model.id,         'comment-001');
        expect(model.postId,     'post-001');
        expect(model.userId,     'user-001');
        expect(model.content,    'Super post !');
        expect(model.likesCount, 5);
        expect(model.parentId,   isNull);
        expect(model.isLiked,    isFalse);
      });

      test('récupère les données de profil depuis le JOIN', () {
        final model = CommentModel.fromJson(commentJson(
          username:    'fan_anime',
          displayName: 'Fan Anime',
          avatarUrl:   'https://example.com/fan.jpg',
        ));

        expect(model.username,    'fan_anime');
        expect(model.displayName, 'Fan Anime');
        expect(model.avatarUrl,   'https://example.com/fan.jpg');
      });

      test('parse un commentaire de type reply (avec parentId)', () {
        final model = CommentModel.fromJson(
          commentJson(id: 'reply-001', parentId: 'comment-001'),
        );
        expect(model.parentId, 'comment-001');
        expect(model.isReply,  isTrue);
      });

      test('parentId est null pour un commentaire racine', () {
        final model = CommentModel.fromJson(commentJson());
        expect(model.parentId, isNull);
        expect(model.isReply,  isFalse);
      });

      test('valeurs par défaut pour likesCount manquant', () {
        final json = commentJson();
        json['likes_count'] = null;
        final model = CommentModel.fromJson(json);
        expect(model.likesCount, 0);
      });

      test('parse correctement createdAt', () {
        final model = CommentModel.fromJson(
          commentJson(createdAt: '2025-03-10T14:30:00.000Z'),
        );
        expect(model.createdAt.year,  2025);
        expect(model.createdAt.month, 3);
        expect(model.createdAt.day,   10);
      });

      test('utilise DateTime.now() si created_at null', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json   = commentJson();
        json['created_at'] = null; // force null après le ?? du fixture
        final model  = CommentModel.fromJson(json);
        expect(model.createdAt.isAfter(before), isTrue);
      });
    });

    // ─── Getters ─────────────────────────────────────────────────────

    group('getters', () {
      test('hasAvatar retourne true quand avatarUrl non vide', () {
        final model = CommentModel.fromJson(commentJson());
        expect(model.hasAvatar, isTrue);
      });

      test('hasAvatar retourne false quand avatarUrl null', () {
        final json = commentJson();
        (json['profiles'] as Map<String, dynamic>)['avatar_url'] = null;
        final model = CommentModel.fromJson(json);
        expect(model.hasAvatar, isFalse);
      });

      test('hasAvatar retourne false quand avatarUrl vide', () {
        final json = commentJson();
        (json['profiles'] as Map<String, dynamic>)['avatar_url'] = '';
        final model = CommentModel.fromJson(json);
        expect(model.hasAvatar, isFalse);
      });

      test('isReply retourne false quand parentId null', () {
        final model = CommentModel.fromJson(commentJson());
        expect(model.isReply, isFalse);
      });

      test('isReply retourne true quand parentId non null', () {
        final model = CommentModel.fromJson(
          commentJson(parentId: 'parent-123'),
        );
        expect(model.isReply, isTrue);
      });

      test('hasReplies retourne false quand replies est vide', () {
        final model = CommentModel.fromJson(commentJson());
        expect(model.hasReplies, isFalse);
      });

      test('hasReplies retourne true quand replies non vide', () {
        final reply = CommentModel.fromJson(
          commentJson(id: 'reply-001', parentId: 'comment-001'),
        );
        final model = CommentModel.fromJson(commentJson()).copyWith(
          replies: [reply],
        );
        expect(model.hasReplies, isTrue);
      });

      test('displayNameOrUsername retourne displayName en priorité', () {
        final model = CommentModel.fromJson(commentJson(
          displayName: 'Prénom Nom',
          username:    'username99',
        ));
        expect(model.displayNameOrUsername, 'Prénom Nom');
      });

      test('displayNameOrUsername retourne username si displayName null', () {
        final json = commentJson(username: 'username99');
        (json['profiles'] as Map<String, dynamic>)['display_name'] = null;
        final model = CommentModel.fromJson(json);
        expect(model.displayNameOrUsername, 'username99');
      });

      test('displayNameOrUsername retourne fallback si tout est null', () {
        final json = commentJson();
        (json['profiles'] as Map<String, dynamic>)['display_name'] = null;
        (json['profiles'] as Map<String, dynamic>)['username']     = null;
        final model = CommentModel.fromJson(json);
        expect(model.displayNameOrUsername, 'Utilisateur');
      });
    });

    // ─── copyWith ────────────────────────────────────────────────────

    group('copyWith', () {
      late CommentModel original;

      setUp(() {
        original = CommentModel.fromJson(commentJson());
      });

      test('met à jour content uniquement', () {
        final updated = original.copyWith(content: 'Nouveau contenu');
        expect(updated.content, 'Nouveau contenu');
        expect(updated.id,      original.id);
        expect(updated.postId,  original.postId);
      });

      test('met à jour isLiked', () {
        final liked   = original.copyWith(isLiked: true,  likesCount: 6);
        final unliked = liked.copyWith(   isLiked: false, likesCount: 5);

        expect(liked.isLiked,   isTrue);
        expect(liked.likesCount, 6);
        expect(unliked.isLiked,   isFalse);
        expect(unliked.likesCount, 5);
      });

      test('met à jour les replies', () {
        final reply   = CommentModel.fromJson(
          commentJson(id: 'reply-001', parentId: 'comment-001'),
        );
        final updated = original.copyWith(replies: [reply]);

        expect(updated.replies.length, 1);
        expect(updated.replies.first.id, 'reply-001');
        expect(updated.hasReplies, isTrue);
      });

      test('préserve les champs non modifiés', () {
        final updated = original.copyWith(likesCount: 99);
        expect(updated.content,  original.content);
        expect(updated.userId,   original.userId);
        expect(updated.postId,   original.postId);
        expect(updated.parentId, original.parentId);
      });
    });

    // ─── Égalité ─────────────────────────────────────────────────────

    group('égalité', () {
      test('deux commentaires avec le même id sont égaux', () {
        final a = CommentModel.fromJson(commentJson(id: 'same'));
        final b = CommentModel.fromJson(commentJson(id: 'same', content: 'Autre'));
        expect(a, equals(b));
      });

      test('deux commentaires avec ids différents ne sont pas égaux', () {
        final a = CommentModel.fromJson(commentJson(id: 'c-A'));
        final b = CommentModel.fromJson(commentJson(id: 'c-B'));
        expect(a, isNot(equals(b)));
      });
    });
  });
}
