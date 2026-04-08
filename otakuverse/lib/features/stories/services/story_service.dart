import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';

class StoryService {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ─── CHARGER LES STORIES DU FEED ─────────────────────────────────
  Future<List<StoryGroup>> getFeedStories() async {
    try {
      final followingIds = await _getFollowingIds();
      final viewedIds    = await _getViewedStoryIds();
      final allIds       = [...followingIds, _uid];

      final myAndFollowingStories = await _fetchStories(
        userIds:   allIds,
        viewedIds: viewedIds,
      );

      final discoveryStories =
          await _fetchDiscoveryStories(
        excludeIds: allIds,
        viewedIds:  viewedIds,
        limit:      5,
      );

      // ✅ Utiliser la nouvelle méthode avec profils directs
      final allGroups = await _groupByUserWithProfiles(
        myAndFollowingStories,
        isDiscovery: false,
      );

      final discoveryGroups = await _groupByUserWithProfiles(
        discoveryStories,
        isDiscovery: true,
      );

      debugPrint('✅ Stories: '
          '${allGroups.length} abonnés + '
          '${discoveryGroups.length} découverte');

      return [...allGroups, ...discoveryGroups];
    } catch (e) {
      debugPrint('❌ getFeedStories: $e');
      return [];
    }
  }

  // ─── FETCH STORIES AVEC JOIN PROFIL ──────────────────────────────
  // ✅ Grâce à la FK vers profiles, le join est automatique
  Future<List<StoryModel>> _fetchStories({
    required List<String> userIds,
    required Set<String>  viewedIds,
  }) async {
    if (userIds.isEmpty) return [];

    // ✅ Join direct — plus besoin de requête séparée
    final data = await _supabase
        .from('stories')
        .select('''
          *,
          profiles!inner(
            user_id,
            username,
            display_name,
            avatar_url
          )
        ''')
        .inFilter('user_id', userIds)
        .gt('expires_at',
            DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (data as List).map((s) {
      final map = s as Map<String, dynamic>;
      return StoryModel.fromJson({
        ...map,
        'is_viewed': viewedIds.contains(
            map['id'] as String),
      });
    }).toList();
  }

  // ─── FETCH STORIES DÉCOUVERTE ────────────────────────────────────
  Future<List<StoryModel>> _fetchDiscoveryStories({
    required List<String> excludeIds,
    required Set<String>  viewedIds,
    required int          limit,
  }) async {
    try {
      if (excludeIds.isEmpty) return [];

      final data = await _supabase
          .from('stories')
          .select('''
            *,
            profiles!inner(
              user_id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .not('user_id', 'in',
              '(${excludeIds.join(',')})')
          .gt('expires_at',
              DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit * 5);

      if ((data as List).isEmpty) return [];

      // ✅ 1 story max par user pour la découverte
      final seenUsers = <String>{};
      final filtered  = <Map<String, dynamic>>[];

      for (final s in data) {
        final userId = s['user_id'] as String;
        if (!seenUsers.contains(userId) &&
            filtered.length < limit) {
          seenUsers.add(userId);
          filtered.add(s);
        }
      }

      return filtered.map((map) {
        return StoryModel.fromJson({
          ...map,
          'is_viewed':    viewedIds.contains(
              map['id'] as String),
          'is_discovery': true,
        });
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Discovery stories: $e');
      return [];
    }
  }

  // ─── GROUPER PAR UTILISATEUR ─────────────────────────────────────
  Future<List<StoryGroup>> _groupByUserWithProfiles(
    List<StoryModel> stories, {
    required bool isDiscovery,
  }) async {
    if (stories.isEmpty) return [];

    // ─ Grouper les stories ─────────────────────────────────────────
    final Map<String, List<StoryModel>> grouped = {};
    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    // ─ Récupérer les profils directement ──────────────────────────
    // ✅ Source de vérité = table profiles
    final userIds = grouped.keys.toList();
    final profilesData = await _supabase
        .from('profiles')
        .select('user_id, username, display_name, avatar_url')
        .inFilter('user_id', userIds);

    final profilesMap = {
      for (final p in profilesData as List)
        p['user_id'] as String: p as Map<String, dynamic>,
    };

    // ─ Construire les groupes ──────────────────────────────────────
    final groups = grouped.entries.map((e) {
      final userStories = e.value
        ..sort((a, b) =>
            a.createdAt.compareTo(b.createdAt));

      // ✅ Profil depuis la table profiles — pas depuis StoryModel
      final profile = profilesMap[e.key];

      return StoryGroup(
        userId:      e.key,
        // ✅ Données fraîches depuis profiles
        username:    profile?['username']     as String? ?? '',
        displayName: profile?['display_name'] as String?,
        avatarUrl:   profile?['avatar_url']   as String?,
        stories:     userStories,
        hasUnviewed: userStories.any((s) => !s.isViewed),
        isMe:        e.key == _uid,
        isDiscovery: isDiscovery,
      );
    }).toList();

    groups.sort((a, b) {
      if (a.isMe)  return -1;
      if (b.isMe)  return 1;
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return b.latest.createdAt
          .compareTo(a.latest.createdAt);
    });

    return groups;
  }

  // ─── PUBLIER IMAGE ───────────────────────────────────────────────
  Future<StoryModel?> createImageStory(
      XFile file) async {
    try {
      final url = await _uploadFile(file, 'image');

      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':    _uid,
            'media_url':  url,
            'media_type': 'image',
            'duration':   5,
          })
          // ✅ Join direct dans le select retour
          .select('''
            *,
            profiles!inner(
              user_id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .single();

      return StoryModel.fromJson(
          data);
    } catch (e) {
      debugPrint('❌ createImageStory: $e');
      return null;
    }
  }

  // ─── PUBLIER VIDÉO ───────────────────────────────────────────────
  Future<StoryModel?> createVideoStory(
      XFile file) async {
    try {
      final url = await _uploadFile(file, 'video');

      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':    _uid,
            'media_url':  url,
            'media_type': 'video',
            'duration':   15,
          })
          .select('''
            *,
            profiles!inner(
              user_id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .single();

      return StoryModel.fromJson(
          data);
    } catch (e) {
      debugPrint('❌ createVideoStory: $e');
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
          .select('''
            *,
            profiles!inner(
              user_id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .single();

      return StoryModel.fromJson(
          data);
    } catch (e) {
      debugPrint('❌ createTextStory: $e');
      return null;
    }
  }

  // ─── PUBLIER MULTI-MÉDIAS ────────────────────────────────────────
  Future<StoryModel?> createMultiMediaStory(
      List<StoryMediaItem> items) async {
    try {
      final urls  = <String>[];
      final types = <String>[];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final url  = await _uploadFile(
            item.file,
            item.isVideo ? 'video' : 'image',
            suffix: '_$i');
        urls.add(url);
        types.add(item.isVideo ? 'video' : 'image');
      }

      final hasVideo = types.contains('video');

      final data = await _supabase
          .from('stories')
          .insert({
            'user_id':     _uid,
            'media_url':   urls.first,
            'media_type':  types.first,
            'media_urls':  urls,
            'media_types': types,
            'duration':    hasVideo ? 15 : 5,
          })
          .select('''
            *,
            profiles!inner(
              user_id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .single();

      return StoryModel.fromJson(
          data);
    } catch (e) {
      debugPrint('❌ createMultiMediaStory: $e');
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

  // ─── UPLOAD FICHIER ──────────────────────────────────────────────
  // ✅ Méthode centralisée pour tous les uploads
  Future<String> _uploadFile(
      XFile file, String type, {String suffix = ''}) async {
    final bytes = await file.readAsBytes();
    final ext   = file.path.split('.').last.toLowerCase();
    final ts    = DateTime.now().millisecondsSinceEpoch;
    final path  = 'stories/$_uid/${ts}$suffix.$ext';

    await _supabase.storage
        .from('stories')
        .uploadBinary(path, bytes,
            fileOptions:
                const FileOptions(upsert: false));

    return _supabase.storage
        .from('stories')
        .getPublicUrl(path);
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

  Future<void> markAsViewed(String storyId) async {
    try {
      await _supabase
      .from('story_views')
      .insert({
        'story_id': storyId,
        'viewer_id': _uid
      },
      defaultToNull: false,
      ).select();
    } catch (e) {
      if (e.toString().contains('23505') ||
          e.toString().contains('duplicate')) {
        debugPrint('⚠️ Story déjà marquée comme vue: $storyId');
        return;
      }
      debugPrint('❌ markAsViewed: $e');
    }
  }
}


// ─── MODÈLE MEDIA ITEM ───────────────────────────────────────────────
class StoryMediaItem {
  final XFile file;
  final bool  isVideo;
  final Uint8List bytes;
  const StoryMediaItem({
    required this.file,
    required this.isVideo,
    required this.bytes,
  });
}