import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';
import 'package:otakuverse/features/feed/widgets/posts/heart_animation.dart';

class PostCardMedia extends StatefulWidget {
  final PostModel    post;
  final bool         showHeart;
  final VoidCallback onDoubleTap;

  const PostCardMedia({
    super.key,
    required this.post,
    required this.showHeart,
    required this.onDoubleTap,
  });

  @override
  State<PostCardMedia> createState() => _PostCardMediaState();
}

class _PostCardMediaState extends State<PostCardMedia> {
  int  _currentPage = 0;
  final PageController _pageController = PageController();

  // ✅ Cache des ratios — calcul une seule fois par URL
  static final Map<String, double> _ratioCache = {};

  // ✅ Limites Instagram — portrait max 4:5, paysage max 1.91:1
  static const double _minRatio = 4 / 5;
  static const double _maxRatio = 1.91;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── DÉTECTER LE RATIO RÉEL DE L'IMAGE ───────────────────────────
  Future<double> _getImageRatio(String url) async {
    if (_ratioCache.containsKey(url)) return _ratioCache[url]!;

    try {
      final completer = Completer<double>();
      final stream = NetworkImage(url)
          .resolve(ImageConfiguration.empty);

      stream.addListener(ImageStreamListener(
        (info, _) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          final ratio = (w / h).clamp(_minRatio, _maxRatio);
          _ratioCache[url] = ratio;
          if (!completer.isCompleted) completer.complete(ratio);
        },
        onError: (_, __) {
          if (!completer.isCompleted) completer.complete(1.0);
        },
      ));

      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => 1.0,
      );
    } catch (_) {
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstUrl = widget.post.mediaUrls.first;

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: FutureBuilder<double>(
        future:      _getImageRatio(firstUrl),
        initialData: _ratioCache[firstUrl] ?? 1.0,
        builder: (context, snapshot) {
          final ratio = snapshot.data ?? 1.0;

          return AspectRatio(
            aspectRatio: ratio,
            // ✅ ClipRect évite tout débordement
            child: ClipRect(
              child: Stack(
                // ✅ StackFit.expand force les enfants à remplir
                fit: StackFit.expand,
                children: [
                  // ─ Image / Carrousel ────────────────────────
                  widget.post.isCarousel
                      ? _buildCarousel()
                      : _buildSingleImage(firstUrl),

                  // ─ Badge carrousel ──────────────────────────
                  if (widget.post.isCarousel)
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:        Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1}/'
                          '${widget.post.mediaCount}',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),

                  // ─ Animation cœur ───────────────────────────
                  if (widget.showHeart)
                    const Positioned.fill(child: HeartAnimation()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── IMAGE UNIQUE ─────────────────────────────────────────────────
  Widget _buildSingleImage(String url) {
    // ✅ LayoutBuilder → dimensions exactes du conteneur
    return LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: url,
          // ✅ Dimensions exactes — plus de double.infinity ambigu
          width:    constraints.maxWidth,
          height:   constraints.maxHeight,
          fit:      BoxFit.cover,
          placeholder: (_, __) => Container(
            color: AppColors.darkGray,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:       AppColors.crimsonRed,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.darkGray,
            child: const Center(
              child: Icon(
                HeroiconsOutline.photo,
                color: AppColors.mediumGray,
                size:  48,
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── CARROUSEL ────────────────────────────────────────────────────
  Widget _buildCarousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller:    _pageController,
          itemCount:     widget.post.mediaUrls.length,
          onPageChanged: (i) =>
              setState(() => _currentPage = i),
          itemBuilder:   (_, i) =>
              _buildSingleImage(widget.post.mediaUrls[i]),
        ),

        // ─ Dots ─────────────────────────────────────────────
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.post.mediaUrls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin:   const EdgeInsets.symmetric(
                    horizontal: 3),
                width:    _currentPage == i ? 16 : 6,
                height:   6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.crimsonRed
                      : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}