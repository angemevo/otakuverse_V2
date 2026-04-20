import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';

/// Affiche le contenu d'une story selon son type :
/// - 'text'  → fond coloré + texte centré
/// - 'video' → lecteur vidéo avec badge
/// - autre   → image réseau avec cache
class StoryContentWidget extends StatelessWidget {
  final StoryModel             story;
  final VideoPlayerController? videoController;
  final bool                   videoReady;

  const StoryContentWidget({
    super.key,
    required this.story,
    required this.videoController,
    required this.videoReady,
  });

  @override
  Widget build(BuildContext context) {
    if (story.mediaType == 'text')  return _buildText();
    if (story.mediaType == 'video') return _buildVideo();
    if (story.mediaUrl  != null)    return _buildImage();
    return Container(color: Colors.black);
  }

  // ─── Texte ────────────────────────────────────────────────────────

  Widget _buildText() {
    final bg = story.bgColor != null
        ? Color(int.parse(story.bgColor!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      color:     bg,
      alignment: Alignment.center,
      padding:   const EdgeInsets.all(32),
      child: Text(
        story.textContent ?? '',
        style: GoogleFonts.poppins(
          color:      Colors.white,
          fontSize:   28,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color:      Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Vidéo ────────────────────────────────────────────────────────

  Widget _buildVideo() {
    if (!videoReady || videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Stack(fit: StackFit.expand, children: [
      Container(color: Colors.black),
      Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child:       VideoPlayer(videoController!),
        ),
      ),
      Positioned(
        top: 80, right: 16,
        child: _StoryMediaBadge(icon: Icons.videocam, label: 'Vidéo'),
      ),
    ]);
  }

  // ─── Image ────────────────────────────────────────────────────────

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl:    story.mediaUrl!,
      fit:         BoxFit.cover,
      width:       double.infinity,
      height:      double.infinity,
      placeholder: (_, __) => Container(color: Colors.black),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.bgCard,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.textMuted,
          size:  48,
        ),
      ),
    );
  }
}

// ─── Badge type média ─────────────────────────────────────────────────

class _StoryMediaBadge extends StatelessWidget {
  final IconData icon;
  final String   label;

  const _StoryMediaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color:      Colors.white,
            fontSize:   11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}
