import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';

class StoryController extends GetxController {
  final _service = StoryService();

  final RxList<StoryGroup> storyGroups = <StoryGroup>[].obs;
  final RxBool             isLoading   = false.obs;
  final RxBool             isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStories();
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
    await _service.markAsViewed(storyId);

    // ✅ Mise à jour optimiste
    for (int g = 0; g < storyGroups.length; g++) {
      final group = storyGroups[g];
      final idx   = group.stories
          .indexWhere((s) => s.id == storyId);

      if (idx == -1) continue;

      final updatedStories = List<StoryModel>.from(
          group.stories);
      updatedStories[idx] = StoryModel(
        id:          updatedStories[idx].id,
        userId:      updatedStories[idx].userId,
        mediaUrl:    updatedStories[idx].mediaUrl,
        mediaType:   updatedStories[idx].mediaType,
        textContent: updatedStories[idx].textContent,
        bgColor:     updatedStories[idx].bgColor,
        duration:    updatedStories[idx].duration,
        viewsCount:  updatedStories[idx].viewsCount,
        createdAt:   updatedStories[idx].createdAt,
        expiresAt:   updatedStories[idx].expiresAt,
        username:    updatedStories[idx].username,
        displayName: updatedStories[idx].displayName,
        avatarUrl:   updatedStories[idx].avatarUrl,
        isViewed:    true,
      );

      storyGroups[g] = StoryGroup(
        userId:      group.userId,
        username:    group.username,
        displayName: group.displayName,
        avatarUrl:   group.avatarUrl,
        stories:     updatedStories,
        hasUnviewed: updatedStories.any((s) => !s.isViewed),
        isMe:        group.isMe,
      );
      break;
    }
  }

  // ─── PUBLIER IMAGE/VIDEO ───────────────────────────────────────────────
  Future<bool> publishMediaStory(
    XFile file, {required bool isVideo}) async {
    isUploading.value = true;
    try {
      final StoryModel? story;

      if (isVideo) {
        story = await _service.createVideoStory(file);
      } else {
        story = await _service.createImageStory(file);
      }

      if (story != null) {
        await loadStories();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ publishMediaStory: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> publishImageStory(XFile file) async =>
    publishMediaStory(file, isVideo: false);

  Future<bool> publishVideoStory(XFile file) async =>
    publishMediaStory(file, isVideo: true);

  // ─── PUBLIER TEXTE ───────────────────────────────────────────────
  Future<bool> publishTextStory({
    required String text,
    required String bgColor,
  }) async {
    isUploading.value = true;
    try {
      final story = await _service.createTextStory(
          text: text, bgColor: bgColor);
      if (story != null) {
        await loadStories();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ publishTextStory: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // ─── SUPPRIMER ───────────────────────────────────────────────────
  Future<void> deleteStory(String storyId) async {
    await _service.deleteStory(storyId);
    await loadStories();
  }
}