import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';

class CreateStoryBottomBar extends StatelessWidget {
  final Uint8List?           galleryThumb;
  final Uint8List?           mediaPreview;
  final bool                 textMode;
  final VoidCallback         onGallery;
  final VoidCallback         onCapturePhoto;
  final VoidCallback         onCaptureVideo;
  final VoidCallback         onSwitchCamera;
  final VoidCallback         onNext;
  final ValueChanged<String> onNavigateTab;

  const CreateStoryBottomBar({
    super.key,
    required this.galleryThumb,
    required this.mediaPreview,
    required this.textMode,
    required this.onGallery,
    required this.onCapturePhoto,
    required this.onCaptureVideo,
    required this.onSwitchCamera,
    required this.onNext,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StoryController>();

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  // ─ Galerie ──────────────────────────────
                  GestureDetector(
                    onTap: onGallery,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white, width: 2),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: galleryThumb != null
                          ? Image.memory(
                              galleryThumb!,
                              fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.photo_library_outlined,
                                color: Colors.white54,
                                size:  22,
                              ),
                            ),
                    ),
                  ),

                  // ─ Capture ──────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap:       onCapturePhoto,
                        onLongPress: onCaptureVideo,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white,
                                width: 4),
                            color: Colors.white
                                .withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Container(
                              width:  58, height: 58,
                              decoration:
                                  const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Appui = photo · Maintenir = vidéo',
                        style: GoogleFonts.inter(
                          color: Colors.white
                              .withValues(alpha: 0.5),
                          fontSize:        9,
                          decoration:
                              TextDecoration.none,
                          decorationColor:
                              Colors.transparent,
                        ),
                      ),
                    ],
                  ),

                  // ─ Switch + Suivant ──────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onSwitchCamera,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.flip_camera_ios_outlined,
                            color: Colors.white,
                            size:  22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Obx(() {
                        final uploading =
                            ctrl.isUploading.value;
                        final hasContent =
                            mediaPreview != null ||
                            textMode;

                        return GestureDetector(
                          onTap: uploading ? null : onNext,
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical:   8,
                            ),
                            decoration: BoxDecoration(
                              color: hasContent
                                  ? Colors.white
                                  : Colors.white
                                      .withValues(alpha: 0.3),
                              borderRadius:
                                  BorderRadius.circular(24),
                            ),
                            child: uploading
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors
                                          .crimsonRed,
                                    ),
                                  )
                                : Text(
                                    'Suivant',
                                    style: GoogleFonts.inter(
                                      color: hasContent
                                          ? Colors.black
                                          : Colors.white54,
                                      fontWeight:
                                          FontWeight.w700,
                                      fontSize:        13,
                                      decoration:
                                          TextDecoration.none,
                                      decorationColor:
                                          Colors.transparent,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // ─ Onglets ────────────────────────────────────────
            _buildTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    const types = ['PUBLIER', 'STORY', 'REEL'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: types.map((t) {
          final bool sel = t == 'STORY';
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14),
            child: GestureDetector(
              onTap: () => onNavigateTab(t),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t,
                      style: GoogleFonts.inter(
                        color: sel
                            ? Colors.white
                            : Colors.white
                                .withValues(alpha: 0.45),
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize:        13,
                        letterSpacing:   0.5,
                        decoration:      TextDecoration.none,
                        decorationColor: Colors.transparent,
                      )),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    width:  sel ? 20 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}