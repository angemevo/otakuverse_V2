import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'package:otakuverse/features/stories/screens/create_story/create_story_screen.dart';
import 'package:otakuverse/features/stories/screens/story_viewer_screen.dart';
import 'package:otakuverse/features/stories/widgets/story_circle.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StoryController>();

    return Obx(() {
      if (ctrl.isLoading.value) {
        return const SizedBox(
          height: 96,
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
            ),
          ),
        );
      }

      // ✅ Obx rule : extraire .value avant le build
      final groups     = ctrl.storyGroups;
      final hasMyStory = groups.any((g) => g.isMe);

      // ✅ Key sur le SizedBox principal de la barre de stories
      return SizedBox(
        key:    AppKeys.storiesRow,
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding:         const EdgeInsets.symmetric(horizontal: 12),
          itemCount:       groups.length + (hasMyStory ? 0 : 1),
          itemBuilder: (_, index) {
            // ─ Bouton créer (si pas encore de story perso) ───
            if (!hasMyStory && index == 0) {
              return _AddStoryButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateStoryScreen()),
                ),
              );
            }

            final groupIndex = hasMyStory ? index : index - 1;
            final group      = groups[groupIndex];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StoryCircle(
                group: group,
                onTap: () => _openViewer(
                  context,
                  groups:            groups,
                  initialGroupIndex: groupIndex,
                  ctrl:              ctrl,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _openViewer(
    BuildContext context, {
    required List<StoryGroup> groups,
    required int              initialGroupIndex,
    required StoryController  ctrl,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque:      false,
        pageBuilder: (_, __, ___) => StoryViewerScreen(
          groups:            groups,
          initialGroupIndex: initialGroupIndex,
          onStoryViewed:     ctrl.markAsViewed,
          onDeleteStory:     ctrl.deleteStory,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

// ─── Bouton "Ajouter une story" ───────────────────────────────────────

class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ✅ Key sur le GestureDetector du bouton +
    return GestureDetector(
      key:  AppKeys.addStoryButton,
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgCard,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 5),
            const Text(
              'Ajouter',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
