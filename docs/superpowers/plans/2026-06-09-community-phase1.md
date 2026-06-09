# Community Phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implémenter les communautés thématiques Phase 1 — création, découverte, feed dédié, rejoindre/quitter — en remplaçant l'onglet placeholder Community de la navigation principale.

**Architecture:** Option A isolée : les posts exclusifs vivent dans `community_posts` (nouvelle table), les posts globaux tagués ajoutent une colonne nullable `community_id` à `posts`. Le `CommunityController` charge 3 sections en parallèle (mes communautés, tendances, recommandées). Le feed détail fusionne les deux types de posts côté Flutter via `RxList<Object>`.

**Tech Stack:** Flutter, GetX, Supabase (Postgres + Realtime), `flutter_typeahead` (déjà dans pubspec), `flutter_screenutil`, `cached_network_image`.

**Branch:** `feature/community-phase1` (créée depuis `version-2`)

---

## Structure des fichiers

### Nouveaux fichiers
```
otakuverse/supabase/migrations/20260609000000_community.sql
otakuverse/lib/features/community/
  bindings/community_binding.dart
  controllers/community_controller.dart
  models/community_model.dart
  models/community_post_model.dart
  repositories/community_repository.dart
  services/community_service.dart
  screens/community_screen.dart
  screens/community_detail_screen.dart
  screens/create_community_screen.dart
  screens/widgets/community_card.dart
  screens/widgets/community_header.dart
  screens/widgets/community_post_card.dart
  screens/widgets/community_sections.dart
otakuverse/test/models/community_model_test.dart
otakuverse/test/models/community_post_model_test.dart
otakuverse/test/controllers/community_controller_test.dart
```

### Fichiers modifiés
```
otakuverse/test/helpers/fixtures.dart               — +communityJson(), +communityPostJson()
otakuverse/lib/features/navigation/navigation_page.dart  — swap placeholder → CommunityScreen
otakuverse/lib/main.dart                            — +CommunityBinding sur route /home
otakuverse/lib/core/services/realtime_service.dart  — +channel community_members
otakuverse/lib/features/feed/screens/create_post_screen.dart — +sélecteur communauté + toggle
```

---

## Task 1 : Migration SQL

**Files:**
- Create: `otakuverse/supabase/migrations/20260609000000_community.sql`

- [ ] **Step 1 : Créer le fichier de migration**

```sql
-- otakuverse/supabase/migrations/20260609000000_community.sql

-- ─── TABLE communities ───────────────────────────────────────────────────────
CREATE TABLE public.communities (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  description   text,
  avatar_url    text,
  banner_url    text,
  anime_tag     text,
  creator_id    uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  members_count int  NOT NULL DEFAULT 0,
  posts_count   int  NOT NULL DEFAULT 0,
  is_private    bool NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT communities_name_unique UNIQUE (name)
);

-- ─── TABLE community_members ─────────────────────────────────────────────────
CREATE TABLE public.community_members (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  role          text NOT NULL DEFAULT 'member',
  joined_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT community_members_unique UNIQUE (community_id, user_id)
);

-- ─── TABLE community_posts ───────────────────────────────────────────────────
CREATE TABLE public.community_posts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id  uuid NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  caption       text NOT NULL DEFAULT '',
  media_urls    text[] NOT NULL DEFAULT '{}',
  likes_count   int  NOT NULL DEFAULT 0,
  comments_count int NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- ─── MODIFIER TABLE posts ────────────────────────────────────────────────────
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id) ON DELETE SET NULL;

-- ─── TRIGGERS membres ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_members_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.communities
    SET members_count = members_count + 1
    WHERE id = NEW.community_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_members_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.communities
    SET members_count = GREATEST(members_count - 1, 0)
    WHERE id = OLD.community_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_member_join
  AFTER INSERT ON public.community_members
  FOR EACH ROW EXECUTE FUNCTION increment_members_count();

CREATE TRIGGER on_member_leave
  AFTER DELETE ON public.community_members
  FOR EACH ROW EXECUTE FUNCTION decrement_members_count();

-- ─── TRIGGERS posts communauté ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_community_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.communities
    SET posts_count = posts_count + 1
    WHERE id = NEW.community_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_community_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.communities
    SET posts_count = GREATEST(posts_count - 1, 0)
    WHERE id = OLD.community_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_community_post_create
  AFTER INSERT ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION increment_community_posts_count();

CREATE TRIGGER on_community_post_delete
  AFTER DELETE ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION decrement_community_posts_count();

-- ─── RLS (Row Level Security) ────────────────────────────────────────────────
ALTER TABLE public.communities      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts   ENABLE ROW LEVEL SECURITY;

-- Lecture publique des communautés non-privées
CREATE POLICY "communities_select" ON public.communities
  FOR SELECT USING (is_private = false OR creator_id = auth.uid());

-- Insertion : tout utilisateur authentifié
CREATE POLICY "communities_insert" ON public.communities
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Membres : lecture publique, gestion par soi-même
CREATE POLICY "members_select" ON public.community_members
  FOR SELECT USING (true);
CREATE POLICY "members_insert" ON public.community_members
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "members_delete" ON public.community_members
  FOR DELETE USING (user_id = auth.uid());

-- Posts communauté : lecture publique, écriture par membres authentifiés
CREATE POLICY "community_posts_select" ON public.community_posts
  FOR SELECT USING (true);
CREATE POLICY "community_posts_insert" ON public.community_posts
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "community_posts_delete" ON public.community_posts
  FOR DELETE USING (user_id = auth.uid());
```

- [ ] **Step 2 : Appliquer la migration en local**

```bash
cd otakuverse
supabase db reset
```

Résultat attendu : `Finished supabase db reset` sans erreur.

- [ ] **Step 3 : Commit**

```bash
git checkout feature/community-phase1
git add supabase/migrations/20260609000000_community.sql
git commit -m "feat(community): add SQL migration — communities, community_members, community_posts tables"
```

---

## Task 2 : CommunityModel + fixtures + tests

**Files:**
- Create: `otakuverse/lib/features/community/models/community_model.dart`
- Modify: `otakuverse/test/helpers/fixtures.dart`
- Create: `otakuverse/test/models/community_model_test.dart`

- [ ] **Step 1 : Écrire le test en premier**

