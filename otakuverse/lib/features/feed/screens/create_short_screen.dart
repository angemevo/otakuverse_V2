// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:otakuverse/core/constants/app_colors.dart';

class CreateShortScreen extends StatefulWidget {
  const CreateShortScreen({super.key});

  @override
  State<CreateShortScreen> createState() => _CreateShortScreenState();
}

class _CreateShortScreenState extends State<CreateShortScreen> {
  final _captionController = TextEditingController();
  XFile?    _videoFile;
  Uint8List? _videoPreview;
  bool _isPublishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(
      source:       ImageSource.gallery,
      maxDuration:  const Duration(seconds: 60),
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _videoFile    = file;
      _videoPreview = bytes;
    });
  }

  Future<void> _publish() async {
    HapticFeedback.mediumImpact();
    // TODO: implémenter la publication de short
    Get.snackbar(
      'Bientôt disponible 🚧',
      'Les Shorts arrivent prochainement',
      backgroundColor: AppColors.darkGray,
      colorText:       AppColors.pureWhite,
      snackPosition:   SnackPosition.BOTTOM,
      margin:          const EdgeInsets.all(16),
      borderRadius:    12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation:       0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.pureWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Short',
            style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publish,
            child: Text('Publier',
                style: GoogleFonts.inter(
                    color:      const Color(0xFFFF6B35),
                    fontWeight: FontWeight.w700,
                    fontSize:   16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Zone vidéo ──────────────────────────────────────
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                width:  double.infinity,
                height: 420, // ✅ Format portrait 9:16
                decoration: BoxDecoration(
                  color:        AppColors.darkGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _videoFile != null
                        ? const Color(0xFFFF6B35)
                        : Colors.white.withValues(alpha: 0.08),
                    width: _videoFile != null ? 2 : 1,
                  ),
                ),
                child: _videoFile == null
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color:  Color(0x1AFF6B35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.videocam_outlined,
                              color: Color(0xFFFF6B35),
                              size:  52,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Sélectionner une vidéo',
                            style: GoogleFonts.poppins(
                              color:      AppColors.pureWhite,
                              fontWeight: FontWeight.w600,
                              fontSize:   16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Format vertical · 60 secondes max',
                            style: GoogleFonts.inter(
                              color:    AppColors.mediumGray,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ─ Indications ──────────────────────
                          _InfoChip(
                              icon:  Icons.aspect_ratio,
                              label: '9:16 recommandé'),
                          const SizedBox(height: 8),
                          _InfoChip(
                              icon:  Icons.timer_outlined,
                              label: 'Max 60 secondes'),
                          const SizedBox(height: 8),
                          _InfoChip(
                              icon:  Icons.hd_outlined,
                              label: 'HD 1080p idéal'),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // ✅ Vraie preview avec video_player
                          // Pour l'instant : placeholder
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white70,
                                size:  64,
                              ),
                            ),
                          ),

                          // ─ Bouton changer ───────────────────
                          Positioned(
                            bottom: 12, right: 12,
                            child: GestureDetector(
                              onTap: _pickVideo,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size:  18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ─ Caption ───────────────────────────────────────
            Text('Description',
                style: GoogleFonts.inter(
                    color:      AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                    fontSize:   14)),
            const SizedBox(height: 10),
            TextField(
              controller: _captionController,
              maxLength:  150,
              maxLines:   3,
              style: GoogleFonts.inter(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: 'Décris ton short...',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.mediumGray),
                filled:      true,
                fillColor:   AppColors.darkGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFFF6B35)),
                ),
                counterStyle: GoogleFonts.inter(
                    color: AppColors.mediumGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INFO CHIP ───────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFF6B35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0x33FF6B35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                color:      const Color(0xFFFF6B35),
                fontSize:   12,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}