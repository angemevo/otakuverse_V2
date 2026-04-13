import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PostPreviewWidget extends StatelessWidget {
  final List<Uint8List>   imagePreviews;
  final int               currentPreview;
  final ValueChanged<int> onPageChanged;

  const PostPreviewWidget({
    super.key,
    required this.imagePreviews,
    required this.currentPreview,
    required this.onPageChanged,
  });

  void _openFullscreen(BuildContext context) {
    if (imagePreviews.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque:      false,
        pageBuilder: (_, __, ___) => _FullscreenViewer(
          imagePreviews: imagePreviews,
          initialIndex:  currentPreview,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    if (imagePreviews.isEmpty) {
      return Container(
        width:  double.infinity,
        height: size,
        color:  AppColors.bgCard,
        child:  const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textMuted, size: 64),
        ),
      );
    }

    return Stack(children: [
      SizedBox(
        width:  double.infinity,
        height: size,
        child: imagePreviews.length == 1
            ? Image.memory(imagePreviews.first,
                fit: BoxFit.cover, width: double.infinity)
            : PageView.builder(
                itemCount:     imagePreviews.length,
                onPageChanged: onPageChanged,
                itemBuilder:   (_, i) => Image.memory(
                    imagePreviews[i], fit: BoxFit.cover),
              ),
      ),
      // ─ Expand ────────────────────────────────────────────
      Positioned(
        bottom: 12, left: 12,
        child: GestureDetector(
          onTap: () => _openFullscreen(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fullscreen,
                color: Colors.white, size: 20),
          ),
        ),
      ),
      // ─ Compteur ──────────────────────────────────────────
      if (imagePreviews.length > 1)
        Positioned(
          bottom: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentPreview + 1}/${imagePreviews.length}',
              style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontSize:   12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      // ─ Dots ──────────────────────────────────────────────
      if (imagePreviews.length > 1)
        Positioned(
          bottom: 8, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imagePreviews.length, (i) =>
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:   const EdgeInsets.symmetric(horizontal: 3),
                width:  currentPreview == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: currentPreview == i
                      ? AppColors.primary
                      : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
          ),
        ),
    ]);
  }
}

// ─── Visionneuse plein écran ──────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<Uint8List> imagePreviews;
  final int             initialIndex;

  const _FullscreenViewer({
    required this.imagePreviews,
    required this.initialIndex,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PhotoViewGallery.builder(
          itemCount:      widget.imagePreviews.length,
          pageController: PageController(
              initialPage: widget.initialIndex),
          onPageChanged: (i) => setState(() => _current = i),
          builder: (_, i) => PhotoViewGalleryPageOptions(
            imageProvider: MemoryImage(widget.imagePreviews[i]),
            minScale:      PhotoViewComputedScale.contained,
            maxScale:      PhotoViewComputedScale.covered * 3,
          ),
          backgroundDecoration: const BoxDecoration(
              color: Colors.black),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        if (widget.imagePreviews.length > 1)
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imagePreviews.length, (i) =>
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:   const EdgeInsets.symmetric(horizontal: 3),
                  width:  _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppColors.primary
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
            ),
          ),
      ]),
    );
  }
}