```dart
// otakuverse/test/models/community_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/community/models/community_model.dart';
import '../helpers/fixtures.dart';

void main() {
  group('CommunityModel.fromJson', () {
    test('parse tous les champs obligatoires', () {
      final m = CommunityModel.fromJson(communityJson());
      expect(m.id,           'community-001');
      expect(m.name,         'One Piece Fan Club');
      expect(m.creatorId,    'user-001');
      expect(m.membersCount, 42);
      expect(m.postsCount,   10);
      expect(m.isPrivate,    isFalse);
      expect(m.isJoined,     isFalse);
    });

    test('parse les champs optionnels', () {
      final m = CommunityModel.fromJson(communityJson(
        description: 'Une communauté pour les fans',
        avatarUrl:   'https://example.com/avatar.jpg',
        animeTag:    'One Piece',
      ));
      expect(m.description, 'Une communauté pour les fans');
      expect(m.avatarUrl,   'https://example.com/avatar.jpg');
      expect(m.animeTag,    'One Piece');
    });

    test('isJoined peut être passé via paramètre', () {
      final m = CommunityModel.fromJson(communityJson(), isJoined: true);
      expect(m.isJoined, isTrue);
    });

    test('membersCount vaut 0 si absent du JSON', () {
      final json = communityJson();
      json.remove('members_count');
      final m = CommunityModel.fromJson(json);
      expect(m.membersCount, 0);
    });
  });

  group('CommunityModel getters', () {
    test('hasAvatar — true si avatarUrl non vide', () {
      final m = CommunityModel.fromJson(
          communityJson(avatarUrl: 'https://example.com/a.jpg'));
      expect(m.hasAvatar, isTrue);
    });

    test('hasAvatar — false si avatarUrl null', () {
      final m = CommunityModel.fromJson(communityJson(avatarUrl: null));
      expect(m.hasAvatar, isFalse);
    });
  });

  group('CommunityModel.copyWith', () {
    test('membersCount mis à jour', () {
      final m       = CommunityModel.fromJson(communityJson(membersCount: 5));
      final updated = m.copyWith(membersCount: 6);
      expect(updated.membersCount, 6);
      expect(updated.id,           m.id); // autres champs inchangés
    });

    test('isJoined mis à jour', () {
      final m       = CommunityModel.fromJson(communityJson());
      final updated = m.copyWith(isJoined: true);
      expect(updated.isJoined, isTrue);
    });
  });

  group('equality', () {
    test('même id → égaux', () {
      final a = CommunityModel.fromJson(communityJson());
      final b = CommunityModel.fromJson(communityJson(membersCount: 99));
      expect(a, equals(b));
    });

    test('ids différents → inégaux', () {
      final a = CommunityModel.fromJson(communityJson(id: 'c-001'));
      final b = CommunityModel.fromJson(communityJson(id: 'c-002'));
      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2 : Lancer le test — doit échouer**

```bash
cd otakuverse
flutter test test/models/community_model_test.dart
```

Résultat attendu : erreur `Target of URI doesn't exist`.

- [ ] **Step 3 : Ajouter communityJson() dans fixtures.dart**

Ajouter à la fin de `otakuverse/test/helpers/fixtures.dart` :

```dart
// ─── COMMUNITY ────────────────────────────────────────────────────────────────

Map<String, dynamic> communityJson({
  String  id           = 'community-001',
  String  name         = 'One Piece Fan Club',
  String? description,
  String? avatarUrl,
  String? bannerUrl,
  String? animeTag,
  String  creatorId    = 'user-001',
  int     membersCount = 42,
  int     postsCount   = 10,
  bool    isPrivate    = false,
  String? createdAt,
}) =>
    {
      'id':            id,
      'name':          name,
      'description':   ?description,
      'avatar_url':    ?avatarUrl,
      'banner_url':    ?bannerUrl,
      'anime_tag':     ?animeTag,
      'creator_id':    creatorId,
      'members_count': membersCount,
      'posts_count':   postsCount,
      'is_private':    isPrivate,
      'created_at':    createdAt ?? '2026-01-01T00:00:00.000Z',
    };
```

- [ ] **Step 4 : Créer CommunityModel**

```dart
// otakuverse/lib/features/community/models/community_model.dart

class CommunityModel {
  final String  id;
  final String  name;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? animeTag;
  final String  creatorId;
  final int     membersCount;
  final int     postsCount;
  final bool    isPrivate;
  final DateTime createdAt;
  final bool    isJoined;

  const CommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.animeTag,
    required this.creatorId,
    required this.membersCount,
    required this.postsCount,
    required this.isPrivate,
    required this.createdAt,
    this.isJoined = false,
  });

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasBanner => bannerUrl != null && bannerUrl!.isNotEmpty;

  factory CommunityModel.fromJson(Map<String, dynamic> json,
      {bool isJoined = false}) {
    return CommunityModel(
      id:           json['id']           as String,
      name:         json['name']         as String,
      description:  json['description']  as String?,
      avatarUrl:    json['avatar_url']   as String?,
      bannerUrl:    json['banner_url']   as String?,
      animeTag:     json['anime_tag']    as String?,
      creatorId:    json['creator_id']   as String,
      membersCount: json['members_count'] as int? ?? 0,
      postsCount:   json['posts_count']  as int? ?? 0,
      isPrivate:    json['is_private']   as bool? ?? false,
      createdAt:    json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isJoined:     isJoined,
    );
  }

  CommunityModel copyWith({int? membersCount, bool? isJoined}) {
    return CommunityModel(
      id:           id,
      name:         name,
      description:  description,
      avatarUrl:    avatarUrl,
      bannerUrl:    bannerUrl,
      animeTag:     animeTag,
      creatorId:    creatorId,
      membersCount: membersCount ?? this.membersCount,
      postsCount:   postsCount,
      isPrivate:    isPrivate,
      createdAt:    createdAt,
      isJoined:     isJoined ?? this.isJoined,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommunityModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 5 : Lancer le test — doit passer**

```bash
flutter test test/models/community_model_test.dart
```

Résultat attendu : `All tests passed`.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/community/models/community_model.dart \
        test/models/community_model_test.dart \
        test/helpers/fixtures.dart
git commit -m "feat(community): CommunityModel + fixtures + tests"
```

---

## Task 3 : CommunityPostModel + fixtures + tests

**Files:**
- Create: `otakuverse/lib/features/community/models/community_post_model.dart`
- Modify: `otakuverse/test/helpers/fixtures.dart`
- Create: `otakuverse/test/models/community_post_model_test.dart`

- [ ] **Step 1 : Écrire le test en premier**

```dart
// otakuverse/test/models/community_post_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:otakuverse/features/community/models/community_post_model.dart';
import '../helpers/fixtures.dart';

void main() {
  group('CommunityPostModel.fromJson', () {
    test('parse tous les champs', () {
      final m = CommunityPostModel.fromJson(communityPostJson());
      expect(m.id,            'cpost-001');
      expect(m.communityId,   'community-001');
      expect(m.userId,        'user-001');
      expect(m.caption,       'Mon post dans la communauté !');
      expect(m.mediaUrls,     ['https://example.com/img.jpg']);
      expect(m.likesCount,    0);
      expect(m.commentsCount, 0);
    });

    test('parse le profil joint', () {
      final m = CommunityPostModel.fromJson(communityPostJson());
      expect(m.username,    'otaku_sensei');
      expect(m.displayName, 'Otaku Sensei');
      expect(m.avatarUrl,   'https://example.com/avatar.jpg');
    });

    test('displayNameOrUsername retourne displayName si défini', () {
      final m = CommunityPostModel.fromJson(
          communityPostJson(displayName: 'Mon Nom'));
      expect(m.displayNameOrUsername, 'Mon Nom');
    });

    test('displayNameOrUsername retourne username si displayName null', () {
      final m = CommunityPostModel.fromJson(
          communityPostJson(displayName: null));
      expect(m.displayNameOrUsername, 'otaku_sensei');
    });

    test('mediaUrls est vide si absent du JSON', () {
      final json = communityPostJson();
      json.remove('media_urls');
      final m = CommunityPostModel.fromJson(json);
      expect(m.mediaUrls, isEmpty);
    });
  });

  group('equality', () {
    test('même id → égaux', () {
      final a = CommunityPostModel.fromJson(communityPostJson());
      final b = CommunityPostModel.fromJson(
          communityPostJson(likesCount: 99));
      expect(a, equals(b));
    });
  });
}
```

- [ ] **Step 2 : Lancer le test — doit échouer**

```bash
flutter test test/models/community_post_model_test.dart
```

Résultat attendu : erreur `Target of URI doesn't exist`.

- [ ] **Step 3 : Ajouter communityPostJson() dans fixtures.dart**

Ajouter à la fin de `otakuverse/test/helpers/fixtures.dart` :

