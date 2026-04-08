// ignore_for_file: unused_field

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/screens/create_short_screen.dart';
import 'package:otakuverse/features/feed/screens/media_picker_screen.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';
import 'create_story_background.dart';
import 'create_story_bottom_bar.dart';
import 'create_story_top_bar.dart';

// ─── MODÈLE LOCAL ────────────────────────────────────────────────────
// class _StoryMediaItem {
//   final XFile     file;
//   final Uint8List bytes;
//   final bool      isVideo;
//   const _StoryMediaItem({
//     required this.file,
//     required this.bytes,
//     required this.isVideo,
//   });
// }

class CreateStoryScreen extends StatefulWidget {
  final XFile? preselectedFile;

  const CreateStoryScreen({
    super.key,
    this.preselectedFile,
  });

  @override
  State<CreateStoryScreen> createState() =>
      _CreateStoryScreenState();
}

class _CreateStoryScreenState
    extends State<CreateStoryScreen> {

  // ─── Media (multi) ───────────────────────────────────────────────
  List<StoryMediaItem> _mediaItems   = [];
  int                   _currentSlide = 0;

  // ✅ Helpers pour compatibilité avec CreateStoryBackground
  Uint8List? get _mediaPreview =>
      _mediaItems.isNotEmpty
          ? _mediaItems[_currentSlide].bytes
          : null;
  bool get _isVideo =>
      _mediaItems.isNotEmpty &&
      _mediaItems[_currentSlide].isVideo;

  // ─── Video player ────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoReady   = false;
  bool _videoPlaying = false;

  // ─── Caméra ──────────────────────────────────────────────────────
  CameraDevice _activeCamera = CameraDevice.rear;

  // ─── Miniature galerie ───────────────────────────────────────────
  Uint8List? _galleryThumb;

  // ─── Mode texte ──────────────────────────────────────────────────
  bool  _textMode = false;
  final _textCtrl = TextEditingController();
  Color _textBg   = const Color(0xFF7C6FFF);

  static const _bgColors = [
    Color(0xFFE01A3C), Color(0xFF7C6FFF),
    Color(0xFFFF6B35), Color(0xFF22C55E),
    Color(0xFF0EA5E9), Color(0xFFEC4899),
    Color(0xFF1A1A2E), Color(0xFF16213E),
  ];

  @override
  void initState() {
    super.initState();
    _loadGalleryThumb();
    if (widget.preselectedFile != null) {
      _loadPreselected();
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ─── GALERIE THUMB ───────────────────────────────────────────────
  Future<void> _loadGalleryThumb() async {
    try {
      final permission =
          await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return;

      final albums = await PhotoManager.getAssetPathList(
          type: RequestType.image);
      if (albums.isEmpty) return;

      final assets = await albums.first
          .getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) return;

      final bytes = await assets.first
          .thumbnailDataWithSize(
              const ThumbnailSize(150, 150));
      if (mounted) setState(() => _galleryThumb = bytes);
    } catch (_) {}
  }

  // ─── PRÉSELECTIONNÉ ──────────────────────────────────────────────
  Future<void> _loadPreselected() async {
    final file  = widget.preselectedFile!;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _mediaItems = [
        StoryMediaItem(
            file: file, bytes: bytes, isVideo: false)
      ];
      _currentSlide = 0;
    });
  }

  // ─── INIT VIDEO PLAYER ───────────────────────────────────────────
  Future<void> _initVideoPlayer(XFile file) async {
    await _videoController?.dispose();
    setState(() {
      _videoController = null;
      _videoReady      = false;
      _videoPlaying    = false;
    });

    try {
      final ctrl = VideoPlayerController.file(
          File(file.path));

      await ctrl.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Video init timeout'),
      );

      ctrl.setLooping(true);
      if (!mounted) return;

      setState(() {
        _videoController = ctrl;
        _videoReady      = true;
      });

      await ctrl.play();
      if (mounted) setState(() => _videoPlaying = true);
    } catch (e) {
      debugPrint('❌ Load error: $e');
      if (mounted) {
        Get.snackbar(
          'Erreur vidéo',
          'Impossible de charger cette vidéo',
          backgroundColor: AppColors.errorRed,
          colorText:       AppColors.pureWhite,
          snackPosition:   SnackPosition.BOTTOM,
          margin:          const EdgeInsets.all(16),
          borderRadius:    12,
        );
        // ✅ Retirer le media ajouté si erreur
        setState(() {
          if (_mediaItems.isNotEmpty) {
            _mediaItems.removeLast();
            _currentSlide =
                (_mediaItems.length - 1).clamp(0, 9);
          }
          _videoReady   = false;
          _videoPlaying = false;
        });
      }
    }
  }

  // ─── CAPTURE PHOTO ───────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    final file = await ImagePicker().pickImage(
      source:                ImageSource.camera,
      preferredCameraDevice: _activeCamera,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    await _videoController?.pause();
    setState(() {
      _mediaItems.add(StoryMediaItem(
          file: file, bytes: bytes, isVideo: false));
      _currentSlide = _mediaItems.length - 1;
      _textMode     = false;
      _videoReady   = false;
    });
  }

  // ─── CAPTURE VIDÉO ───────────────────────────────────────────────
  Future<void> _captureVideo() async {
    final file = await ImagePicker().pickVideo(
      source:                ImageSource.camera,
      preferredCameraDevice: _activeCamera,
      maxDuration:           const Duration(seconds: 30),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _mediaItems.add(StoryMediaItem(
          file: file, bytes: bytes, isVideo: true));
      _currentSlide = _mediaItems.length - 1;
      _textMode     = false;
    });

    await _initVideoPlayer(file);
  }

  // ─── CHANGER DE SLIDE ────────────────────────────────────────────
  Future<void> _onSlideChanged(int index) async {
    if (index == _currentSlide) return;
    await _videoController?.pause();

    setState(() => _currentSlide = index);

    final item = _mediaItems[index];
    if (item.isVideo) {
      await _initVideoPlayer(item.file);
    } else {
      setState(() {
        _videoReady   = false;
        _videoPlaying = false;
      });
    }
  }

  // ─── SUPPRIMER UN SLIDE ──────────────────────────────────────────
  void _removeSlide(int index) {
    setState(() {
      _mediaItems.removeAt(index);
      _currentSlide =
          (_currentSlide >= _mediaItems.length
              ? _mediaItems.length - 1
              : _currentSlide)
          .clamp(0, 9);
    });
  }

  // ─── SWITCH CAMÉRA ───────────────────────────────────────────────
  void _switchCamera() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeCamera =
          _activeCamera == CameraDevice.rear
              ? CameraDevice.front
              : CameraDevice.rear;
    });
  }

  // ─── TOGGLE PLAY/PAUSE VIDÉO ─────────────────────────────────────
  Future<void> _toggleVideoPlay() async {
    if (_videoController == null) return;
    if (_videoPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
    setState(() => _videoPlaying = !_videoPlaying);
  }

  // ─── GALERIE ─────────────────────────────────────────────────────
  Future<void> _openGallery() async {
    showModalBottomSheet(
      context:         context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(
                  Icons.image_outlined,
                  color: Colors.white),
              title: const Text('Photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await ImagePicker()
                    .pickImage(
                        source: ImageSource.gallery);
                if (file == null) return;
                final bytes = await file.readAsBytes();
                if (!mounted) return;
                await _videoController?.pause();
                setState(() {
                  _mediaItems.add(StoryMediaItem(
                    file:    file,
                    bytes:   bytes,
                    isVideo: false,
                  ));
                  _currentSlide = _mediaItems.length - 1;
                  _textMode     = false;
                  _videoReady   = false;
                });
              },
            ),

            ListTile(
              leading: const Icon(
                  Icons.videocam_outlined,
                  color: Colors.white),
              title: const Text('Vidéo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final file = await ImagePicker().pickVideo(
                  source:      ImageSource.gallery,
                  maxDuration:
                      const Duration(seconds: 30),
                );
                if (file == null) return;
                final bytes = await file.readAsBytes();
                if (!mounted) return;
                setState(() {
                  _mediaItems.add(StoryMediaItem(
                    file:    file,
                    bytes:   bytes,
                    isVideo: true,
                  ));
                  _currentSlide = _mediaItems.length - 1;
                  _textMode     = false;
                });
                await _initVideoPlayer(file);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── NAVIGATION ──────────────────────────────────────────────────
  void _navigateToTab(String tab) {
    if (tab == 'PUBLIER') {
      Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              const MediaPickerScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration:
              const Duration(milliseconds: 200),
        ),
      );
    } else if (tab == 'REEL') {
      Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              const CreateShortScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration:
              const Duration(milliseconds: 200),
        ),
      );
    }
  }

  // ─── COLOR TO HEX ────────────────────────────────────────────────
  String _colorToHex(Color color) {
    final r =
        color.red.toRadixString(16).padLeft(2, '0');
    final g =
        color.green.toRadixString(16).padLeft(2, '0');
    final b =
        color.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  // ─── PUBLIER ─────────────────────────────────────────────────────
  Future<void> _onNext() async {
    if (_mediaItems.isEmpty && !_textMode) {
      Get.snackbar(
        'Aucun contenu',
        'Prends une photo/vidéo ou écris quelque chose',
        backgroundColor: AppColors.darkGray,
        colorText:       AppColors.pureWhite,
        snackPosition:   SnackPosition.TOP,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await _videoController?.pause();

    final ctrl = Get.find<StoryController>();

    // ─ Texte ───────────────────────────────────────────────────────
    if (_textMode) {
      final text = _textCtrl.text.trim();
      if (text.isEmpty) {
        Get.snackbar('Texte vide',
            'Écris quelque chose avant de publier',
            backgroundColor: AppColors.darkGray,
            colorText:       AppColors.pureWhite,
            snackPosition:   SnackPosition.TOP,
            margin:          const EdgeInsets.all(16),
            borderRadius:    12);
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator(
            color: AppColors.crimsonRed)),
        barrierDismissible: false,
      );

      final ok = await ctrl.publishTextStory(
        text:    text,
        bgColor: _colorToHex(_textBg),
      );

      Get.back();
      if (!mounted) return;
      _showResult(ok);
      if (ok) Navigator.pop(context);
      return;
    }

    // ─ Médias ──────────────────────────────────────────────────────
    Get.dialog(
      const Center(child: CircularProgressIndicator(
          color: AppColors.crimsonRed)),
      barrierDismissible: false,
    );

    final bool ok;

    if (_mediaItems.length == 1) {
      // ✅ Un seul média
      final item = _mediaItems.first;
      ok = item.isVideo
          ? await ctrl.publishVideoStory(item.file)
          : await ctrl.publishImageStory(item.file);
    } else {
      // ✅ Plusieurs médias
      ok = await ctrl.publishMultiStory(
        _mediaItems.map((m) => StoryMediaItem(
          file:    m.file,
          isVideo: m.isVideo, 
          bytes:   m.bytes, 
        )).toList(),
      );
    }

    Get.back();
    if (!mounted) return;
    _showResult(ok);
    if (ok) Navigator.pop(context);
  }

  void _showResult(bool ok) {
    Get.snackbar(
      ok ? '✅ Story publiée !' : 'Erreur',
      ok
          ? 'Visible pendant 24h'
          : 'Impossible de publier la story',
      backgroundColor: ok
          ? AppColors.successGreen
          : AppColors.errorRed,
      colorText:     AppColors.pureWhite,
      snackPosition: SnackPosition.BOTTOM,
      margin:        const EdgeInsets.all(16),
      borderRadius:  12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─ Fond ───────────────────────────────────────────
          Positioned.fill(
            child: CreateStoryBackground(
              textMode:        _textMode,
              textBg:          _textBg,
              textCtrl:        _textCtrl,
              mediaPreview:    _mediaPreview,
              isVideo:         _isVideo,
              videoController: _videoController,
              videoReady:      _videoReady,
              videoPlaying:    _videoPlaying,
              onToggleVideo:   _toggleVideoPlay,
              // ✅ Params multi-slides
              mediaItems:      _mediaItems,
              currentSlide:    _currentSlide,
              onSlideChanged:  _onSlideChanged,
              onRemoveSlide:   _removeSlide,
            ),
          ),

          // ─ Gradient haut ──────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─ Gradient bas ───────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─ Top bar ────────────────────────────────────────
          // ✅ mediaPreview et onNext retirés
          CreateStoryTopBar(
            textMode:      _textMode,
            bgColors:      _bgColors,
            textBg:        _textBg,
            onClose:       () => Navigator.pop(context),
            onTextMode:    () =>
                setState(() => _textMode = true),
            onCloseText:   () =>
                setState(() => _textMode = false),
            onColorChange: (c) =>
                setState(() => _textBg = c),
          ),

          // ─ Bottom bar ─────────────────────────────────────
          CreateStoryBottomBar(
            galleryThumb:   _galleryThumb,
            mediaPreview:   _mediaPreview,
            textMode:       _textMode,
            onGallery:      _openGallery,
            onCapturePhoto: _capturePhoto,
            onCaptureVideo: _captureVideo,
            onSwitchCamera: _switchCamera,
            onNext:         _onNext,
            onNavigateTab:  _navigateToTab,
          ),
        ],
      ),
    );
  }
}