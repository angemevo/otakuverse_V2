import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';

class StoryService {
  final _supabase = Supabase.instance.client;

  String get _uid =>
      _supabase.auth.currentUser!.id;

  // ─── CHARGER LES STORIES DU FEED ─────────────────────────────────
  Future<List<StoryGroup>> getFeedStories() async {
    try {
      final followingIds = await _getFollowingIds();
      final viewedIds    = await _getViewedStoryIds();

      // ─ Étape 1 : Mes stories + abonnés ──────────────────────────
      final myAndFollowingIds = [...followingIds, _uid];

      final myAndFollowingStories = await _fetchStories(
        userIds:   myAndFollowingIds,
        viewedIds: viewedIds,
      );

      // ─ Étape 2 : 5 stories de non-abonnés ───────────────────────
      // ✅ Exclure : moi, mes abonnés, et les gens sans stories
      final discoveryStories =
          await _fetchDiscoveryStories(
        excludeIds: myAndFollowingIds,
        viewedIds:  viewedIds,
        limit:      5,
      );

      // ─ Étape 3 : Stories sponsorisées (pubs) ────────────────────
      final sponsoredGroups = _buildSponsoredGroups();

      // ─ Étape 4 : Grouper et trier ────────────────────────────────
      final allGroups = _groupByUser(
        myAndFollowingStories,
        isDiscovery: false,
      );

      final discoveryGroups = _groupByUser(
        discoveryStories,
        isDiscovery: true,
      );

      // ─ Ordre final ───────────────────────────────────────────────
      // ✅ 1. Mes stories
      // ✅ 2. Abonnés (non vues en premier)
      // ✅ 3. Découverte (5 non-abonnés)
      // ✅ 4. Pubs
      final result = [
        ...allGroups,
        ...discoveryGroups,
        ...sponsoredGroups,
      ];

      debugPrint('✅ Stories: '
          '${allGroups.length} abonnés + '
          '${discoveryGroups.length} découverte + '
          '${sponsoredGroups.length} pubs');

      return result;
    } catch (e) {
      debugPrint('❌ getFeedStories: $e');
      return [];
    }
  }

  // ─── FETCH STORIES POUR UNE LISTE D'IDs ──────────────────────────
  Future<List<StoryModel>> _fetchStories({
    required List<String> userIds,
    required Set<String>  viewedIds,
  }) async {
    if (userIds.isEmpty) return [];

    final storiesData = await _supabase
        .from('stories')
        .select()
        .inFilter('user_id', userIds)
        .gt('expires_at',
            DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    if ((storiesData as List).isEmpty) return [];

    // ✅ Profils en une seule requête
    final ids = storiesData
        .map((s) => s['user_id'] as String)
        .toSet()
        .toList();

    final profilesMap =
        await _fetchProfilesMap(ids);

    return storiesData.map((s) {
      final map = s;
      return StoryModel.fromJson({
        ...map,
        'profiles': profilesMap[map['user_id']],
        'is_viewed': viewedIds.contains(
            map['id'] as String),
      });
    }).toList();
  }

  // ─── FETCH STORIES DE DÉCOUVERTE (non-abonnés) ───────────────────
  Future<List<StoryModel>> _fetchDiscoveryStories({
    required List<String> excludeIds,
    required Set<String>  viewedIds,
    required int          limit,
  }) async {
    try {
      // ✅ Récupérer des users aléatoires avec stories actives
      // qui ne sont pas dans excludeIds
      final storiesData = await _supabase
          .from('stories')
          .select()
          .not('user_id', 'in',
              '(${excludeIds.join(',')})')
          .gt('expires_at',
              DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit * 5); // ✅ Plus large pour diversifier

      if ((storiesData as List).isEmpty) return [];

      // ✅ Garder max 1 story par user pour la diversité
      final seenUsers  = <String>{};
      final filtered   = <Map<String, dynamic>>[];

      for (final s in storiesData) {
        final userId = s['user_id'] as String;
        if (!seenUsers.contains(userId) &&
            filtered.length < limit) {
          seenUsers.add(userId);
          filtered.add(s);
        }
      }

      if (filtered.isEmpty) return [];

      final ids = filtered
          .map((s) => s['user_id'] as String)
          .toList();

      final profilesMap =
          await _fetchProfilesMap(ids);

      return filtered.map((map) {
        return StoryModel.fromJson({
          ...map,
          'profiles':    profilesMap[map['user_id']],
          'is_viewed':   viewedIds.contains(
              map['id'] as String),
          'is_discovery': true, // ✅ Flag découverte
        });
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Discovery stories: $e');
      return [];
    }
  }

  // ─── STORIES SPONSORISÉES ────────────────────────────────────────
  // ✅ Pour l'instant simulées — à brancher sur une vraie table ads
  List<StoryGroup> _buildSponsoredGroups() {
    // TODO: Brancher sur une table `ads` ou `sponsored_stories`
    // Pour l'instant retourne une liste vide
    // → Décommenter et adapter quand les pubs seront prêtes
    return [];

    /* Exemple futur :
    return [
      StoryGroup(
        userId:      'ad_1',
        username:    'otakuverse_ads',
        displayName: 'Sponsorisé',
        avatarUrl:   null,
        stories:     [...],
        hasUnviewed: true,
        isMe:        false,
        isSponsored: true,
      ),
    ];
    */
  }

  // ─── GROUPER PAR UTILISATEUR ─────────────────────────────────────
  List<StoryGroup> _groupByUser(
    List<StoryModel> stories, {
    required bool isDiscovery,
  }) {
    if (stories.isEmpty) return [];

    final Map<String, List<StoryModel>> grouped = {};

    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    final groups = grouped.entries.map((e) {
      final userStories = e.value
        ..sort((a, b) =>
            a.createdAt.compareTo(b.createdAt));
      final first = userStories.first;

      return StoryGroup(
        userId:      e.key,
        username:    first.username    ?? '',
        displayName: first.displayName,
        avatarUrl:   first.avatarUrl,
        stories:     userStories,
        hasUnviewed: userStories
            .any((s) => !s.isViewed),
        isMe:        e.key == _uid,
        isDiscovery: isDiscovery,
      );
    }).toList();

    // ✅ Mes stories en premier, puis non vues
    groups.sort((a, b) {
      if (a.isMe) return -1;
      if (b.isMe) return 1;
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return b.latest.createdAt
          .compareTo(a.latest.createdAt);
    });

    return groups;
  }

  // ─── FETCH PROFILES MAP ──────────────────────────────────────────
  Future<Map<String, Map<String, dynamic>>>
      _fetchProfilesMap(List<String> ids) async {
    if (ids.isEmpty) return {};

    final profilesData = await _supabase
        .from('profiles')
        .select(
            'id, username, display_name, avatar_url')
        .inFilter('id', ids);

    return {
      for (final p in profilesData as List)
        p['id'] as String: p as Map<String, dynamic>,
    };
  }

  // ─── MARQUER COMME VUE ───────────────────────────────────────────
  Future<void> markAsViewed(String storyId) async {
    try {
      await _supabase.from('story_views').upsert({
        'story_id':  storyId,
        'viewer_id': _uid,
      });
    } catch (e) {
      debugPrint('❌ markAsViewed: $e');
    }
  }

  // ─── PUBLIER IMAGE ───────────────────────────────────────────────
  Future<StoryModel?> createImageStory(
      XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final ext   = file.path
          .split('.')
          .last
          .toLowerCase();
      final path  =
          'stories/$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('stories')
          .uploadBinary(path, bytes,
              fileOptions:
                  const FileOptions(upsert: false));

      final url = _supabase.storage
          .from('stories')
          .getPublicUrl(path);

      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':    _uid,
            'media_url':  url,
            'media_type': 'image',
            'duration':   5,
          })
          .select()
          .single();

      final profile = await _supabase
          .from('profiles')
          .select(
              'id, username, display_name, avatar_url')
          .eq('id', _uid)
          .single();

      return StoryModel.fromJson({
        ...data,
        'profiles': profile,
      });
    } catch (e) {
      debugPrint('❌ createImageStory: $e');
      return null;
    }
  }

