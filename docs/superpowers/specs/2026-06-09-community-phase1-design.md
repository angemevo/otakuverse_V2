# Community Phase 1 — Design Spec

**Date:** 2026-06-09
**Branch:** `feature/community-phase1`
**Status:** Approved

---

## Vue d'ensemble

Implémenter la fonctionnalité **Community Phase 1** dans Otakuverse : un système de communautés thématiques (principalement anime/manga) où n'importe quel utilisateur peut créer une communauté, la rejoindre, et y poster du contenu exclusif ou partagé avec le feed global.

**Hors scope Phase 1 :** modération avancée, rôles personnalisés, salons de discussion temps réel (Phase 3), events (Phase 3), flairs/catégories (Phase 2).

---

## Modèle de données (Supabase)

### Nouvelles tables

**`communities`**
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
name            text NOT NULL UNIQUE
description     text
avatar_url      text
banner_url      text
anime_tag       text          -- nom libre de l'anime/manga associé
creator_id      uuid NOT NULL REFERENCES profiles(user_id)
members_count   int NOT NULL DEFAULT 0
posts_count     int NOT NULL DEFAULT 0
is_private      bool NOT NULL DEFAULT false
created_at      timestamptz NOT NULL DEFAULT now()
```

**`community_members`**
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
community_id    uuid NOT NULL REFERENCES communities(id) ON DELETE CASCADE
user_id         uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE
role            text NOT NULL DEFAULT 'member'  -- 'admin' | 'member'
joined_at       timestamptz NOT NULL DEFAULT now()
UNIQUE(community_id, user_id)
```

**`community_posts`** *(posts exclusifs à une communauté)*
```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
community_id    uuid NOT NULL REFERENCES communities(id) ON DELETE CASCADE
user_id         uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE
caption         text NOT NULL DEFAULT ''
media_urls      text[] NOT NULL DEFAULT '{}'
likes_count     int NOT NULL DEFAULT 0
comments_count  int NOT NULL DEFAULT 0
created_at      timestamptz NOT NULL DEFAULT now()
updated_at      timestamptz NOT NULL DEFAULT now()
```

### Modification table existante

**`posts`** — ajout d'une colonne nullable :
```sql
ALTER TABLE posts ADD COLUMN community_id uuid REFERENCES communities(id) ON DELETE SET NULL;
```
Les posts globaux tagués à une communauté ont `community_id` rempli. Les posts normaux restent à `NULL` — aucun impact sur les requêtes du feed existant.

### Triggers Supabase

- `community_members` INSERT → `communities.members_count + 1`
- `community_members` DELETE → `communities.members_count - 1`
- `community_posts` INSERT → `communities.posts_count + 1`
- `community_posts` DELETE → `communities.posts_count - 1`

---

## Architecture Flutter

Nouvelle feature dans `lib/features/community/`, cohérente avec le pattern existant du projet.

```
lib/features/community/
├── bindings/
│   └── community_binding.dart          -- lazyPut CommunityController
├── controllers/
│   └── community_controller.dart       -- state: sections (mes/tendances/recommandées), pagination
├── models/
│   ├── community_model.dart            -- fromJson, isJoined getter
│   └── community_post_model.dart       -- fromJson, posts exclusifs uniquement (community_posts table)
├── repositories/
│   └── community_repository.dart      -- toutes les requêtes Supabase
├── services/
│   └── community_service.dart         -- logique métier (créer, rejoindre, quitter, poster)
└── screens/
    ├── community_screen.dart           -- remplace le placeholder actuel
    ├── community_detail_screen.dart    -- page d'une communauté
    ├── create_community_screen.dart    -- formulaire de création
    └── widgets/
        ├── community_card.dart         -- carte dans la liste (avatar, nom, membres, anime_tag)
        ├── community_header.dart       -- bannière + stats en haut du détail
        ├── community_post_card.dart    -- post dans le feed communauté
        └── community_sections.dart    -- sections "Mes", "Tendances", "Recommandées"
```

