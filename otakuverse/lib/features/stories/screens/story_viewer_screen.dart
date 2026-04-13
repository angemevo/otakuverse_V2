import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/stories/models/story_model.dart';
import 'package:otakuverse/features/stories/widgets/story_content_widget.dart';
import 'package:otakuverse/features/stories/widgets/story_viewer_header.dart';

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
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {

  late PageController      _pageController;
  late AnimationController _progressController;

  int  _groupIndex = 0;
  int  _storyIndex = 0;
  bool _isPaused   = false;

  VideoPlayerController? _videoController;
  bool                   _videoReady = false;

  StoryGroup get _currentGroup => widget.groups[_groupIndex];
  StoryModel get _currentStory => _currentGroup.stories[_storyIndex];

  // ─── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _groupIndex     = widget.initialGroupIndex;
    _pageController = PageController(initialPage: widget.initialGroupIndex);
    _progressController = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _nextStory();
      });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStory());
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _disposeVideo();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _videoReady      = false;
  }

  // ─── Démarrage story ─────────────────────────────────────────────

  Future<void> _startStory() async {
    _progressController
      ..stop()
      ..reset();
    _disposeVideo();
    widget.onStoryViewed(_currentStory.id);

    if (_currentStory.mediaType == 'video' && _currentStory.mediaUrl != null) {
      setState(() => _videoReady = false);
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_currentStory.mediaUrl!));
      try {
        await _videoController!.initialize();
        if (!mounted) return;
        final dur = _videoController!.value.duration;
        _progressController.duration =
            dur > Duration.zero ? dur : const Duration(seconds: 15);
        setState(() => _videoReady = true);
        _videoController!.play();
        _progressController.forward();
      } catch (e) {
        debugPrint('❌ Video init: $e');
        _progressController.duration = const Duration(seconds: 10);
        _progressController.forward();
      }
    } else {
      _progressController.duration = Duration(seconds: _currentStory.duration);
      _progressController.forward();
    }
  }

  // ─── Navigation stories ──────────────────────────────────────────

  void _nextStory() {
    // ✅ Bug fix : était > au lieu de <, empêchait l'avance dans la story
    if (_storyIndex < _currentGroup.stories.length - 1) {
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
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevGroup() {
    if (_groupIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // ─── Pause / Resume ──────────────────────────────────────────────

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

  // ─── Suppression ─────────────────────────────────────────────────

  void _confirmDelete() {
    _pause();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer la story ?',
          style: GoogleFonts.poppins(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _resume(); },
            child: Text('Annuler',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDeleteStory(_currentStory.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics:    const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() { _groupIndex = i; _storyIndex = 0; });
          _startStory();
        },
        itemCount:   widget.groups.length,
        itemBuilder: (_, __) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return GestureDetector(
      onTapDown:        (_) => _pause(),
      onTapUp:          (_) => _resume(),
      onLongPressStart: (_) => _pause(),
      onLongPressEnd:   (_) => _resume(),
      child: Stack(fit: StackFit.expand, children: [
        // ─ Contenu ──────────────────────────────────
        StoryContentWidget(
          story:           _currentStory,
          videoController: _videoController,
          videoReady:      _videoReady,
        ),
        // ─ Zones tap gauche / droite ────────────────
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _prevStory,
            child: Container(color: Colors.transparent),
          )),
          Expanded(child: GestureDetector(
            onTap: _nextStory,
            child: Container(color: Colors.transparent),
          )),
        ]),
        // ─ Header ────────────────────────────────────
        StoryViewerHeader(
          group:              _currentGroup,
          story:              _currentStory,
          storyIndex:         _storyIndex,
          progressController: _progressController,
          onClose:            () => Navigator.pop(context),
          onDelete:           _currentGroup.isMe ? _confirmDelete : null,
        ),
        // ─ Compteur vues (mes stories) ───────────────
        if (_currentGroup.isMe)
          StoryViewsCounter(count: _currentStory.viewsCount),
      ]),
    );
  }
}