```dart
// ─── COMMUNITY POST ───────────────────────────────────────────────────────────

Map<String, dynamic> communityPostJson({
  String       id            = 'cpost-001',
  String       communityId   = 'community-001',
  String       userId        = 'user-001',
  String       caption       = 'Mon post dans la communauté !',
  List<String>? mediaUrls,
  int          likesCount    = 0,
  int          commentsCount = 0,
  String?      username      = 'otaku_sensei',
  String?      displayName   = 'Otaku Sensei',
  String?      avatarUrl     = 'https://example.com/avatar.jpg',
  String?      createdAt,
  String?      updatedAt,
}) =>
    {
      'id':             id,
      'community_id':   communityId,
      'user_id':        userId,
      'caption':        caption,
      'media_urls':     mediaUrls ?? ['https://example.com/img.jpg'],
      'likes_count':    likesCount,
      'comments_count': commentsCount,
      'profiles': {
        'username':     username,
        'display_name': displayName,
        'avatar_url':   avatarUrl,
      },
      'created_at': createdAt ?? '2026-01-01T12:00:00.000Z',
      'updated_at': updatedAt ?? '2026-01-01T12:00:00.000Z',
    };
```

- [ ] **Step 4 : Créer CommunityPostModel**

```dart
// otakuverse/lib/features/community/models/community_post_model.dart

class CommunityPostModel {
  final String       id;
  final String       communityId;
  final String       userId;
  final String       caption;
  final List<String> mediaUrls;
  final int          likesCount;
  final int          commentsCount;
  final DateTime     createdAt;
  final DateTime     updatedAt;
  final String?      username;
  final String?      displayName;
  final String?      avatarUrl;

  const CommunityPostModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.caption,
    required this.mediaUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  String get displayNameOrUsername =>
      displayName?.isNotEmpty == true ? displayName! : (username ?? 'Utilisateur');

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasMedia  => mediaUrls.isNotEmpty;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return CommunityPostModel(
      id:            json['id']            as String,
      communityId:   json['community_id']  as String,
      userId:        json['user_id']       as String,
      caption:       json['caption']       as String? ?? '',
      mediaUrls:     (json['media_urls']   as List<dynamic>?)
                         ?.map((e) => e as String).toList() ?? [],
      likesCount:    json['likes_count']   as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt:     json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt:     json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      username:    profile?['username']     as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl:   profile?['avatar_url']   as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPostModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 5 : Lancer le test — doit passer**

```bash
flutter test test/models/community_post_model_test.dart
```

Résultat attendu : `All tests passed`.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/community/models/community_post_model.dart \
        test/models/community_post_model_test.dart \
        test/helpers/fixtures.dart
git commit -m "feat(community): CommunityPostModel + fixtures + tests"
```

---

## Task 4 : CommunityRepository + CommunityService

**Files:**
- Create: `otakuverse/lib/features/community/repositories/community_repository.dart`
- Create: `otakuverse/lib/features/community/services/community_service.dart`

- [ ] **Step 1 : Créer CommunityRepository**

```dart
// otakuverse/lib/features/community/repositories/community_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';
import '../models/community_post_model.dart';

class CommunityRepository {
  final _supabase = Supabase.instance.client;
  String get _uid => _supabase.auth.currentUser!.id;

  static const _postSelect =
      '*, profiles(username, display_name, avatar_url)';

  // ─── COMMUNAUTÉS ─────────────────────────────────────────────────

  Future<List<CommunityModel>> getMyCommunities() async {
    final data = await _supabase
        .from('community_members')
        .select('communities(*)')
        .eq('user_id', _uid);

    return (data as List)
        .map((e) => CommunityModel.fromJson(
              e['communities'] as Map<String, dynamic>,
              isJoined: true,
            ))
        .toList();
  }

  Future<List<CommunityModel>> getTrendingCommunities(
      {int limit = 10, int offset = 0}) async {
    final data = await _supabase
        .from('communities')
        .select()
        .eq('is_private', false)
        .order('members_count', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) => CommunityModel.fromJson(e)).toList();
  }

  Future<List<CommunityModel>> getRecommendedCommunities(
      List<String> tags, {int limit = 10}) async {
    if (tags.isEmpty) return [];
    final data = await _supabase
        .from('communities')
        .select()
        .eq('is_private', false)
        .inFilter('anime_tag', tags)
        .limit(limit);

    return (data as List).map((e) => CommunityModel.fromJson(e)).toList();
  }

  Future<CommunityModel?> getCommunityById(String id) async {
    final data = await _supabase
        .from('communities')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    final memberRow = await _supabase
        .from('community_members')
        .select('id')
        .eq('community_id', id)
        .eq('user_id', _uid)
        .maybeSingle();

    return CommunityModel.fromJson(data, isJoined: memberRow != null);
  }

  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    String? animeTag,
    bool isPrivate = false,
  }) async {
    final data = await _supabase
        .from('communities')
        .insert({
          'name':        name,
          'description': description,
          'avatar_url':  avatarUrl,
          'banner_url':  bannerUrl,
          'anime_tag':   animeTag,
          'creator_id':  _uid,
          'is_private':  isPrivate,
        })
        .select()
        .single();

    await _supabase.from('community_members').insert({
      'community_id': data['id'],
      'user_id':      _uid,
      'role':         'admin',
    });

    return CommunityModel.fromJson(data, isJoined: true);
  }

  Future<void> joinCommunity(String communityId) async {
    await _supabase.from('community_members').insert({
      'community_id': communityId,
      'user_id':      _uid,
      'role':         'member',
    });
  }

  Future<void> leaveCommunity(String communityId) async {
    await _supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', _uid);
  }

  Future<bool> isAdmin(String communityId) async {
    final data = await _supabase
        .from('community_members')
        .select('role')
        .eq('community_id', communityId)
        .eq('user_id', _uid)
        .maybeSingle();
    return data?['role'] == 'admin';
  }

  // ─── POSTS COMMUNAUTÉ ────────────────────────────────────────────

  Future<List<CommunityPostModel>> getCommunityPosts(
      String communityId, {int limit = 20, int offset = 0}) async {
    final data = await _supabase
        .from('community_posts')
        .select(_postSelect)
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => CommunityPostModel.fromJson(e))
        .toList();
  }

  Future<CommunityPostModel> createCommunityPost({
    required String       communityId,
    required String       caption,
    required List<String> mediaUrls,
  }) async {
    final data = await _supabase
        .from('community_posts')
        .insert({
          'community_id': communityId,
          'user_id':      _uid,
          'caption':      caption,
          'media_urls':   mediaUrls,
        })
        .select(_postSelect)
        .single();

    return CommunityPostModel.fromJson(data);
  }
}
```

- [ ] **Step 2 : Créer CommunityService**

```dart
// otakuverse/lib/features/community/services/community_service.dart
import '../models/community_model.dart';
import '../models/community_post_model.dart';
import '../repositories/community_repository.dart';

class CommunityService {
  final CommunityRepository _repository;

  CommunityService([CommunityRepository? repository])
      : _repository = repository ?? CommunityRepository();

  Future<List<CommunityModel>> getMyCommunities() =>
      _repository.getMyCommunities();

  Future<List<CommunityModel>> getTrendingCommunities({int offset = 0}) =>
      _repository.getTrendingCommunities(offset: offset);

  Future<List<CommunityModel>> getRecommendedCommunities(List<String> tags) =>
      _repository.getRecommendedCommunities(tags);

  Future<CommunityModel?> getCommunityById(String id) =>
      _repository.getCommunityById(id);

  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    String? animeTag,
    bool isPrivate = false,
  }) =>
      _repository.createCommunity(
        name:        name,
        description: description,
        avatarUrl:   avatarUrl,
        bannerUrl:   bannerUrl,
        animeTag:    animeTag,
        isPrivate:   isPrivate,
      );

  Future<void> joinCommunity(String communityId) =>
      _repository.joinCommunity(communityId);

  Future<void> leaveCommunity(String communityId) =>
      _repository.leaveCommunity(communityId);

  Future<bool> isAdmin(String communityId) =>
      _repository.isAdmin(communityId);

  Future<List<CommunityPostModel>> getCommunityPosts(
          String communityId, {int offset = 0}) =>
      _repository.getCommunityPosts(communityId, offset: offset);

  Future<CommunityPostModel> createCommunityPost({
    required String       communityId,
    required String       caption,
    required List<String> mediaUrls,
  }) =>
      _repository.createCommunityPost(
        communityId: communityId,
        caption:     caption,
        mediaUrls:   mediaUrls,
      );
}
```

