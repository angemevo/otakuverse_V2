import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';

class StoryController extends GetxController {
  final _service  = StoryService();
  final _supabase = Supabase.instance.client;

  final RxList<StoryGroup> storyGroups = <StoryGroup>[].obs;
  final RxBool             isLoading   = false.obs;
  final RxBool             isUploading = false.obs;

  // ✅ Channel Realtime
  RealtimeChannel? _storiesChannel;

  @override
  void onInit() {
    super.onInit();
    loadStories();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _storiesChannel?.unsubscribe();
    super.onClose();
  }

  // ─── REALTIME ────────────────────────────────────────────────────
  void _subscribeRealtime() {
    _storiesChannel = _supabase
        .channel('public:stories')
        .onPostgresChanges(
          event:    PostgresChangeEvent.insert,
          schema:   'public',
          table:    'stories',
          callback: (_) {
            debugPrint('🆕 Realtime: nouvelle story');
            loadStories();
          },
        )
        .onPostgresChanges(
          event:    PostgresChangeEvent.delete,
          schema:   'public',
          table:    'stories',
          callback: (payload) {
            debugPrint('🗑 Realtime: story supprimée');
            final deletedId =
                payload.oldRecord['id'] as String?;
            if (deletedId != null) {
              _removeStoryLocally(deletedId);
            }
          },
        )
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'story_views',
          callback: (payload) {
            // ✅ Mettre à jour le compteur de vues
            final storyId =
                payload.newRecord['story_id'] as String?;
            if (storyId != null) {
              _incrementViewCount(storyId);
            }
          },
        );

    _storiesChannel!.subscribe((status, [error]) {
      debugPrint('📡 Stories Realtime: $status');
    });
  }

  // ─── RETIRER UNE STORY LOCALEMENT ────────────────────────────────
  void _removeStoryLocally(String storyId) {
    for (int g = 0; g < storyGroups.length; g++) {
      final group = storyGroups[g];
      final idx   = group.stories
          .indexWhere((s) => s.id == storyId);

      if (idx == -1) continue;

      final updated = List<StoryModel>.from(group.stories)
        ..removeAt(idx);

      if (updated.isEmpty) {
        // ✅ Plus de stories → retirer le groupe
        storyGroups.removeAt(g);
      } else {
        storyGroups[g] = StoryGroup(
          userId:      group.userId,
          username:    group.username,
          displayName: group.displayName,
          avatarUrl:   group.avatarUrl,
          stories:     updated,
          hasUnviewed: updated.any((s) => !s.isViewed),
          isMe:        group.isMe,
          isDiscovery: group.isDiscovery,
        );
      }
      break;
    }
  }

  // ─── INCRÉMENTER LES VUES ────────────────────────────────────────
  void _incrementViewCount(String storyId) {
    for (int g = 0; g < storyGroups.length; g++) {
      final group = storyGroups[g];
      final idx   = group.stories
          .indexWhere((s) => s.id == storyId);

      if (idx == -1) continue;

      final updated =
          List<StoryModel>.from(group.stories);
      updated[idx] = updated[idx].copyWith(
        viewsCount: updated[idx].viewsCount + 1,
      );

      storyGroups[g] = StoryGroup(
        userId:      group.userId,
        username:    group.username,
        displayName: group.displayName,
        avatarUrl:   group.avatarUrl,
        stories:     updated,
        hasUnviewed: updated.any((s) => !s.isViewed),
        isMe:        group.isMe,
        isDiscovery: group.isDiscovery,
      );
      break;
    }
  }

  // ─── CHARGER ─────────────────────────────────────────────────────
  Future<void> loadStories() async {
    isLoading.value = true;
    try {
      final groups = await _service.getFeedStories();
      storyGroups.assignAll(groups);
    } catch (e) {
      debugPrint('❌ loadStories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── MARQUER VUE ─────────────────────────────────────────────────
  Future<void> markAsViewed(String storyId) async {
    // ✅ Update optimiste local
    _markViewedLocally(storyId);
    // ✅ Persister en DB
    await _service.markAsViewed(storyId);
  }

  void _markViewedLocally(String storyId) {
    for (int g = 0; g < storyGroups.length; g++) {
      final group = storyGroups[g];
      final idx   = group.stories
          .indexWhere((s) => s.id == storyId);

      if (idx == -1) continue;

      final updated =
          List<StoryModel>.from(group.stories);
      updated[idx] = updated[idx].copyWith(
          isViewed: true);

      storyGroups[g] = StoryGroup(
        userId:      group.userId,
        username:    group.username,
        displayName: group.displayName,
        avatarUrl:   group.avatarUrl,
        stories:     updated,
        hasUnviewed: updated.any((s) => !s.isViewed),
        isMe:        group.isMe,
        isDiscovery: group.isDiscovery,
      );
      break;
    }
  }

  // ─── PUBLIER IMAGE ───────────────────────────────────────────────
  Future<bool> publishImageStory(XFile file) async =>
      _publishMedia(file, isVideo: false);

  // ─── PUBLIER VIDÉO ───────────────────────────────────────────────
  Future<bool> publishVideoStory(XFile file) async =>
      _publishMedia(file, isVideo: true);

  Future<bool> _publishMedia(
      XFile file, {required bool isVideo}) async {
    isUploading.value = true;
    try {
      final story = isVideo
          ? await _service.createVideoStory(file)
          : await _service.createImageStory(file);

      if (story != null) {
        // ✅ Realtime rechargera automatiquement
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ publishMedia: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // ─── PUBLIER TEXTE ───────────────────────────────────────────────
  Future<bool> publishTextStory({
    required String text,
    required String bgColor,
  }) async {
    isUploading.value = true;
    try {
      final story = await _service.createTextStory(
        text:    text,
        bgColor: bgColor,
      );
      return story != null;
    } catch (e) {
      debugPrint('❌ publishTextStory: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // ─── PUBLIER MULTI-MÉDIAS ────────────────────────────────────────
  Future<bool> publishMultiStory(
      List<StoryMediaItem> items) async {
    isUploading.value = true;
    try {
      final story =
          await _service.createMultiMediaStory(items);
      return story != null;
    } catch (e) {
      debugPrint('❌ publishMultiStory: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // ─── SUPPRIMER ───────────────────────────────────────────────────
  Future<void> deleteStory(String storyId) async {
    // ✅ Optimiste — Realtime confirmera
    _removeStoryLocally(storyId);
    await _service.deleteStory(storyId);
  }
}