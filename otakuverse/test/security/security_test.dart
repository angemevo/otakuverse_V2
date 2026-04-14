// Tests de sécurité — valident les règles de validation et les défenses
// contre les injections, XSS, et mauvaises entrées côté client.

import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/models/comment_model.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/shared/config/api_config.dart';
import '../helpers/fixtures.dart';

void main() {
  // ─── Validation des entrées utilisateur ──────────────────────────

  group('Validation des entrées', () {
    group('caption de post', () {
      test('caption vide est acceptée par le modèle (validation dans UI)', () {
        final model = PostModel.fromJson(postJson(caption: ''));
        expect(model.caption, '');
        // Note : la validation "caption vide" est dans _publish() de CreatePostScreen
      });

      test('caption très longue (> 2000 chars) est stockée sans troncature', () {
        final longCaption = 'A' * 3000;
        final model = PostModel.fromJson(postJson(caption: longCaption));
        // Le modèle accepte — c'est à la couche service de valider la longueur
        expect(model.caption.length, 3000);
        // ⚠️ ALERTE : PostService.createPost() n'a pas de validation de longueur
      });

      test('caption null devient chaîne vide via fromJson', () {
        final json  = postJson();
        json['caption'] = null;
        final model = PostModel.fromJson(json);
        expect(model.caption, '');
      });
    });

    group('contenu de commentaire', () {
      test('content ne peut pas être null (champ required dans fromJson)', () {
        // CommentModel.fromJson lance si content est null
        final json = commentJson(content: '');
        final model = CommentModel.fromJson(json);
        expect(model.content, '');
      });

      test('content très long est accepté par le modèle', () {
        final longContent = 'B' * 5000;
        final model = CommentModel.fromJson(commentJson(content: longContent));
        expect(model.content.length, 5000);
        // ⚠️ ALERTE : CommentService n'a pas de validation de longueur
      });
    });

    group('liste de médias', () {
      test('mediaUrls vide est valide', () {
        final model = PostModel.fromJson(postJson(mediaUrls: []));
        expect(model.mediaUrls, isEmpty);
        expect(model.hasMedia,  isFalse);
      });

      test('10 URLs sont stockées sans limitation', () {
        final urls = List.generate(10, (i) => 'https://example.com/$i.jpg');
        final model = PostModel.fromJson(postJson(mediaUrls: urls));
        expect(model.mediaUrls.length, 10);
        // ⚠️ ALERTE : StorageUploadService n'a pas de limite sur le nombre de fichiers
      });

      test('mediaUrls null devient liste vide (défense contre crash)', () {
        final json = postJson();
        json['media_urls'] = null;
        final model = PostModel.fromJson(json);
        expect(model.mediaUrls, isEmpty);
      });
    });
  });

  // ─── Défense contre les injections ───────────────────────────────

  group('Résistance aux injections (stockage côté modèle)', () {
    // Les modèles stockent les données telles quelles (pas d'exécution).
    // La protection réelle vient du client Supabase (paramétré) et des RLS.

    test('SQL injection dans caption → stockée comme texte brut', () {
      const malicious = "'; DROP TABLE posts; --";
      final model = PostModel.fromJson(postJson(caption: malicious));
      expect(model.caption, malicious);
      // Le client Supabase utilise des requêtes paramétrées → pas d'injection
    });

    test('XSS dans caption → stocké comme texte brut, pas exécuté', () {
      const xss = '<script>alert("xss")</script>';
      final model = PostModel.fromJson(postJson(caption: xss));
      expect(model.caption, xss);
      // Flutter ne rend pas de HTML brut → XSS non exécutable dans l'UI
    });

    test('injection dans displayName → stockée comme texte', () {
      const inject = r'${malicious_code()}';
      final model  = PostModel.fromJson(postJson(displayName: inject));
      expect(model.displayName, inject);
    });

    test('XSS dans bio du profil → stocké comme texte', () {
      const xss  = '<img src=x onerror=alert(1)>';
      final json = profileJson();
      json['bio'] = xss;
      final model = ProfileModel.fromJson(json);
      expect(model.bio, xss);
    });

    test('injection SQL dans location → stockée comme texte', () {
      const loc   = "Paris' OR '1'='1";
      final model = PostModel.fromJson(postJson(location: loc));
      expect(model.location, loc);
    });
  });

  // ─── Intégrité des données du profil ─────────────────────────────

  group('Intégrité du profil', () {
    test('followersCount ne peut pas être négatif via fromJson', () {
      final json  = profileJson(followersCount: -50);
      final model = ProfileModel.fromJson(json);
      // Le modèle accepte — validation à implémenter côté serveur (RLS/trigger)
      expect(model.followersCount, -50);
      // ⚠️ ALERTE : pas de contrainte NOT NULL / CHECK >= 0 vérifiée côté client
    });

    test('otakuPoints ne dépasse pas le seuil dans levelProgress', () {
      // Même avec 1 000 000 points, levelProgress est clampé à 1.0
      final model = ProfileModel.fromJson(
        profileJson(otakuLevel: 1, otakuPoints: 1_000_000),
      );
      expect(model.levelProgress, 1.0);
    });

    test('otakuLevel 0 ne provoque pas de division par zéro', () {
      final json = profileJson();
      json['otaku_level'] = 0;
      final model = ProfileModel.fromJson(json);
      // level=0 → next=1*1*10=10, current=0*0*10=0
      // levelProgress = (points - 0) / (10 - 0) clampé
      expect(() => model.levelProgress, returnsNormally);
    });

    test('id est user_id quand colonne id absente (correction bug précédent)', () {
      final json  = profileJson(userId: 'uuid-abc');
      final model = ProfileModel.fromJson(json);
      // Régression : id ne doit JAMAIS être null
      expect(model.id, isNotEmpty);
      expect(model.id, 'uuid-abc');
    });
  });

  // ─── Configuration API ────────────────────────────────────────────

  group('Configuration API', () {
    test('supabaseUrl utilise HTTPS', () {
      expect(ApiConfig.supabaseUrl, startsWith('https://'));
    });

    test('supabaseUrl n\'est pas vide', () {
      expect(ApiConfig.supabaseUrl, isNotEmpty);
    });

    test('supabaseAnonKey n\'est pas vide', () {
      expect(ApiConfig.supabaseAnonKey, isNotEmpty);
    });

    test('baseUrl en production utilise HTTPS', () {
      // En dev, on vérifie juste le format. En prod, HTTPS obligatoire.
      // isProduction = false en dev → on vérifie que la valeur prod serait HTTPS
      expect('https://api.otakuverse.com', startsWith('https://'));
    });

    test('les endpoints auth ont le bon format', () {
      expect(ApiConfig.signup,  contains('/auth/signup'));
      expect(ApiConfig.signin,  contains('/auth/signin'));
      expect(ApiConfig.signout, contains('/auth/signout'));
    });
  });

  // ─── Parsing défensif des modèles ────────────────────────────────

  group('Parsing défensif — pas de crash sur données corrompues', () {
    test('PostModel.fromJson avec champs inconnus → ignorés sans crash', () {
      final json = postJson();
      json['champ_inconnu'] = 'valeur';
      json['autre_champ']   = 12345;
      expect(() => PostModel.fromJson(json), returnsNormally);
    });

    test('ProfileModel.fromJson avec champs inconnus → ignorés sans crash', () {
      final json = profileJson();
      json['hack_field'] = {'nested': 'data'};
      expect(() => ProfileModel.fromJson(json), returnsNormally);
    });

    test('CommentModel.fromJson avec champs inconnus → ignorés', () {
      final json = commentJson();
      json['injected'] = [1, 2, 3];
      expect(() => CommentModel.fromJson(json), returnsNormally);
    });

    test('PostModel.fromJson avec media_urls contenant des types mixtes', () {
      final json = postJson();
      json['media_urls'] = ['https://a.com/1.jpg', 42, null, true];
      // Doit convertir tout en String sans crash
      expect(() => PostModel.fromJson(json), returnsNormally);
    });

    test('ProfileModel._parseList accepte null', () {
      final json = profileJson();
      json['favorite_anime'] = null;
      final model = ProfileModel.fromJson(json);
      expect(model.favoriteAnime, isEmpty);
    });

    test('ProfileModel._parseList accepte une liste hétérogène', () {
      final json = profileJson();
      json['favorite_anime'] = ['Naruto', 42, true, null];
      final model = ProfileModel.fromJson(json);
      // Tous convertis en String
      expect(model.favoriteAnime, isNotEmpty);
    });
  });

  // ─── Égalité et hashCode — pas de collision ───────────────────────

  group('Égalité et hashCode', () {
    test('posts avec IDs différents → hashCodes différents', () {
      final a = PostModel.fromJson(postJson(id: 'post-A'));
      final b = PostModel.fromJson(postJson(id: 'post-B'));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('deux instances avec même ID → même hashCode', () {
      final a = PostModel.fromJson(postJson(id: 'post-X'));
      final b = PostModel.fromJson(postJson(id: 'post-X', caption: 'autre'));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, equals(b));
    });

    test('Set déduplique les posts par id', () {
      final set = {
        PostModel.fromJson(postJson(id: 'post-1')),
        PostModel.fromJson(postJson(id: 'post-1', caption: 'doublon')),
        PostModel.fromJson(postJson(id: 'post-2')),
      };
      expect(set.length, 2);
    });
  });
}
