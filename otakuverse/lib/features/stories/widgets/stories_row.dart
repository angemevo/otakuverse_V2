import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'package:otakuverse/features/stories/screens/create_story/create_story_screen.dart';
import 'package:otakuverse/features/stories/screens/story_viewer_screen.dart';
import 'package:otakuverse/features/stories/widgets/story_circle.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

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
                color:       AppColors.crimsonRed,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }

      final groups = ctrl.storyGroups;

      // ✅ Toujours afficher le bouton "Ajouter"
      final hasMyStory =
          groups.any((g) => g.isMe);

      return SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection:    Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: 12),
          itemCount: groups.length +
              (hasMyStory ? 0 : 1),
          itemBuilder: (_, index) {
            // ✅ Si pas de story perso → bouton créer
            if (!hasMyStory && index == 0) {
              return _AddStoryButton(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CreateStoryScreen(),
                  ),
                ),
              );
            }

            final groupIndex =
                hasMyStory ? index : index - 1;
            final group = groups[groupIndex];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StoryCircle(
                group: group,
                onTap: () => _openStories(
                  context,
                  groups: groups,
                  initialGroupIndex: groupIndex,
                  ctrl: ctrl,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _openStories(
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
        transitionDuration:
            const Duration(milliseconds: 200),
      ),
    );
  }
}

// ─── BOUTON AJOUTER UNE STORY ────────────────────────────────────────
class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                color: AppColors.darkGray,
                border: Border.all(
                  color: AppColors.crimsonRed
                      .withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.crimsonRed,
                size:  28,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Ajouter',
              style: TextStyle(
                color:    AppColors.mediumGray,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}