- [ ] **Step 3 : Analyser pour détecter les erreurs**

```bash
flutter analyze lib/features/community/repositories/community_repository.dart \
                lib/features/community/services/community_service.dart
```

Résultat attendu : `No issues found`.

- [ ] **Step 4 : Commit**

```bash
git add lib/features/community/repositories/community_repository.dart \
        lib/features/community/services/community_service.dart
git commit -m "feat(community): CommunityRepository + CommunityService"
```

---

## Task 5 : CommunityController + CommunityBinding + tests

**Files:**
- Create: `otakuverse/lib/features/community/controllers/community_controller.dart`
- Create: `otakuverse/lib/features/community/bindings/community_binding.dart`
- Create: `otakuverse/test/controllers/community_controller_test.dart`

- [ ] **Step 1 : Écrire le test en premier**

```dart
// otakuverse/test/controllers/community_controller_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/community/controllers/community_controller.dart';
import 'package:otakuverse/features/community/models/community_model.dart';
import 'package:otakuverse/features/community/services/community_service.dart';
import '../helpers/fixtures.dart';

// ─── Fake Service ─────────────────────────────────────────────────────────────

class _FakeCommunityService extends CommunityService {
  List<CommunityModel> myList          = [];
  List<CommunityModel> trendingList    = [];
  List<CommunityModel> recommendedList = [];
  bool throwOnLoad = false;

  @override
  Future<List<CommunityModel>> getMyCommunities() async {
    if (throwOnLoad) throw Exception('network error');
    return myList;
  }

  @override
  Future<List<CommunityModel>> getTrendingCommunities({int offset = 0}) async {
    if (throwOnLoad) throw Exception('network error');
    return trendingList;
  }

  @override
  Future<List<CommunityModel>> getRecommendedCommunities(
      List<String> tags) async {
    if (throwOnLoad) throw Exception('network error');
    return recommendedList;
  }

  @override
  Future<void> joinCommunity(String communityId) async {}

  @override
  Future<void> leaveCommunity(String communityId) async {}
}

// ─── Helper ───────────────────────────────────────────────────────────────────

CommunityModel _community({
  String id        = 'c-001',
  int    members   = 10,
  bool   isJoined  = false,
}) =>
    CommunityModel.fromJson(
      communityJson(id: id, membersCount: members),
      isJoined: isJoined,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  late CommunityController ctrl;
  late _FakeCommunityService svc;

  setUp(() {
    Get.testMode = true;
    svc  = _FakeCommunityService();
    ctrl = CommunityController(svc);
  });

  tearDown(Get.reset);

  group('état initial', () {
    test('toutes les listes sont vides', () {
      expect(ctrl.myCommunities,         isEmpty);
      expect(ctrl.trendingCommunities,   isEmpty);
      expect(ctrl.recommendedCommunities, isEmpty);
    });

    test('isLoading est false', () {
      expect(ctrl.isLoading.value, isFalse);
    });

    test('errorMessage est vide', () {
      expect(ctrl.errorMessage.value, '');
    });
  });

  group('loadAll — succès', () {
    setUp(() {
      svc.myList       = [_community(id: 'c-001')];
      svc.trendingList = [_community(id: 'c-002'), _community(id: 'c-003')];
      svc.recommendedList = [_community(id: 'c-004')];
    });

    test('remplit les 3 listes', () async {
      await ctrl.loadAll();
      expect(ctrl.myCommunities.length,          1);
      expect(ctrl.trendingCommunities.length,    2);
      expect(ctrl.recommendedCommunities.length, 1);
    });

    test('isLoading revient à false après chargement', () async {
      await ctrl.loadAll();
      expect(ctrl.isLoading.value, isFalse);
    });

    test('errorMessage reste vide si pas d\'erreur', () async {
      await ctrl.loadAll();
      expect(ctrl.errorMessage.value, '');
    });
  });

  group('loadAll — erreur', () {
    setUp(() => svc.throwOnLoad = true);

    test('isLoading revient à false même en cas d\'erreur', () async {
      await ctrl.loadAll();
      expect(ctrl.isLoading.value, isFalse);
    });

    test('errorMessage est rempli', () async {
      await ctrl.loadAll();
      expect(ctrl.errorMessage.value, isNotEmpty);
    });
  });

  group('joinCommunity — optimistic update', () {
    setUp(() {
      ctrl.trendingCommunities.assignAll([
        _community(id: 'c-001', members: 10, isJoined: false),
      ]);
    });

    test('isJoined passe à true immédiatement', () async {
      await ctrl.joinCommunity('c-001');
      expect(ctrl.trendingCommunities.first.isJoined, isTrue);
    });

    test('membersCount est incrémenté', () async {
      await ctrl.joinCommunity('c-001');
      expect(ctrl.trendingCommunities.first.membersCount, 11);
    });
  });

  group('leaveCommunity — optimistic update', () {
    setUp(() {
      ctrl.myCommunities.assignAll([
        _community(id: 'c-001', members: 10, isJoined: true),
      ]);
      ctrl.trendingCommunities.assignAll([
        _community(id: 'c-001', members: 10, isJoined: true),
      ]);
    });

    test('retire la communauté de myCommunities', () async {
      await ctrl.leaveCommunity('c-001');
      expect(ctrl.myCommunities, isEmpty);
    });

    test('membersCount est décrémenté dans trending', () async {
      await ctrl.leaveCommunity('c-001');
      expect(ctrl.trendingCommunities.first.membersCount, 9);
    });
  });
}
```

- [ ] **Step 2 : Lancer le test — doit échouer**

```bash
flutter test test/controllers/community_controller_test.dart
```

Résultat attendu : erreur `Target of URI doesn't exist`.

- [ ] **Step 3 : Créer CommunityController**

```dart
// otakuverse/lib/features/community/controllers/community_controller.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityController extends GetxController {
  final CommunityService _service;

  CommunityController([CommunityService? service])
      : _service = service ?? CommunityService();

  final RxList<CommunityModel> myCommunities          = <CommunityModel>[].obs;
  final RxList<CommunityModel> trendingCommunities     = <CommunityModel>[].obs;
  final RxList<CommunityModel> recommendedCommunities  = <CommunityModel>[].obs;
  final RxBool   isLoading     = false.obs;
  final RxString errorMessage  = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll({List<String> tags = const []}) async {
    isLoading.value    = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _service.getMyCommunities(),
        _service.getTrendingCommunities(),
        _service.getRecommendedCommunities(tags),
      ]);
      myCommunities.assignAll(results[0]);
      trendingCommunities.assignAll(results[1]);
      recommendedCommunities.assignAll(results[2]);
    } catch (e) {
      errorMessage.value = 'Impossible de charger les communautés';
      debugPrint('🔴 CommunityController.loadAll: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinCommunity(String communityId) async {
    _updateCommunity(communityId,
        (c) => c.copyWith(isJoined: true, membersCount: c.membersCount + 1));
    try {
      await _service.joinCommunity(communityId);
      final joined = _findInAll(communityId);
      if (joined != null) myCommunities.add(joined);
    } catch (e) {
      _updateCommunity(communityId,
          (c) => c.copyWith(isJoined: false, membersCount: c.membersCount - 1));
      debugPrint('🔴 joinCommunity: $e');
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    _updateCommunity(communityId,
        (c) => c.copyWith(isJoined: false,
            membersCount: (c.membersCount - 1).clamp(0, 999999)));
    myCommunities.removeWhere((c) => c.id == communityId);
    try {
      await _service.leaveCommunity(communityId);
    } catch (e) {
      await loadAll();
      debugPrint('🔴 leaveCommunity: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  void _updateCommunity(String id, CommunityModel Function(CommunityModel) fn) {
    for (final list in [myCommunities, trendingCommunities, recommendedCommunities]) {
      final idx = list.indexWhere((c) => c.id == id);
      if (idx != -1) list[idx] = fn(list[idx]);
    }
  }

  CommunityModel? _findInAll(String id) {
    for (final list in [trendingCommunities, recommendedCommunities]) {
      try {
        return list.firstWhere((c) => c.id == id);
      } catch (_) {}
    }
    return null;
  }
}
```