**Modification existante** — `lib/features/feed/screens/create_post_screen.dart` :
- Ajouter un sélecteur de communauté optionnel (champ `community_id` nullable)
- Ajouter un toggle **"Post exclusif / Visible dans le feed global"**
- Le sélecteur est caché si l'utilisateur n'est membre d'aucune communauté

**`RealtimeService`** — ajouter un channel `public:community_members` pour mettre à jour `members_count` en temps réel sur `CommunityDetailScreen`.

**Navigation** — `CommunityScreen` remplace directement le widget placeholder dans `NavigationPage._pages[1]`. Aucun changement dans les routes de `main.dart`.

---

## Flux de données

### Écran principal Community (`CommunityScreen`)

Charge 3 sections en parallèle au `onInit` :

```
"Mes communautés"    → community_members WHERE user_id = moi → JOIN communities
"Tendances"          → communities ORDER BY members_count DESC LIMIT 10
"Recommandées"       → communities WHERE anime_tag IN (favoriteAnime + favoriteGenres du profil)
```

Pagination infinie sur chaque section (offset + pageSize = 20), identique au feed existant.

### Page détail (`CommunityDetailScreen`)

```
Header    → communities WHERE id = X (+ isJoined check)
Feed      → community_posts WHERE community_id = X   → CommunityPostModel (exclusifs)
          + posts WHERE community_id = X              → PostModel (globaux tagués)
          → fusionnés dans RxList<Object> et triés par created_at DESC côté Flutter
          → le widget feed affiche CommunityPostCard pour CommunityPostModel,
            PostsCard existant pour PostModel
```

Bouton **Rejoindre / Quitter** :
1. Optimistic update immédiat (compteur + état bouton)
2. Insert/delete dans `community_members`
3. Rollback si erreur Supabase

### Créer un post dans une communauté

Depuis `CommunityDetailScreen` → ouvre `CreatePostScreen` avec `communityId` pré-rempli.

- Toggle **"Exclusif"** → insert dans `community_posts`
- Toggle **"Feed global"** → insert dans `posts` avec `community_id` rempli

### Créer une communauté (`CreateCommunityScreen`)

Champs : nom (obligatoire, min 3 chars), description, anime_tag (texte libre avec suggestions `flutter_typeahead` depuis les favoris), avatar (optionnel via `StorageUploadService`).

À la validation :
1. Insert dans `communities` avec `creator_id = currentUser.id`
2. Insert dans `community_members` avec `role = 'admin'`
3. Navigation vers `CommunityDetailScreen` de la nouvelle communauté

---

## Gestion d'erreurs

| Cas | Comportement |
|-----|-------------|
| Nom de communauté déjà pris | Message inline sous le champ (unique constraint Supabase) |
| Nom < 3 caractères | Validation Flutter avant envoi |
| Quitter si seul admin | Snackbar "Supprime la communauté d'abord" |
| Feed vide | Illustration + "Sois le premier à poster ici" |
| Communauté introuvable | Pop automatique + snackbar |
| Erreur offline | `ConnectivityWrapper` existant gère le cas |
| Optimistic update échoue | Rollback compteur + snackbar erreur |

---

## Tests

```
otakuverse/test/
├── models/
│   ├── community_model_test.dart        -- parsing JSON, getter isJoined, edge cases
│   └── community_post_model_test.dart   -- parsing JSON, type exclusif/global
└── controllers/
    └── community_controller_test.dart   -- mock CommunityService, tester load/join/leave/create
```

`helpers/fixtures.dart` reçoit deux nouvelles factories : `communityJson()` et `communityPostJson()`.

---

## Découpage en tickets (ordre d'implémentation)

1. **DB** — migrations SQL (3 tables + ALTER posts)
2. **Models** — `CommunityModel`, `CommunityPostModel` + fixtures
3. **Repository + Service** — toutes les requêtes Supabase
4. **CommunityController + Binding**
5. **CommunityScreen** — remplace placeholder, 3 sections
6. **CommunityDetailScreen** — feed fusionné + header + rejoindre/quitter
7. **CreateCommunityScreen** — formulaire
8. **CreatePostScreen** — ajout sélecteur communauté + toggle
9. **RealtimeService** — channel community_members
10. **Tests** — models + controller
