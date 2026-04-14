import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import '../helpers/fixtures.dart';

void main() {
  group('PostModel', () {
    // ─── fromJson ────────────────────────────────────────────────────

    group('fromJson', () {
      test('parse un post complet avec profil JOIN', () {
        final model = PostModel.fromJson(postJson());

        expect(model.id,            'post-001');
        expect(model.userId,        'user-001');
        expect(model.caption,       'Mon premier post otaku !');
        expect(model.likesCount,    42);
        expect(model.commentsCount, 7);
        expect(model.sharesCount,   3);
        expect(model.viewsCount,    120);
        expect(model.allowComments, isTrue);
        expect(model.isPinned,      isFalse);
        expect(model.mediaUrls,     ['https://example.com/img1.jpg']);
      });

      test('récupère username et displayName depuis le JOIN profiles', () {
        final model = PostModel.fromJson(postJson(
          username:    'sensei42',
          displayName: 'Sensei 42',
          avatarUrl:   'https://example.com/av.png',
        ));

        expect(model.username,    'sensei42');
        expect(model.displayName, 'Sensei 42');
        expect(model.avatarUrl,   'https://example.com/av.png');
      });

      test('gère les champs optionnels manquants avec des valeurs par défaut', () {
        final json = {
          'id':       'post-002',
          'user_id':  'user-002',
          'caption':  null,
          'media_urls': null,
          'allow_comments': null,
          'likes_count':    null,
          'comments_count': null,
          'is_pinned':      null,
          'created_at':     null,
          'updated_at':     null,
        };
        final model = PostModel.fromJson(json);

        expect(model.caption,       '');
        expect(model.mediaUrls,     isEmpty);
        expect(model.allowComments, isTrue);
        expect(model.likesCount,    0);
        expect(model.commentsCount, 0);
        expect(model.isPinned,      isFalse);
        expect(model.sharesCount,   0);
        expect(model.viewsCount,    0);
      });

      test('parse une liste de plusieurs mediaUrls', () {
        final model = PostModel.fromJson(postJson(
          mediaUrls: ['https://a.com/1.jpg', 'https://a.com/2.jpg', 'https://a.com/3.jpg'],
        ));
        expect(model.mediaUrls.length, 3);
      });

      test('parse les champs music quand présents', () {
        final model = PostModel.fromJson(postJson(
          musicTitle:  'Gurenge',
          musicArtist: 'LiSA',
        ));

        expect(model.musicTitle,  'Gurenge');
        expect(model.musicArtist, 'LiSA');
      });

      test('music fields sont null quand absents', () {
        final model = PostModel.fromJson(postJson());
        expect(model.musicTitle,      isNull);
        expect(model.musicArtist,     isNull);
        expect(model.musicTrackId,    isNull);
        expect(model.musicPreviewUrl, isNull);
        expect(model.musicImageUrl,   isNull);
      });

      test('parse la location quand présente', () {
        final model = PostModel.fromJson(postJson(location: 'Tokyo, Japon'));
        expect(model.location, 'Tokyo, Japon');
      });

      test('location est null quand absente', () {
        final model = PostModel.fromJson(postJson());
        expect(model.location, isNull);
      });

      test('parse correctement createdAt', () {
        final model = PostModel.fromJson(
          postJson(createdAt: '2024-12-25T08:30:00.000Z'),
        );
        expect(model.createdAt.year,  2024);
        expect(model.createdAt.month, 12);
        expect(model.createdAt.day,   25);
      });

      test('utilise DateTime.now() si created_at est null', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json   = postJson();
        json['created_at'] = null; // force null après le ?? du fixture
        final model  = PostModel.fromJson(json);
        expect(model.createdAt.isAfter(before), isTrue);
      });
    });

    // ─── Getters ─────────────────────────────────────────────────────

    group('getters', () {
      test('hasMedia retourne true quand mediaUrls non vide', () {
        final model = PostModel.fromJson(postJson());
        expect(model.hasMedia, isTrue);
      });

      test('hasMedia retourne false quand mediaUrls vide', () {
        final model = PostModel.fromJson(postJson(mediaUrls: []));
        expect(model.hasMedia, isFalse);
      });

      test('isCarousel retourne true pour 2+ images', () {
        final model = PostModel.fromJson(postJson(
          mediaUrls: ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
        ));
        expect(model.isCarousel, isTrue);
      });

      test('isCarousel retourne false pour 1 image', () {
        final model = PostModel.fromJson(postJson(mediaUrls: ['https://a.com/1.jpg']));
        expect(model.isCarousel, isFalse);
      });

      test('mediaCount retourne le nombre correct', () {
        final model = PostModel.fromJson(postJson(
          mediaUrls: ['a', 'b', 'c'],
        ));
        expect(model.mediaCount, 3);
      });

      test('hasLocation retourne true quand location non vide', () {
        final model = PostModel.fromJson(postJson(location: 'Paris'));
        expect(model.hasLocation, isTrue);
      });

      test('hasLocation retourne false quand location null', () {
        final model = PostModel.fromJson(postJson());
        expect(model.hasLocation, isFalse);
      });

      test('displayNameOrUsername retourne displayName en priorité', () {
        final model = PostModel.fromJson(postJson(
          displayName: 'Mon Pseudo',
          username:    'username123',
        ));
        expect(model.displayNameOrUsername, 'Mon Pseudo');
      });

      test('displayNameOrUsername retourne username si displayName null', () {
        final json = postJson();
        (json['profiles'] as Map<String, dynamic>)['display_name'] = null;
        final model = PostModel.fromJson(json);
        expect(model.displayNameOrUsername, 'otaku_sensei');
      });

      test('displayNameOrUsername retourne fallback si tout est null', () {
        final json = postJson();
        (json['profiles'] as Map<String, dynamic>)['display_name'] = null;
        (json['profiles'] as Map<String, dynamic>)['username']     = null;
        final model = PostModel.fromJson(json);
        expect(model.displayNameOrUsername, 'Utilisateur');
      });
    });

    // ─── copyWith ────────────────────────────────────────────────────

    group('copyWith', () {
      late PostModel original;

      setUp(() {
        original = PostModel.fromJson(postJson());
      });

      test('met à jour likesCount uniquement', () {
        final updated = original.copyWith(likesCount: 100);
        expect(updated.likesCount, 100);
        expect(updated.id,         original.id);
        expect(updated.caption,    original.caption);
      });

      test('met à jour isLiked en optimistic update', () {
        final liked    = original.copyWith(isLiked: true,  likesCount: 43);
        final unliked  = liked.copyWith(   isLiked: false, likesCount: 42);

        expect(liked.isLiked,   isTrue);
        expect(liked.likesCount, 43);
        expect(unliked.isLiked,   isFalse);
        expect(unliked.likesCount, 42);
      });

      test('met à jour commentsCount', () {
        final updated = original.copyWith(commentsCount: 10);
        expect(updated.commentsCount, 10);
      });

      test('préserve les champs non modifiés', () {
        final updated = original.copyWith(caption: 'Nouveau caption');
        expect(updated.userId,        original.userId);
        expect(updated.mediaUrls,     original.mediaUrls);
        expect(updated.allowComments, original.allowComments);
        expect(updated.createdAt,     original.createdAt);
      });
    });

    // ─── Égalité ─────────────────────────────────────────────────────

    group('égalité', () {
      test('deux posts avec le même id sont égaux', () {
        final a = PostModel.fromJson(postJson(id: 'same'));
        final b = PostModel.fromJson(postJson(id: 'same', caption: 'Différent'));
        expect(a, equals(b));
      });

      test('deux posts avec ids différents ne sont pas égaux', () {
        final a = PostModel.fromJson(postJson(id: 'post-A'));
        final b = PostModel.fromJson(postJson(id: 'post-B'));
        expect(a, isNot(equals(b)));
      });

      test('hashCode est basé sur id', () {
        final a = PostModel.fromJson(postJson(id: 'same'));
        final b = PostModel.fromJson(postJson(id: 'same'));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    // ─── toJson ──────────────────────────────────────────────────────

    group('toJson', () {
      test('sérialise correctement les champs obligatoires', () {
        final model = PostModel.fromJson(postJson());
        final json  = model.toJson();

        expect(json['id'],       model.id);
        expect(json['user_id'],  model.userId);
        expect(json['caption'],  model.caption);
        expect(json['is_pinned'], model.isPinned);
      });

      test('n\'inclut pas location si null', () {
        final model = PostModel.fromJson(postJson());
        final json  = model.toJson();
        expect(json.containsKey('location'), isFalse);
      });

      test('inclut location si non null', () {
        final model = PostModel.fromJson(postJson(location: 'Paris'));
        final json  = model.toJson();
        expect(json['location'], 'Paris');
      });
    });
  });
}
