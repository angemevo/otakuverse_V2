import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import '../helpers/fixtures.dart';

void main() {
  group('ProfileModel', () {
    // ─── fromJson ────────────────────────────────────────────────────

    group('fromJson', () {
      test('parse un profil complet', () {
        final model = ProfileModel.fromJson(profileJson());

        expect(model.userId,         'user-001');
        expect(model.displayName,    'Otaku Sensei');
        expect(model.bio,            'Passionné d\'anime depuis toujours.');
        expect(model.avatarUrl,      'https://example.com/avatar.jpg');
        expect(model.followersCount, 150);
        expect(model.followingCount, 80);
        expect(model.postsCount,     25);
        expect(model.isPrivate,      isFalse);
        expect(model.isVerified,     isTrue);
      });

      test('id est user_id quand la colonne id est absente', () {
        final json  = profileJson(userId: 'user-xyz');
        final model = ProfileModel.fromJson(json);
        // La table profiles n'a pas de colonne 'id', donc id = user_id
        expect(model.id,     'user-xyz');
        expect(model.userId, 'user-xyz');
      });

      test('id utilise json["id"] quand présent', () {
        final json = profileJson(userId: 'user-xyz');
        json['id'] = 'profile-id-123';
        final model = ProfileModel.fromJson(json);
        expect(model.id, 'profile-id-123');
      });

      test('parse les listes de favoris', () {
        final model = ProfileModel.fromJson(profileJson());

        expect(model.favoriteAnime,  containsAll(['Naruto', 'Attack on Titan']));
        expect(model.favoriteManga,  contains('One Piece'));
        expect(model.favoriteGames,  contains('Elden Ring'));
        expect(model.favoriteGenres, containsAll(['Shonen', 'Seinen']));
      });

      test('listes de favoris vides quand absentes', () {
        final json = profileJson();
        json.remove('favorite_anime');
        json.remove('favorite_manga');
        json.remove('favorite_games');
        json.remove('favorite_genres');
        final model = ProfileModel.fromJson(json);

        expect(model.favoriteAnime,  isEmpty);
        expect(model.favoriteManga,  isEmpty);
        expect(model.favoriteGames,  isEmpty);
        expect(model.favoriteGenres, isEmpty);
      });

      test('parse le système de rank otaku', () {
        final model = ProfileModel.fromJson(profileJson(
          otakuRank:   'Senpai',
          otakuLevel:  5,
          otakuPoints: 420,
        ));

        expect(model.otakuRank,   'Senpai');
        expect(model.otakuLevel,  5);
        expect(model.otakuPoints, 420);
      });

      test('rank par défaut = Novice niveau 1 quand absent', () {
        final json = profileJson();
        json.remove('otaku_rank');
        json.remove('otaku_level');
        json.remove('otaku_points');
        final model = ProfileModel.fromJson(json);

        expect(model.otakuRank,   'Novice');
        expect(model.otakuLevel,  1);
        expect(model.otakuPoints, 0);
      });

      test('parse watchlistCount et reviewsCount', () {
        final model = ProfileModel.fromJson(profileJson(
          watchlistCount: 33,
          reviewsCount:   12,
        ));
        expect(model.watchlistCount, 33);
        expect(model.reviewsCount,   12);
      });

      test('parse correctement createdAt', () {
        final model = ProfileModel.fromJson(
          profileJson(createdAt: '2024-01-01T00:00:00.000Z'),
        );
        expect(model.createdAt.year,  2024);
        expect(model.createdAt.month, 1);
        expect(model.createdAt.day,   1);
      });

      test('champs optionnels null quand absents', () {
        final json = profileJson();
        json['bio']        = null;
        json['avatar_url'] = null;
        json['banner_url'] = null;
        json['website']    = null;
        final model = ProfileModel.fromJson(json);

        expect(model.bio,       isNull);
        expect(model.avatarUrl, isNull);
        expect(model.bannerUrl, isNull);
        expect(model.website,   isNull);
      });
    });

    // ─── Getters booléens ─────────────────────────────────────────────

    group('getters booléens', () {
      test('hasAvatar retourne true quand avatarUrl non vide', () {
        final model = ProfileModel.fromJson(profileJson());
        expect(model.hasAvatar, isTrue);
      });

      test('hasAvatar retourne false quand avatarUrl null', () {
        final json = profileJson();
        json['avatar_url'] = null;
        final model = ProfileModel.fromJson(json);
        expect(model.hasAvatar, isFalse);
      });

      test('hasAvatar retourne false quand avatarUrl chaîne vide', () {
        final json = profileJson();
        json['avatar_url'] = '';
        final model = ProfileModel.fromJson(json);
        expect(model.hasAvatar, isFalse);
      });

      test('hasBanner retourne true quand bannerUrl non vide', () {
        final json = profileJson(bannerUrl: 'https://example.com/banner.jpg');
        final model = ProfileModel.fromJson(json);
        expect(model.hasBanner, isTrue);
      });

      test('hasBanner retourne false quand bannerUrl null', () {
        final model = ProfileModel.fromJson(profileJson());
        expect(model.hasBanner, isFalse);
      });

      test('hasBio retourne true quand bio non vide', () {
        final model = ProfileModel.fromJson(profileJson());
        expect(model.hasBio, isTrue);
      });

      test('hasBio retourne false quand bio null', () {
        final json = profileJson();
        json['bio'] = null;
        final model = ProfileModel.fromJson(json);
        expect(model.hasBio, isFalse);
      });

      test('hasBio retourne false quand bio chaîne vide', () {
        final json = profileJson();
        json['bio'] = '';
        final model = ProfileModel.fromJson(json);
        expect(model.hasBio, isFalse);
      });
    });

    // ─── displayNameOrUsername ─────────────────────────────────────────

    group('displayNameOrUsername', () {
      test('retourne displayName quand non null et non vide', () {
        final model = ProfileModel.fromJson(profileJson(displayName: 'Mon Nom'));
        expect(model.displayNameOrUsername, 'Mon Nom');
      });

      test('retourne username fallback quand displayName null', () {
        final json = profileJson();
        json['display_name'] = null;
        final model = ProfileModel.fromJson(json);
        // username getter retourne displayName ?? 'utilisateur'
        expect(model.displayNameOrUsername, 'utilisateur');
      });
    });

    // ─── Système de niveau ────────────────────────────────────────────

    group('système de niveau', () {
      test('pointsForNextLevel = (level+1)^2 * 10', () {
        final json  = profileJson(otakuLevel: 3);
        final model = ProfileModel.fromJson(json);
        // next = 4 → 4*4*10 = 160
        expect(model.pointsForNextLevel, 160);
      });

      test('levelProgress est entre 0.0 et 1.0', () {
        final model = ProfileModel.fromJson(profileJson(
          otakuLevel:  5,
          otakuPoints: 420,
        ));
        expect(model.levelProgress, greaterThanOrEqualTo(0.0));
        expect(model.levelProgress, lessThanOrEqualTo(1.0));
      });

      test('levelProgress retourne 1.0 si points dépassent le plafond', () {
        // level=2 → current=40, next=90 → avec 10000 points → 1.0
        final model = ProfileModel.fromJson(profileJson(
          otakuLevel:  2,
          otakuPoints: 10000,
        ));
        expect(model.levelProgress, 1.0);
      });

      test('levelProgress retourne 0.0 si points = current threshold', () {
        // level=1 → current=10, next=40 → points=10 → (10-10)/(40-10)=0.0
        final model = ProfileModel.fromJson(profileJson(
          otakuLevel:  1,
          otakuPoints: 10,
        ));
        expect(model.levelProgress, 0.0);
      });
    });

    // ─── copyWith ────────────────────────────────────────────────────

    group('copyWith', () {
      late ProfileModel original;

      setUp(() {
        original = ProfileModel.fromJson(profileJson());
      });

      test('met à jour displayName uniquement', () {
        final updated = original.copyWith(displayName: 'Nouveau Nom');
        expect(updated.displayName,  'Nouveau Nom');
        expect(updated.userId,       original.userId);
        expect(updated.followersCount, original.followersCount);
      });

      test('met à jour followersCount', () {
        final updated = original.copyWith(followersCount: 999);
        expect(updated.followersCount, 999);
      });

      test('met à jour otakuRank et otakuLevel ensemble', () {
        final updated = original.copyWith(
          otakuRank:  'Sensei',
          otakuLevel: 10,
        );
        expect(updated.otakuRank,  'Sensei');
        expect(updated.otakuLevel, 10);
      });

      test('met à jour les listes de favoris', () {
        final updated = original.copyWith(
          favoriteAnime: ['Bleach', 'Dragon Ball'],
        );
        expect(updated.favoriteAnime, ['Bleach', 'Dragon Ball']);
        expect(updated.favoriteManga, original.favoriteManga);
      });

      test('préserve createdAt et updatedAt', () {
        final updated = original.copyWith(bio: 'Nouvelle bio');
        expect(updated.createdAt, original.createdAt);
        expect(updated.updatedAt, original.updatedAt);
      });
    });
  });
}
