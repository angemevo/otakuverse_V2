import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';
import 'package:video_player/video_player.dart';

/// Fond de la story en cours de création.
/// Gère 3 modes : texte, média (photo/vidéo), et multi-slides.
class CreateStoryBackground extends StatelessWidget {
  final bool                   textMode;
  final Color                  textBg;
  final TextEditingController  textCtrl;
  final Uint8List?             mediaPreview;
  final bool                   isVideo;
  final VideoPlayerController? videoController;
  final bool                   videoReady;
  final bool                   videoPlaying;
  final VoidCallback           onToggleVideo;
  final List<StoryMediaItem>   mediaItems;
  final int                    currentSlide;
  final ValueChanged<int>      onSlideChanged;
  final ValueChanged<int>      onRemoveSlide;

  const CreateStoryBackground({
    super.key,
    required this.textMode,
    required this.textBg,
    required this.textCtrl,
    required this.mediaPreview,
    required this.isVideo,
    required this.videoController,
    required this.videoReady,
    required this.videoPlaying,
    required this.onToggleVideo,
    required this.mediaItems,
    required this.currentSlide,
    required this.onSlideChanged,
    required this.onRemoveSlide,
  });

  @override
  Widget build(BuildContext context) {
    if (textMode)          return _buildTextMode();
    if (mediaItems.isNotEmpty) return _buildMediaMode();
    return Container(color: Colors.black);
  }

  // ─── Mode texte ──────────────────────────────────────────────────

  Widget _buildTextMode() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color:    textBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: TextField(
            controller: textCtrl,
            maxLines:   null,
            textAlign:  TextAlign.center,
            autofocus:  true,
            style: GoogleFonts.poppins(
              color:      Colors.white,
              fontSize:   26,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
              ],
            ),
            decoration: InputDecoration(
              border:   InputBorder.none,
              hintText: 'Écris quelque chose...',
              hintStyle: GoogleFonts.poppins(
                  color:      Colors.white54,
                  fontSize:   26,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mode médias ─────────────────────────────────────────────────

  Widget _buildMediaMode() {
    return Stack(fit: StackFit.expand, children: [
      Container(color: Colors.black),
      _buildMediaContent(),
      if (isVideo && videoReady) _buildVideoControls(),
      _buildMediaBadge(),
      if (mediaItems.length > 1) ...[
        _buildSlideCounter(),
        _buildSlideThumbnails(),
      ],
    ]);
  }

  Widget _buildMediaContent() {
    if (isVideo && videoReady && videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child:       VideoPlayer(videoController!),
        ),
      );
    }
    if (isVideo && !videoReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (!isVideo && mediaPreview != null) {
      return Image.memory(mediaPreview!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return const SizedBox.shrink();
  }

  Widget _buildVideoControls() {
    return Stack(children: [
      // ─ Tap play/pause ─────────────────────────────
      Positioned.fill(child: GestureDetector(
        onTap:  onToggleVideo,
        child:  Container(color: Colors.transparent),
      )),
      // ─ Icône play si en pause ─────────────────────
      Center(
        child: AnimatedOpacity(
          opacity:  videoPlaying ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 48),
          ),
        ),
      ),
      // ─ Barre de progression ───────────────────────
      if (videoController != null)
        Positioned(
          bottom: 230, left: 16, right: 16,
          child: VideoProgressIndicator(
            videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor:     Colors.white,
              bufferedColor:   Colors.white38,
              backgroundColor: Colors.white12,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      // ─ Durée ─────────────────────────────────────
      if (videoController != null)
        Positioned(
          bottom: 242, right: 16,
          child: ValueListenableBuilder(
            valueListenable: videoController!,
            builder: (_, value, __) => Text(
              '${_fmt(value.position)} / ${_fmt(value.duration)}',
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildMediaBadge() {
    return Positioned(
      top: 80, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isVideo ? Icons.videocam : Icons.image_outlined,
              color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            isVideo ? 'Vidéo' : 'Photo',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  Widget _buildSlideCounter() {
    return Positioned(
      top: 80, left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${currentSlide + 1}/${mediaItems.length}',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSlideThumbnails() {
    return Positioned(
      bottom: 195, left: 0, right: 0,
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding:         const EdgeInsets.symmetric(horizontal: 16),
          itemCount:       mediaItems.length + 1,
          itemBuilder: (_, i) {
            if (i == mediaItems.length) return _buildAddSlideBtn();
            return _buildSlideThumbnail(i);
          },
        ),
      ),
    );
  }

  Widget _buildAddSlideBtn() {
    return Container(
      width: 48, height: 48,
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 22),
    );
  }

  Widget _buildSlideThumbnail(int i) {
    final item      = mediaItems[i];
    final isCurrent = i == currentSlide;

    return GestureDetector(
      onTap: () => onSlideChanged(i),
      child: Stack(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48, height: 48,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent ? Colors.white : Colors.transparent, width: 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: item.isVideo
              // ✅ AppColors.bgCard remplace Colors.grey[800]
              ? Container(
                  color: AppColors.bgCard,
                  child: const Icon(Icons.videocam,
                      color: Colors.white54, size: 22))
              : Image.memory(item.bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0, right: 4,
          child: GestureDetector(
            onTap: () => onRemoveSlide(i),
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 10),
            ),
          ),
        ),
      ]),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
