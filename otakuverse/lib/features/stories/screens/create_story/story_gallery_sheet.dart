import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';

/// Sheet de sélection galerie (photo ou vidéo) pour la création de story.
/// S'utilise via [StoryGallerySheet.show].
class StoryGallerySheet {
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(StoryMediaItem) onMediaAdded,
  }) {
    return showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GallerySheetContent(onMediaAdded: onMediaAdded),
    );
  }
}

// ─── Contenu interne ─────────────────────────────────────────────────

class _GallerySheetContent extends StatelessWidget {
  final Future<void> Function(StoryMediaItem) onMediaAdded;

  const _GallerySheetContent({required this.onMediaAdded});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color:        Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.image_outlined, color: Colors.white),
            title:   const Text('Photo',
                style: TextStyle(color: Colors.white)),
            onTap:   () => _pick(context, isVideo: false),
          ),
          ListTile(
            leading: const Icon(Icons.videocam_outlined, color: Colors.white),
            title:   const Text('Vidéo',
                style: TextStyle(color: Colors.white)),
            onTap:   () => _pick(context, isVideo: true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, {required bool isVideo}) async {
    Navigator.pop(context);

    final XFile? file;
    if (isVideo) {
      file = await ImagePicker().pickVideo(
        source:      ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
    } else {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    }

    if (file == null) return;
    final bytes = await file.readAsBytes();
    await onMediaAdded(
        StoryMediaItem(file: file, bytes: bytes, isVideo: isVideo));
  }
}
