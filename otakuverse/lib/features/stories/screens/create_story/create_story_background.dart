import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';
import 'package:video_player/video_player.dart';


class CreateStoryBackground extends StatelessWidget {
  final bool                     textMode;
  final Color                    textBg;
  final TextEditingController    textCtrl;
  final Uint8List?               mediaPreview;
  final bool                     isVideo;
  final VideoPlayerController?   videoController;
  final bool                     videoReady;
  final bool                     videoPlaying;
  final VoidCallback             onToggleVideo;

  // ✅ Nouveaux params multi-slides
  final List<StoryMediaItem>    mediaItems;
  final int                      currentSlide;
  final ValueChanged<int>        onSlideChanged;
  final ValueChanged<int>        onRemoveSlide;

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
    // ✅ Nouveaux
    required this.mediaItems,
    required this.currentSlide,
    required this.onSlideChanged,
    required this.onRemoveSlide,
  });

  @override
  Widget build(BuildContext context) {
    // ─ Mode texte ──────────────────────────────────────────────────
    if (textMode) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color:    textBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 32),
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
                  Shadow(
                    color:      Colors.black
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
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

    // ─ Médias ──────────────────────────────────────────────────────
    if (mediaItems.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          // ─ Contenu du slide courant ───────────────────────
          if (isVideo && videoReady && videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio:
                    videoController!.value.aspectRatio,
                child: VideoPlayer(videoController!),
              ),
            )
          else if (isVideo && !videoReady)
            const Center(
              child: CircularProgressIndicator(
                  color: Colors.white),
            )
          else if (!isVideo && mediaPreview != null)
            Image.memory(
              mediaPreview!,
              fit:    BoxFit.cover,
              width:  double.infinity,
              height: double.infinity,
            ),

          // ─ Tap play/pause (vidéo) ─────────────────────────
          if (isVideo && videoReady)
            Positioned.fill(
              child: GestureDetector(
                onTap:  onToggleVideo,
                child:  Container(
                    color: Colors.transparent),
              ),
            ),

          // ─ Icône play si en pause ─────────────────────────
          if (isVideo && videoReady)
            Center(
              child: AnimatedOpacity(
                opacity:  videoPlaying ? 0.0 : 1.0,
                duration: const Duration(
                    milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:  Colors.black
                        .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size:  48,
                  ),
                ),
              ),
            ),

          // ─ Progress bar vidéo ─────────────────────────────
          if (isVideo && videoReady &&
              videoController != null)
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

          // ─ Durée vidéo ────────────────────────────────────
          if (isVideo && videoReady &&
              videoController != null)
            Positioned(
              bottom: 242, right: 16,
              child: ValueListenableBuilder(
                valueListenable: videoController!,
                builder: (_, value, __) => Text(
                  '${_fmt(value.position)} / '
                  '${_fmt(value.duration)}',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color:      Colors.black
                            .withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─ Badge type ─────────────────────────────────────
          Positioned(
            top: 80, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideo
                        ? Icons.videocam
                        : Icons.image_outlined,
                    color: Colors.white,
                    size:  14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVideo ? 'Vidéo' : 'Photo',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontSize:   11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─ Compteur slides ────────────────────────────────
          if (mediaItems.length > 1)
            Positioned(
              top: 80, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentSlide + 1}/${mediaItems.length}',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ─ Miniatures slides ──────────────────────────────
          if (mediaItems.length > 1)
            Positioned(
              bottom: 195, left: 0, right: 0,
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: mediaItems.length + 1,
                  itemBuilder: (_, i) {
                    // ─ Bouton ajouter ───────────────────────
                    if (i == mediaItems.length) {
                      return Container(
                        width: 48, height: 48,
                        margin: const EdgeInsets
                            .only(left: 6),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size:  22,
                        ),
                      );
                    }

                    final item      = mediaItems[i];
                    final isCurrent = i == currentSlide;

                    return GestureDetector(
                      onTap: () => onSlideChanged(i),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            width:  48, height: 48,
                            margin: const EdgeInsets
                                .only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: item.isVideo
                                ? Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.videocam,
                                      color: Colors.white54,
                                      size:  22,
                                    ),
                                  )
                                : Image.memory(
                                    item.bytes,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          // ─ Supprimer ──────────────────────
                          Positioned(
                            top: 0, right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  onRemoveSlide(i),
                              child: Container(
                                width:  16, height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size:  10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      );
    }

    return Container(color: Colors.black);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60)
        .toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60)
        .toString().padLeft(2, '0');
    return '$m:$s';
  }
}