  // ─── PUBLIER TEXTE ───────────────────────────────────────────────
  Future<StoryModel?> createTextStory({
    required String text,
    required String bgColor,
  }) async {
    try {
      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':      _uid,
            'media_type':   'text',
            'text_content': text,
            'bg_color':     bgColor,
            'duration':     7,
          })
          .select()
          .single();

      final profile = await _supabase
          .from('profiles')
          .select(
              'id, username, display_name, avatar_url')
          .eq('id', _uid)
          .single();

      return StoryModel.fromJson({
        ...data,
        'profiles': profile,
      });
    } catch (e) {
      debugPrint('❌ createTextStory: $e');
      return null;
    }
  }

  // ─── PUBLIER VIDÉO ───────────────────────────────────────────────
  Future<StoryModel?> createVideoStory(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final ext   = file.path
          .split('.').last.toLowerCase();
      final path  =
          'stories/$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('stories')
          .uploadBinary(path, bytes,
              fileOptions:
                  const FileOptions(upsert: false));

      final url = _supabase.storage
          .from('stories')
          .getPublicUrl(path);

      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':    _uid,
            'media_url':  url,
            'media_type': 'video', // ✅ video
            'duration':   15,      // ✅ 15s pour vidéo
          })
          .select()
          .single();

      final profile = await _supabase
          .from('profiles')
          .select(
              'id, username, display_name, avatar_url')
          .eq('id', _uid)
          .single();

      return StoryModel.fromJson({
        ...data,
        'profiles': profile,
      });
    } catch (e) {
      debugPrint('❌ createVideoStory: $e');
      return null;
    }
  }
  

  // ─── SUPPRIMER ───────────────────────────────────────────────────
  Future<void> deleteStory(String storyId) async {
    await _supabase
        .from('stories')
        .delete()
        .eq('id', storyId)
        .eq('user_id', _uid);
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  Future<List<String>> _getFollowingIds() async {
    final data = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', _uid);
    return (data as List)
        .map((e) => e['following_id'] as String)
        .toList();
  }

  Future<Set<String>> _getViewedStoryIds() async {
    final data = await _supabase
        .from('story_views')
        .select('story_id')
        .eq('viewer_id', _uid);
    return (data as List)
        .map((e) => e['story_id'] as String)
        .toSet();
  }
}