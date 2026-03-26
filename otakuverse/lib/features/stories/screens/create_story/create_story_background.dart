import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // ─ Vidéo ───────────────────────────────────────────────────────
    if (mediaPreview != null && isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          // ─ Player ──────────────────────────────────────────
          if (videoReady && videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio:
                    videoController!.value.aspectRatio,
                child: VideoPlayer(videoController!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                  color: Colors.white),
            ),

          // ─ Tap play/pause ──────────────────────────────────
          if (videoReady)
            Positioned.fill(
              child: GestureDetector(
                onTap:  onToggleVideo,
                child:  Container(color: Colors.transparent),
              ),
            ),

          // ─ Icône play visible si en pause ──────────────────
          if (videoReady)
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

          // ─ Progress bar ────────────────────────────────────
          if (videoReady && videoController != null)
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

          // ─ Durée ───────────────────────────────────────────
          if (videoReady && videoController != null)
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

          // ─ Badge vidéo ─────────────────────────────────────
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
                  const Icon(Icons.videocam,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Vidéo',
                      style: GoogleFonts.inter(
                        color:      Colors.white,
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ─ Image ───────────────────────────────────────────────────────
    if (mediaPreview != null) {
      return Image.memory(
        mediaPreview!,
        fit:    BoxFit.cover,
        width:  double.infinity,
        height: double.infinity,
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