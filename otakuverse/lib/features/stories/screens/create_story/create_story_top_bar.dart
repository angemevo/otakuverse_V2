import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';

class CreateStoryTopBar extends StatelessWidget {
  final bool             textMode;
  final List<Color>      bgColors;
  final Color            textBg;
  final VoidCallback     onClose;
  final VoidCallback     onTextMode;
  final VoidCallback     onCloseText;
  final ValueChanged<Color> onColorChange;
  final Uint8List?           mediaPreview;
  final VoidCallback         onNext;

  const CreateStoryTopBar({
    super.key,
    required this.textMode,
    required this.bgColors,
    required this.textBg,
    required this.onClose,
    required this.onTextMode,
    required this.onCloseText,
    required this.onColorChange,
    required this.mediaPreview,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StoryController>();
    return Stack(
      children: [
        // ─ Top bar ───────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _NavBtn(
                      icon: Icons.close, onTap: onClose),
                  Row(children: [
                    _NavBtn(
                        icon: Icons.flash_off_outlined,
                        onTap: () {}),
                    const SizedBox(width: 8),
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
                  ]),
                ],
              ),
            ),
          ),
        ),

        // ─ Outils gauche (hors mode texte) ───────────────────
        if (!textMode)
          Positioned(
            left: 12, top: 100, bottom: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ToolBtn(
                  isText: true,
                  label:  'Aa',
                  onTap:  onTextMode,
                ),
                const SizedBox(height: 18),
                _ToolBtn(
                    icon: Icons.all_inclusive,
                    onTap: () {}),
                const SizedBox(height: 18),
                _ToolBtn(
                    icon: Icons.grid_view_outlined,
                    onTap: () {}),
                const SizedBox(height: 18),
                _ToolBtn(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () {}),
              ],
            ),
          ),

        // ─ Palette couleurs (mode texte) ─────────────────────
        if (textMode)
          Positioned(
            bottom: 175, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: onCloseText,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  ...bgColors.map((color) {
                    final bool sel = textBg == color;
                    return GestureDetector(
                      onTap: () => onColorChange(color),
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 150),
                        width:  sel ? 32 : 24,
                        height: sel ? 32 : 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel
                                ? Colors.white
                                : Colors.white
                                    .withValues(alpha: 0.25),
                            width: sel ? 2.5 : 1,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: color
                                        .withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── NAV BUTTON ──────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:  Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ─── TOOL BUTTON ─────────────────────────────────────────────────────
class _ToolBtn extends StatelessWidget {
  final IconData?    icon;
  final String?      label;
  final bool         isText;
  final VoidCallback onTap;

  const _ToolBtn({
    this.icon, this.label,
    this.isText = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color:  Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: isText
            ? const Text('Aa',
                style: TextStyle(
                  color:           Colors.white,
                  fontSize:        15,
                  fontWeight:      FontWeight.w700,
                  decoration:      TextDecoration.none,
                  decorationColor: Colors.transparent,
                ))
            : Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}