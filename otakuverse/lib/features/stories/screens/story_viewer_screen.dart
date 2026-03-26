// ignore_for_file: unused_field

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup>              groups;
  final int                           initialGroupIndex;
  final Future<void> Function(String) onStoryViewed;
  final Future<void> Function(String) onDeleteStory;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    required this.onStoryViewed,
    required this.onDeleteStory,
  });

  @override
  State<StoryViewerScreen> createState() =>
      _StoryViewerScreenState();
}

class _StoryViewerScreenState
    extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {

  late PageController      _pageController;
  late AnimationController _progressController;

  int  _groupIndex = 0;
  int  _storyIndex = 0;
  bool _isPaused   = false;

  // ─── Video ───────────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool                   _videoReady = false;

  StoryGroup get _currentGroup =>
      widget.groups[_groupIndex];
  StoryModel get _currentStory =>
      _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex     = widget.initialGroupIndex;
    _pageController = PageController(
        initialPage: widget.initialGroupIndex);

    _progressController = AnimationController(vsync: this);
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _startStory());
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _disposeVideo();
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── DISPOSE VIDÉO ───────────────────────────────────────────────
  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoReady      = false;
  }

  // ─── DÉMARRER LA STORY ───────────────────────────────────────────
  Future<void> _startStory() async {
    _progressController.stop();
    _progressController.reset();
    _disposeVideo();

    widget.onStoryViewed(_currentStory.id);

    if (_currentStory.mediaType == 'video' &&
        _currentStory.mediaUrl != null) {
      // ✅ Initialiser le player vidéo
      setState(() => _videoReady = false);

      _videoController =
          VideoPlayerController.networkUrl(
        Uri.parse(_currentStory.mediaUrl!),
      );

      try {
        await _videoController!.initialize();

        if (!mounted) return;

        final videoDuration =
            _videoController!.value.duration;

        _progressController.duration =
            videoDuration > Duration.zero
                ? videoDuration
                : const Duration(seconds: 15);

        setState(() => _videoReady = true);
        _videoController!.play();
        _progressController.forward();
      } catch (e) {
        debugPrint('❌ Video init: $e');
        // ✅ Fallback durée fixe si erreur
        _progressController.duration =
            const Duration(seconds: 10);
        _progressController.forward();
      }
    } else {
      // ✅ Image ou texte
      _progressController.duration =
          Duration(seconds: _currentStory.duration);
      _progressController.forward();
    }
  }

  // ─── NAVIGATION ──────────────────────────────────────────────────
  void _nextStory() {
    if (_storyIndex > _currentGroup.stories.length - 1) {
      setState(() => _storyIndex++);
      _startStory();
    } else {
      _nextGroup();
    }
  }

  void _prevStory() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startStory();
    } else {
      _prevGroup();
    }
  }

  void _nextGroup() {
    if (_groupIndex < widget.groups.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prevGroup() {
    if (_groupIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeInOut,
      );
    }
  }

  // ─── PAUSE / RESUME ──────────────────────────────────────────────
  void _pause() {
    _progressController.stop();
    _videoController?.pause();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (!_isPaused) return;
    _progressController.forward();
    _videoController?.play();
    setState(() => _isPaused = false);
  }

  // ─── SUPPRIMER ───────────────────────────────────────────────────
  void _confirmDelete() {
    _pause();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkGray,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer la story ?',
            style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resume();
            },
            child: Text('Annuler',
                style: GoogleFonts.inter(
                    color: AppColors.mediumGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDeleteStory(
                  _currentStory.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8)),
            ),
            child: Text('Supprimer',
                style: GoogleFonts.inter(
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics:    const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _groupIndex = index;
            _storyIndex = 0;
          });
          _startStory();
        },
        itemCount:   widget.groups.length,
        itemBuilder: (_, __) => _buildStoryPage(),
      ),
    );
  }

  // ─── PAGE STORY ──────────────────────────────────────────────────
  Widget _buildStoryPage() {
    return GestureDetector(
      onTapDown:        (_) => _pause(),
      onTapUp:          (_) => _resume(),
      onLongPressStart: (_) => _pause(),
      onLongPressEnd:   (_) => _resume(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─ Contenu ────────────────────────────────────────
          _buildContent(),

          // ─ Zones tap nav gauche/droite ────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _prevStory,
                child: Container(color: Colors.transparent),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _nextStory,
                child: Container(color: Colors.transparent),
              ),
            ),
          ]),

          // ─ Header ─────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ─ Barres progression ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(
                        _currentGroup.stories.length,
                        (i) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 2),
                            child: _StoryProgressBar(
                              state: i < _storyIndex
                                  ? _ProgressState.completed
                                  : i == _storyIndex
                                      ? _ProgressState.active
                                      : _ProgressState.pending,
                              controller: i == _storyIndex
                                  ? _progressController
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─ Auteur ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        CachedAvatar(
                          url:   _currentGroup.avatarUrl,
                          radius: 18,
                          fallbackLetter: _currentGroup
                              .displayNameOrUsername,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentGroup
                                    .displayNameOrUsername,
                                style: GoogleFonts.inter(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize:   14,
                                ),
                              ),
                              Text(
                                _formatTime(
                                    _currentStory.createdAt),
                                style: GoogleFonts.inter(
                                  color: Colors.white
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_currentGroup.isMe)
                          GestureDetector(
                            onTap: _confirmDelete,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(8),
                              child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size:  22),
                            ),
                          ),

                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: Container(
                            padding:
                                const EdgeInsets.all(8),
                            child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size:  22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─ Vues (mes stories) ─────────────────────────────
          if (_currentGroup.isMe)
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withValues(alpha: 0.4),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size:  16),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentStory.viewsCount} vues',
                          style: GoogleFonts.inter(
                            color:      Colors.white,
                            fontSize:   13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── CONTENU ─────────────────────────────────────────────────────
  Widget _buildContent() {
    // ─ Texte ───────────────────────────────────────────────────────
    if (_currentStory.mediaType == 'text') {
      final color = _currentStory.bgColor != null
          ? Color(int.parse(
              _currentStory.bgColor!
                  .replaceFirst('#', '0xFF')))
          : AppColors.crimsonRed;

      return Container(
        color:     color,
        alignment: Alignment.center,
        padding:   const EdgeInsets.all(32),
        child: Text(
          _currentStory.textContent ?? '',
          style: GoogleFonts.poppins(
            color:      Colors.white,
            fontSize:   28,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color:      Colors.black
                    .withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ─ Vidéo ───────────────────────────────────────────────────────
    if (_currentStory.mediaType == 'video') {
      if (!_videoReady || _videoController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
                color: AppColors.crimsonRed),
          ),
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          Center(
            child: AspectRatio(
              aspectRatio:
                  _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // ─ Badge vidéo ───────────────────────────────────
          Positioned(
            top: 80, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
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
    if (_currentStory.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: _currentStory.mediaUrl!,
        fit:      BoxFit.cover,
        width:    double.infinity,
        height:   double.infinity,
        placeholder: (_, __) =>
            Container(color: Colors.black),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.darkGray,
          child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.mediumGray,
              size:  48),
        ),
      );
    }

    return Container(color: Colors.black);
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes} min';
    }
    return 'il y a ${diff.inHours} h';
  }
}

// ─── BARRE DE PROGRESSION ────────────────────────────────────────────
enum _ProgressState { pending, active, completed }

class _StoryProgressBar extends StatelessWidget {
  final _ProgressState       state;
  final AnimationController? controller;

  const _StoryProgressBar({
    required this.state,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2.5,
        child: state == _ProgressState.active &&
                controller != null
            ? AnimatedBuilder(
                animation: controller!,
                builder: (_, __) =>
                    LinearProgressIndicator(
                  value: controller!.value,
                  backgroundColor: Colors.white
                      .withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation(
                          Colors.white),
                  minHeight: 2.5,
                ),
              )
            : LinearProgressIndicator(
                value: state == _ProgressState.completed
                    ? 1.0
                    : 0.0,
                backgroundColor: Colors.white
                    .withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation(
                        Colors.white),
                minHeight: 2.5,
              ),
      ),
    );
  }
}