- [ ] **Step 4 : Créer CommunityBinding**

```dart
// otakuverse/lib/features/community/bindings/community_binding.dart
import 'package:get/get.dart';
import '../controllers/community_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunityController>(() => CommunityController());
  }
}
```

- [ ] **Step 5 : Lancer le test — doit passer**

```bash
flutter test test/controllers/community_controller_test.dart
```

Résultat attendu : `All tests passed`.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/community/controllers/community_controller.dart \
        lib/features/community/bindings/community_binding.dart \
        test/controllers/community_controller_test.dart
git commit -m "feat(community): CommunityController + Binding + tests"
```

---

## Task 6 : Widgets community

**Files:**
- Create: `otakuverse/lib/features/community/screens/widgets/community_card.dart`
- Create: `otakuverse/lib/features/community/screens/widgets/community_header.dart`
- Create: `otakuverse/lib/features/community/screens/widgets/community_post_card.dart`
- Create: `otakuverse/lib/features/community/screens/widgets/community_sections.dart`

- [ ] **Step 1 : Créer CommunityCard**

```dart
// otakuverse/lib/features/community/screens/widgets/community_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/community/models/community_model.dart';

class CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback   onTap;
  final VoidCallback?  onJoin;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border:       Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48.w, height: 48.w,
              decoration: BoxDecoration(
                color:        AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: community.hasAvatar
                  ? CachedImage(url: community.avatarUrl!)
                  : Icon(Icons.groups_2_rounded,
                        color: AppColors.textMuted, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name,
                      style:     AppTextStyles.body1Bold,
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis),
                  SizedBox(height: 2.h),
                  Row(children: [
                    Text(
                      '${community.membersCount} membres',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                    if (community.animeTag != null) ...[
                      Text(' · ', style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                      Flexible(
                        child: Text(
                          community.animeTag!,
                          style:    AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            // Bouton rejoindre
            if (!community.isJoined && onJoin != null)
              TextButton(
                onPressed: onJoin,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Rejoindre', style: AppTextStyles.caption),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Créer CommunityHeader**

```dart
// otakuverse/lib/features/community/screens/widgets/community_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/community/models/community_model.dart';

class CommunityHeader extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback   onJoinLeave;

  const CommunityHeader({
    super.key,
    required this.community,
    required this.onJoinLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière
        Container(
          height: 120.h,
          width:  double.infinity,
          color:  AppColors.bgSecondary,
          clipBehavior: Clip.antiAlias,
          child: community.hasBanner
              ? CachedImage(url: community.bannerUrl!, fit: BoxFit.cover)
              : null,
        ),
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56.w, height: 56.w,
                    decoration: BoxDecoration(
                      color:        AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12.r),
                      border:       Border.all(
                          color: AppColors.bgPrimary, width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: community.hasAvatar
                        ? CachedImage(url: community.avatarUrl!)
                        : Icon(Icons.groups_2_rounded,
                              color: AppColors.textMuted, size: 28.sp),
                  ),
                  const Spacer(),
                  // Bouton rejoindre/quitter
                  OutlinedButton(
                    onPressed: onJoinLeave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: community.isJoined
                          ? AppColors.textMuted
                          : AppColors.primary,
                      side: BorderSide(
                        color: community.isJoined
                            ? AppColors.borderLight
                            : AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r)),
                    ),
                    child: Text(
                      community.isJoined ? 'Membre' : 'Rejoindre',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(community.name, style: AppTextStyles.h2),
              if (community.animeTag != null) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color:        AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    community.animeTag!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
              if (community.description != null) ...[
                SizedBox(height: 8.h),
                Text(community.description!,
                    style: AppTextStyles.body2
                        .copyWith(color: AppColors.textSecondary)),
              ],
              SizedBox(height: 12.h),
              Row(children: [
                _Stat(value: community.membersCount, label: 'membres'),
                SizedBox(width: 20.w),
                _Stat(value: community.postsCount, label: 'posts'),
              ]),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final int    value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text:  '$value ',
            style: AppTextStyles.body1Bold
                .copyWith(color: AppColors.textPrimary),
          ),
          TextSpan(
            text:  label,
            style: AppTextStyles.body2
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3 : Créer CommunityPostCard**

```dart
// otakuverse/lib/features/community/screens/widgets/community_post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/utils/date_formatter.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/community/models/community_post_model.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;

  const CommunityPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border:       Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header auteur
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius:     18.r,
                  backgroundColor: AppColors.bgSecondary,
                  backgroundImage: post.hasAvatar
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  child: post.hasAvatar
                      ? null
                      : Icon(Icons.person, size: 18.sp,
                            color: AppColors.textMuted),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.displayNameOrUsername,
                          style: AppTextStyles.body2Bold),
                      Text(
                        DateFormatter.timeAgo(post.createdAt),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 4.h),
              child: Text(post.caption, style: AppTextStyles.body2),
            ),
          // Média
          if (post.hasMedia) ...[
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
              child: CachedImage(
                url:    post.mediaUrls.first,
                height: 200.h,
                width:  double.infinity,
                fit:    BoxFit.cover,
              ),
            ),
          ],
          // Footer stats
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(children: [
              Icon(Icons.favorite_border,
                  size: 16.sp, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text('${post.likesCount}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              SizedBox(width: 16.w),
              Icon(Icons.chat_bubble_outline,
                  size: 16.sp, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text('${post.commentsCount}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ]),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4 : Créer CommunitySections**

```dart
// otakuverse/lib/features/community/screens/widgets/community_sections.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/community/models/community_model.dart';
import 'community_card.dart';

class CommunitySection extends StatelessWidget {
  final String                title;
  final List<CommunityModel>  communities;
  final void Function(CommunityModel) onTap;
  final void Function(CommunityModel)? onJoin;

  const CommunitySection({
    super.key,
    required this.title,
    required this.communities,
    required this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
          child: Text(title, style: AppTextStyles.h3),
        ),
        ListView.separated(
          shrinkWrap:  true,
          physics:     const NeverScrollableScrollPhysics(),
          padding:     EdgeInsets.symmetric(horizontal: 16.w),
          itemCount:   communities.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (_, i) => CommunityCard(
            community: communities[i],
            onTap:     () => onTap(communities[i]),
            onJoin:    onJoin != null ? () => onJoin!(communities[i]) : null,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5 : Analyser**

```bash
flutter analyze lib/features/community/screens/widgets/
```

Résultat attendu : `No issues found`.

- [ ] **Step 6 : Commit**

```bash
git add lib/features/community/screens/widgets/
git commit -m "feat(community): community widgets — card, header, post card, sections"
```

---

## Task 7 : CommunityScreen (liste principale)

**Files:**
- Create: `otakuverse/lib/features/community/screens/community_screen.dart`

- [ ] **Step 1 : Créer CommunityScreen**

```dart
// otakuverse/lib/features/community/screens/community_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/connectivity_wrapper.dart';
import 'package:otakuverse/features/community/controllers/community_controller.dart';
import 'package:otakuverse/features/community/models/community_model.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';
import 'widgets/community_sections.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CommunityController>();

    return ConnectivityWrapper(
      onRetry: ctrl.loadAll,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor:           AppColors.bgPrimary,
          elevation:                 0,
          automaticallyImplyLeading: false,
          title: Text('Communautés', style: AppTextStyles.h2),
          actions: [
            IconButton(
              icon:     Icon(Icons.add, color: AppColors.textPrimary),
              onPressed: () => Get.to(() => const CreateCommunityScreen()),
              tooltip: 'Créer une communauté',
            ),
          ],
        ),
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (ctrl.errorMessage.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctrl.errorMessage.value,
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textMuted)),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: ctrl.loadAll,
                    child:     const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final isEmpty = ctrl.myCommunities.isEmpty &&
              ctrl.trendingCommunities.isEmpty &&
              ctrl.recommendedCommunities.isEmpty;

          if (isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_2_outlined,
                      size: 64.sp, color: AppColors.textMuted),
                  SizedBox(height: 16.h),
                  Text('Aucune communauté',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.textMuted)),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: () => Get.to(
                        () => const CreateCommunityScreen()),
                    child: const Text('Créer la première'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: ctrl.loadAll,
            color:     AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommunitySection(
                    title:       'Mes communautés',
                    communities: ctrl.myCommunities,
                    onTap:       _goToDetail,
                  ),
                  CommunitySection(
                    title:       'Tendances',
                    communities: ctrl.trendingCommunities,
                    onTap:       _goToDetail,
                    onJoin:      (c) => ctrl.joinCommunity(c.id),
                  ),
                  CommunitySection(
                    title:       'Recommandées pour toi',
                    communities: ctrl.recommendedCommunities,
                    onTap:       _goToDetail,
                    onJoin:      (c) => ctrl.joinCommunity(c.id),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _goToDetail(CommunityModel community) {
    Get.to(() => CommunityDetailScreen(communityId: community.id));
  }
}
```

- [ ] **Step 2 : Analyser**

```bash
flutter analyze lib/features/community/screens/community_screen.dart
```

Résultat attendu : `No issues found`.

- [ ] **Step 3 : Commit**

```bash
git add lib/features/community/screens/community_screen.dart
git commit -m "feat(community): CommunityScreen — liste avec 3 sections"
```

---

## Task 8 : CommunityDetailScreen

**Files:**
- Create: `otakuverse/lib/features/community/screens/community_detail_screen.dart`

- [ ] **Step 1 : Créer CommunityDetailScreen**

```dart
// otakuverse/lib/features/community/screens/community_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/features/community/controllers/community_controller.dart';
import 'package:otakuverse/features/community/models/community_model.dart';
import 'package:otakuverse/features/community/models/community_post_model.dart';
import 'package:otakuverse/features/community/services/community_service.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/widgets/posts/posts_card.dart'; // class PostCard
import 'widgets/community_header.dart';
import 'widgets/community_post_card.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final _service       = CommunityService();
  final _scrollCtrl    = ScrollController();

  CommunityModel?    _community;
  List<Object>       _feed     = []; // CommunityPostModel | PostModel
  bool               _isLoading   = true;
  bool               _isLoadingMore = false;
  bool               _hasMore    = true;
  int                _offset     = 0;
  static const int   _pageSize   = 20;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.85) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _offset = 0; _hasMore = true; });
    try {
      final community = await _service.getCommunityById(widget.communityId);
      if (community == null) { Get.back(); return; }

      final exclusivePosts = await _service.getCommunityPosts(
          widget.communityId, offset: 0);

      // Posts globaux tagués (depuis PostsController si disponible)
      List<PostModel> globalPosts = [];
      if (Get.isRegistered<PostsController>()) {
        globalPosts = Get.find<PostsController>()
            .posts
            .where((p) => p.communityId == widget.communityId)
            .toList();
      }

      final merged = _merge(exclusivePosts, globalPosts);
      setState(() {
        _community = community;
        _feed      = merged;
        _offset    = exclusivePosts.length;
        _hasMore   = exclusivePosts.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Erreur', 'Impossible de charger la communauté',
          backgroundColor:    AppColors.error.withValues(alpha: 0.9),
          colorText:          AppColors.white,
          snackPosition:      SnackPosition.BOTTOM);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final more = await _service.getCommunityPosts(
          widget.communityId, offset: _offset);
      if (more.length < _pageSize) setState(() => _hasMore = false);
      setState(() {
        _feed.addAll(more);
        _offset += more.length;
      });
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  List<Object> _merge(
      List<CommunityPostModel> exclusive, List<PostModel> global) {
    final all = <Object>[...exclusive, ...global];
    all.sort((a, b) {
      final ta = a is CommunityPostModel ? a.createdAt : (a as PostModel).createdAt;
      final tb = b is CommunityPostModel ? b.createdAt : (b as PostModel).createdAt;
      return tb.compareTo(ta);
    });
    return all;
  }

  Future<void> _toggleJoin() async {
    if (_community == null) return;
    final ctrl = Get.find<CommunityController>();
    if (_community!.isJoined) {
      if (_community!.membersCount <= 1) {
        Get.snackbar('Impossible', 'Supprime la communauté d\'abord',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await ctrl.leaveCommunity(_community!.id);
      setState(() => _community =
          _community!.copyWith(isJoined: false,
              membersCount: _community!.membersCount - 1));
    } else {
      await ctrl.joinCommunity(_community!.id);
      setState(() => _community =
          _community!.copyWith(isJoined: true,
              membersCount: _community!.membersCount + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_community == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            backgroundColor:     AppColors.bgPrimary,
            expandedHeight:      0,
            floating:            true,
            snap:                true,
            leading:             BackButton(
                color: AppColors.textPrimary),
            title: Text(_community!.name,
                style: AppTextStyles.h3),
          ),
          SliverToBoxAdapter(
            child: CommunityHeader(
              community:   _community!,
              onJoinLeave: _toggleJoin,
            ),
          ),
          if (_feed.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.post_add_outlined,
                        size: 48.sp, color: AppColors.textMuted),
                    SizedBox(height: 12.h),
                    Text('Sois le premier à poster ici',
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == _feed.length) {
                    return _hasMore
                        ? Padding(
                            padding: EdgeInsets.all(16.h),
                            child: const Center(
                                child: CircularProgressIndicator()),
                          )
                        : SizedBox(height: 24.h);
                  }
                  final item = _feed[i];
                  if (item is CommunityPostModel) {
                    return CommunityPostCard(post: item);
                  } else {
                    return PostCard(post: item as PostModel);
                  }
                },
                childCount: _feed.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : Analyser**

```bash
flutter analyze lib/features/community/screens/community_detail_screen.dart
```

Résultat attendu : `No issues found`.

- [ ] **Step 3 : Commit**

```bash
git add lib/features/community/screens/community_detail_screen.dart
git commit -m "feat(community): CommunityDetailScreen — feed fusionné + join/leave"
```

---

## Task 9 : CreateCommunityScreen

**Files:**
- Create: `otakuverse/lib/features/community/screens/create_community_screen.dart`

- [ ] **Step 1 : Créer CreateCommunityScreen**

```dart
// otakuverse/lib/features/community/screens/create_community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_text_styles.dart';
import 'package:otakuverse/core/widgets/button/app_button.dart';
import 'package:otakuverse/core/widgets/input/input_standard.dart';
import 'package:otakuverse/features/community/controllers/community_controller.dart';
import 'package:otakuverse/features/community/services/community_service.dart';
import 'community_detail_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _animeTagCtrl    = TextEditingController();
  final _service         = CommunityService();
  final _formKey         = GlobalKey<FormState>();

  bool _isCreating = false;
  String? _nameError;

  // Suggestions basées sur les animes favoris du profil courant
  Future<List<String>> _getAnimeSuggestions(String pattern) async {
    if (pattern.length < 2) return [];
    try {
      final uid  = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return [];
      final data = await Supabase.instance.client
          .from('profiles')
          .select('favorite_anime, favorite_genres')
          .eq('user_id', uid)
          .maybeSingle();
      if (data == null) return [];
      final animes = (data['favorite_anime'] as List<dynamic>?)
              ?.map((e) => e as String).toList() ?? [];
      final genres = (data['favorite_genres'] as List<dynamic>?)
              ?.map((e) => e as String).toList() ?? [];
      final all = [...animes, ...genres];
      return all
          .where((s) => s.toLowerCase().contains(pattern.toLowerCase()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isCreating = true; _nameError = null; });
    try {
      final community = await _service.createCommunity(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null : _descCtrl.text.trim(),
        animeTag:    _animeTagCtrl.text.trim().isEmpty
            ? null : _animeTagCtrl.text.trim(),
      );
      // Rafraîchir la liste principale
      if (Get.isRegistered<CommunityController>()) {
        Get.find<CommunityController>().loadAll();
      }
      Get.off(() => CommunityDetailScreen(communityId: community.id));
    } catch (e) {
      final msg = e.toString().contains('communities_name_unique')
          ? 'Ce nom est déjà pris'
          : 'Erreur lors de la création';
      setState(() { _nameError = msg; _isCreating = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _animeTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor:           AppColors.bgPrimary,
        elevation:                 0,
        title: Text('Nouvelle communauté', style: AppTextStyles.h3),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              InputStandard(
                controller: _nameCtrl,
                label:      'Nom *',
                hintText:   'Ex: One Piece Fan Club',
                errorText:  _nameError,
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Minimum 3 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              // Description
              InputStandard(
                controller: _descCtrl,
                label:      'Description',
                hintText:   'Décris ta communauté...',
                maxLines:   3,
              ),
              SizedBox(height: 16.h),
              // Anime tag avec typeahead
              Text('Anime / Manga associé', style: AppTextStyles.label),
              SizedBox(height: 6.h),
              TypeAheadField<String>(
                controller: _animeTagCtrl,
                suggestionsCallback: _getAnimeSuggestions,
                builder: (context, controller, focusNode) => TextField(
                  controller: controller,
                  focusNode:  focusNode,
                  style:      AppTextStyles.body2
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ex: One Piece',
                    hintStyle: AppTextStyles.body2
                        .copyWith(color: AppColors.textMuted),
                    filled:      true,
                    fillColor:   AppColors.bgCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                itemBuilder: (_, suggestion) => ListTile(
                  title: Text(suggestion, style: AppTextStyles.body2),
                  tileColor: AppColors.bgCard,
                ),
                onSelected: (s) => _animeTagCtrl.text = s,
                emptyBuilder: (_) => const SizedBox.shrink(),
              ),
              SizedBox(height: 32.h),
              AppButton(
                label:     'Créer la communauté',
                isLoading: _isCreating,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Analyser**

```bash
flutter analyze lib/features/community/screens/create_community_screen.dart
```

Résultat attendu : `No issues found`.

- [ ] **Step 3 : Commit**

```bash
git add lib/features/community/screens/create_community_screen.dart
git commit -m "feat(community): CreateCommunityScreen — formulaire avec typeahead"
```

---

## Task 10 : Wire-up — navigation, main.dart, RealtimeService

**Files:**
- Modify: `otakuverse/lib/features/navigation/navigation_page.dart`
- Modify: `otakuverse/lib/main.dart`
- Modify: `otakuverse/lib/core/services/realtime_service.dart`
- Modify: `otakuverse/lib/features/feed/models/post_model.dart`

- [ ] **Step 1 : Ajouter communityId à PostModel**

Dans `otakuverse/lib/features/feed/models/post_model.dart`, ajouter le champ `communityId` :

Après `final String? musicImageUrl;` (ligne ~20), ajouter :
```dart
  final String? communityId;
```

Dans le constructeur, ajouter après `this.musicImageUrl,` :
```dart
    this.communityId,
```

Dans `fromJson`, ajouter après `musicImageUrl: json['music_image_url'] as String?,` :
```dart
      communityId: json['community_id'] as String?,
```

Dans `copyWith`, ajouter le paramètre `String? communityId` et `communityId: communityId ?? this.communityId,`.

- [ ] **Step 2 : Remplacer le placeholder dans NavigationPage**

Dans `otakuverse/lib/features/navigation/navigation_page.dart`, remplacer :

```dart
// Avant
import 'package:otakuverse/features/community/screens/community_screen.dart';
// (si l'import n'est pas là, l'ajouter avec les autres imports)
```

Remplacer dans `_pages` :
```dart
// Avant
const _ComingSoon(label: 'Community', icon: Icons.groups_2_rounded),

// Après
const CommunityScreen(),
```

Ajouter l'import en haut du fichier :
```dart
import 'package:otakuverse/features/community/screens/community_screen.dart';
```

- [ ] **Step 3 : Ajouter CommunityBinding dans main.dart**

Dans `otakuverse/lib/main.dart`, ajouter l'import :
```dart
import 'package:otakuverse/features/community/bindings/community_binding.dart';
```

Modifier la page home dans `_pages` :
```dart
// Avant
GetPage(
  name:     Routes.home,
  page:     () => const NavigationPage(),
  bindings: [AuthBinding(), FeedBinding()],
),

// Après
GetPage(
  name:     Routes.home,
  page:     () => const NavigationPage(),
  bindings: [AuthBinding(), FeedBinding(), CommunityBinding()],
),
```

- [ ] **Step 4 : Ajouter le channel community_members dans RealtimeService**

Dans `otakuverse/lib/core/services/realtime_service.dart`, ajouter après la déclaration `RealtimeChannel? _profileChannel;` :

```dart
  RealtimeChannel? _communityMembersChannel;
```

Ajouter ces deux méthodes publiques à la fin de la classe :

```dart
  Future<void> subscribeCommunityMembers(
      String communityId, void Function(int) onCountChanged) async {
    await _communityMembersChannel?.unsubscribe();
    _communityMembersChannel = _supabase
        .channel('community_members:$communityId')
        .onPostgresChanges(
          event:    PostgresChangeEvent.all,
          schema:   'public',
          table:    'community_members',
          filter:   'community_id=eq.$communityId',
          callback: (_) async {
            try {
              final data = await _supabase
                  .from('communities')
                  .select('members_count')
                  .eq('id', communityId)
                  .single();
              onCountChanged(data['members_count'] as int);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  Future<void> unsubscribeCommunityMembers() async {
    await _communityMembersChannel?.unsubscribe();
    _communityMembersChannel = null;
  }
```

- [ ] **Step 5 : Lancer l'app et vérifier l'onglet Community**

```bash
flutter run
```

Naviguer vers l'onglet Community. Résultat attendu : `CommunityScreen` s'affiche avec les 3 sections (vides si pas de données en base). Pas de crash.

- [ ] **Step 6 : Analyser tout le projet**

```bash
flutter analyze
```

Résultat attendu : `No issues found`.

- [ ] **Step 7 : Commit**

```bash
git add lib/features/navigation/navigation_page.dart \
        lib/main.dart \
        lib/core/services/realtime_service.dart \
        lib/features/feed/models/post_model.dart
git commit -m "feat(community): wire navigation, bindings, realtime channel"
```

---

## Task 11 : Modifications CreatePostScreen — sélecteur communauté

**Files:**
- Modify: `otakuverse/lib/features/feed/screens/create_post_screen.dart`

- [ ] **Step 1 : Ajouter les imports et champs d'état**

Dans `_CreatePostScreenState`, ajouter les champs après `PollData? _pollData;` :

```dart
  String? _selectedCommunityId;
  String? _selectedCommunityName;
  bool    _isExclusivePost = true;

  final _communityService = CommunityService();
  List<CommunityModel> _myCommunities = [];
```

Ajouter les imports en haut du fichier :
```dart
import 'package:otakuverse/features/community/models/community_model.dart';
import 'package:otakuverse/features/community/services/community_service.dart';
```

- [ ] **Step 2 : Charger les communautés dans initState**

Dans `initState`, après `if (widget.preselectedFiles.isNotEmpty) _loadPreselected();`, ajouter :

```dart
    _loadMyCommunities();
```

Ajouter la méthode :

```dart
  Future<void> _loadMyCommunities() async {
    try {
      final list = await _communityService.getMyCommunities();
      if (mounted) setState(() => _myCommunities = list);
    } catch (_) {}
  }
```

- [ ] **Step 3 : Ajouter le sélecteur de communauté dans le build**

Dans le build de `CreatePostScreen`, ajouter le widget sélecteur juste avant le `ShareButton`. Trouver l'endroit où `ShareButton` est construit et insérer avant lui :

```dart
// Sélecteur communauté — visible seulement si l'utilisateur est dans au moins une communauté
if (_myCommunities.isNotEmpty) ...[
  const Divider(height: 1),
  Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur
        DropdownButton<String?>(
          value:           _selectedCommunityId,
          dropdownColor:   AppColors.bgCard,
          isExpanded:      true,
          underline:       const SizedBox.shrink(),
          hint: Text('Partager dans une communauté (optionnel)',
              style: AppTextStyles.body2
                  .copyWith(color: AppColors.textMuted)),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Aucune communauté',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textMuted)),
            ),
            ..._myCommunities.map((c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.name, style: AppTextStyles.body2),
            )),
          ],
          onChanged: (val) => setState(() {
            _selectedCommunityId   = val;
            _selectedCommunityName = val == null
                ? null
                : _myCommunities.firstWhere((c) => c.id == val).name;
            if (val == null) _isExclusivePost = true;
          }),
        ),
        // Toggle exclusif/global — visible seulement si une communauté est sélectionnée
        if (_selectedCommunityId != null)
          SwitchListTile(
            value:          _isExclusivePost,
            onChanged:      (v) => setState(() => _isExclusivePost = v),
            title:          Text('Post exclusif à la communauté',
                style: AppTextStyles.body2),
            subtitle:       Text(
              _isExclusivePost
                  ? 'Visible uniquement dans ${_selectedCommunityName ?? 'la communauté'}'
                  : 'Visible dans le feed global ET la communauté',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted),
            ),
            activeColor:    AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    ),
  ),
],
```

- [ ] **Step 4 : Modifier la logique de publication**

Dans la méthode de publication (chercher `_postsCtrl.createPost` ou le bouton de partage), modifier pour gérer le cas communauté exclusive :

```dart
Future<void> _publish() async {
  if (_isPublishing) return;
  setState(() => _isPublishing = true);

  try {
    final uploadedUrls = await _uploadService.uploadMultiple(_selectedImages);

    if (_selectedCommunityId != null && _isExclusivePost) {
      // Post exclusif → community_posts
      await _communityService.createCommunityPost(
        communityId: _selectedCommunityId!,
        caption:     _captionCtrl.text.trim(),
        mediaUrls:   uploadedUrls,
      );
    } else {
      // Post normal (avec ou sans community_id)
      await _postsCtrl.createPost(
        caption:      _captionCtrl.text.trim(),
        mediaUrls:    uploadedUrls,
        location:     _locationCtrl.text.trim().isEmpty
            ? null : _locationCtrl.text.trim(),
        allowComments: _allowComments,
        musicTitle:    _selectedSong?.title,
        musicArtist:   _selectedSong?.artist,
        musicTrackId:  _selectedSong?.id,
        musicPreviewUrl: _selectedSong?.previewUrl,
        musicImageUrl:   _selectedSong?.imageUrl,
        pollQuestion:    _pollData?.question,
        pollOptionA:     _pollData?.optionA,
        pollOptionB:     _pollData?.optionB,
        pollDurationHours: _pollData?.durationHours,
        communityId:   _selectedCommunityId,
      );
    }

    Get.back(result: true);
    Get.snackbar('Publié !', 'Ton post est en ligne',
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText:       AppColors.white,
        snackPosition:   SnackPosition.BOTTOM);
  } catch (e) {
    Get.snackbar('Erreur', 'Impossible de publier',
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText:       AppColors.white,
        snackPosition:   SnackPosition.BOTTOM);
    debugPrint('🔴 _publish: $e');
  } finally {
    if (mounted) setState(() => _isPublishing = false);
  }
}
```

- [ ] **Step 5 : Mettre à jour PostService pour accepter communityId**

Dans `PostService.createPost`, ajouter le paramètre `String? communityId` et l'inclure dans le payload :

```dart
// Ajouter dans la signature :
String? communityId,

// Ajouter dans le Map d'insert :
'community_id': communityId,
```

Faire de même dans `PostsController.createPost`.

- [ ] **Step 6 : Analyser**

```bash
flutter analyze lib/features/feed/screens/create_post_screen.dart
```

Résultat attendu : `No issues found`.

- [ ] **Step 7 : Lancer tous les tests**

```bash
flutter test
```

Résultat attendu : `All tests passed`.

- [ ] **Step 8 : Commit final**

```bash
git add lib/features/feed/screens/create_post_screen.dart \
        lib/features/feed/services/post_service.dart \
        lib/features/feed/controllers/post_controller.dart
git commit -m "feat(community): CreatePostScreen — sélecteur communauté + toggle exclusif"
```

---

## Task 12 : Push et merge vers version-2

- [ ] **Step 1 : Lancer l'analyse complète et tous les tests**

```bash
flutter analyze && flutter test
```

Résultat attendu : `No issues found` + `All tests passed`.

- [ ] **Step 2 : Push la feature branch**

```bash
git push origin feature/community-phase1
```

- [ ] **Step 3 : Merger dans version-2**

```bash
git checkout version-2
git merge feature/community-phase1 --no-ff -m "feat: merge Community Phase 1"
git push origin version-2
```

---

## Récapitulatif des commits

| # | Message | Contenu |
|---|---------|---------|
| 1 | `feat(community): add SQL migration` | Tables + triggers + RLS |
| 2 | `feat(community): CommunityModel` | Model + fixtures + tests |
| 3 | `feat(community): CommunityPostModel` | Model + fixtures + tests |
| 4 | `feat(community): Repository + Service` | Data layer |
| 5 | `feat(community): Controller + Binding + tests` | State management |
| 6 | `feat(community): community widgets` | Card, header, post card, sections |
| 7 | `feat(community): CommunityScreen` | Liste principale |
| 8 | `feat(community): CommunityDetailScreen` | Feed fusionné |
| 9 | `feat(community): CreateCommunityScreen` | Formulaire |
| 10 | `feat(community): wire navigation` | Navigation + main.dart + Realtime |
| 11 | `feat(community): CreatePostScreen` | Sélecteur communauté |
| 12 | `feat: merge Community Phase 1` | Merge dans version-2 |
