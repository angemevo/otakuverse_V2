import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/features/feed/screens/create_short_screen.dart';
import 'package:otakuverse/features/feed/screens/media/media_picker_screen.dart';
import 'package:otakuverse/features/stories/controllers/story_controller.dart';
import 'package:otakuverse/features/stories/services/story_service.dart';
import 'create_story_background.dart';
import 'create_story_bottom_bar.dart';
import 'create_story_top_bar.dart';
import 'story_gallery_sheet.dart';

class CreateStoryScreen extends StatefulWidget {
  final XFile? preselectedFile;
  const CreateStoryScreen({super.key, this.preselectedFile});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {

  List<StoryMediaItem>   _mediaItems   = [];
  int                    _currentSlide = 0;
  VideoPlayerController? _videoController;
  bool                   _videoReady   = false;
  bool                   _videoPlaying = false;
  CameraDevice           _activeCamera = CameraDevice.rear;
  Uint8List?             _galleryThumb;
  bool                   _textMode     = false;
  final                  _textCtrl     = TextEditingController();
  Color                  _textBg       = const Color(0xFF7C6FFF);

  Uint8List? get _mediaPreview =>
      _mediaItems.isNotEmpty ? _mediaItems[_currentSlide].bytes : null;
  bool get _isVideo =>
      _mediaItems.isNotEmpty && _mediaItems[_currentSlide].isVideo;

  static const _bgColors = [
    Color(0xFFE01A3C), Color(0xFF7C6FFF), Color(0xFFFF6B35), Color(0xFF22C55E),
    Color(0xFF0EA5E9), Color(0xFFEC4899), Color(0xFF1A1A2E), Color(0xFF16213E),
  ];

  @override
  void initState() {
    super.initState();
    _loadGalleryThumb();
    if (widget.preselectedFile != null) _loadPreselected();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryThumb() async {
    try {
      final perm = await PhotoManager.requestPermissionExtend();
      if (!perm.isAuth) return;
      final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isEmpty) return;
      final assets = await albums.first.getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) return;
      final bytes = await assets.first
          .thumbnailDataWithSize(const ThumbnailSize(150, 150));
      if (mounted) setState(() => _galleryThumb = bytes);
    } catch (_) {}
  }

  Future<void> _loadPreselected() async {
    final file  = widget.preselectedFile!;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _mediaItems   = [StoryMediaItem(file: file, bytes: bytes, isVideo: false)];
      _currentSlide = 0;
    });
  }

  Future<void> _initVideoPlayer(XFile file) async {
    await _videoController?.dispose();
    setState(() { _videoController = null; _videoReady = false; _videoPlaying = false; });
    try {
      final ctrl = VideoPlayerController.file(File(file.path));
      await ctrl.initialize().timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('timeout'));
      ctrl.setLooping(true);
      if (!mounted) return;
      setState(() { _videoController = ctrl; _videoReady = true; });
      await ctrl.play();
      if (mounted) setState(() => _videoPlaying = true);
    } catch (e) {
      debugPrint('❌ Video error: $e');
      if (!mounted) return;
      Helpers.showErrorSnackbar('Impossible de charger cette vidéo');
      setState(() {
        if (_mediaItems.isNotEmpty) {
          _mediaItems.removeLast();
          _currentSlide = (_mediaItems.length - 1).clamp(0, 9);
        }
        _videoReady = false; _videoPlaying = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.camera, preferredCameraDevice: _activeCamera);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _videoController?.pause();
    setState(() {
      _mediaItems.add(StoryMediaItem(file: file, bytes: bytes, isVideo: false));
      _currentSlide = _mediaItems.length - 1;
      _textMode = false; _videoReady = false;
    });
  }

  Future<void> _captureVideo() async {
    final file = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: _activeCamera,
        maxDuration: const Duration(seconds: 30));
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _mediaItems.add(StoryMediaItem(file: file, bytes: bytes, isVideo: true));
      _currentSlide = _mediaItems.length - 1; _textMode = false;
    });
    await _initVideoPlayer(file);
  }

  Future<void> _onSlideChanged(int index) async {
    if (index == _currentSlide) return;
    await _videoController?.pause();
    setState(() => _currentSlide = index);
    final item = _mediaItems[index];
    if (item.isVideo) await _initVideoPlayer(item.file);
    else setState(() { _videoReady = false; _videoPlaying = false; });
  }

  void _removeSlide(int index) => setState(() {
    _mediaItems.removeAt(index);
    _currentSlide = (_currentSlide >= _mediaItems.length
        ? _mediaItems.length - 1 : _currentSlide).clamp(0, 9);
  });

  void _switchCamera() {
    HapticFeedback.lightImpact();
    setState(() => _activeCamera =
        _activeCamera == CameraDevice.rear ? CameraDevice.front : CameraDevice.rear);
  }

  Future<void> _toggleVideoPlay() async {
    if (_videoController == null) return;
    if (_videoPlaying) await _videoController!.pause();
    else               await _videoController!.play();
    setState(() => _videoPlaying = !_videoPlaying);
  }

  Future<void> _openGallery() => StoryGallerySheet.show(context,
    onMediaAdded: (item) async {
      await _videoController?.pause();
      setState(() {
        _mediaItems.add(item);
        _currentSlide = _mediaItems.length - 1;
        _textMode = false;
        if (!item.isVideo) _videoReady = false;
      });
      if (item.isVideo) await _initVideoPlayer(item.file);
    },
  );

  void _navigateToTab(String tab) {
    if (tab == 'STORY') return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          tab == 'PUBLIER' ? const MediaPickerScreen() : const CreateShortScreen(),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }

  String _colorToHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}'
      '${c.green.toRadixString(16).padLeft(2, '0')}'
      '${c.blue.toRadixString(16).padLeft(2, '0')}';

  Future<void> _onNext() async {
    if (_mediaItems.isEmpty && !_textMode) {
      Helpers.showWarningSnackbar('Prends une photo/vidéo ou écris quelque chose');
      return;
    }
    HapticFeedback.mediumImpact();
    await _videoController?.pause();
    Helpers.showLoadingDialog();
    final ok = _textMode ? await _publishText() : await _publishMedia();
    Helpers.hideLoadingDialog();
    if (!mounted) return;
    Get.snackbar(
      ok ? '✅ Story publiée !' : 'Erreur',
      ok ? 'Visible pendant 24h' : 'Impossible de publier la story',
      backgroundColor: ok ? AppColors.success : AppColors.error,
      colorText: AppColors.textPrimary,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16), borderRadius: 12,
    );
    if (ok) Navigator.pop(context);
  }

  Future<bool> _publishText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      Helpers.showWarningSnackbar('Écris quelque chose avant de publier');
      return false;
    }
    return Get.find<StoryController>()
        .publishTextStory(text: text, bgColor: _colorToHex(_textBg));
  }

  Future<bool> _publishMedia() async {
    final ctrl = Get.find<StoryController>();
    if (_mediaItems.length == 1) {
      final item = _mediaItems.first;
      return item.isVideo
          ? ctrl.publishVideoStory(item.file)
          : ctrl.publishImageStory(item.file);
    }
    return ctrl.publishMultiStory(
        _mediaItems.map((m) =>
            StoryMediaItem(file: m.file, isVideo: m.isVideo, bytes: m.bytes))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: CreateStoryBackground(
          textMode: _textMode, textBg: _textBg, textCtrl: _textCtrl,
          mediaPreview: _mediaPreview, isVideo: _isVideo,
          videoController: _videoController,
          videoReady: _videoReady, videoPlaying: _videoPlaying,
          onToggleVideo: _toggleVideoPlay,
          mediaItems: _mediaItems, currentSlide: _currentSlide,
          onSlideChanged: _onSlideChanged, onRemoveSlide: _removeSlide,
        )),
        _buildGradient(top: true),
        _buildGradient(top: false),
        CreateStoryTopBar(
          textMode: _textMode, bgColors: _bgColors, textBg: _textBg,
          onClose:       () => Navigator.pop(context),
          onTextMode:    () => setState(() => _textMode = true),
          onCloseText:   () => setState(() => _textMode = false),
          onColorChange: (c) => setState(() => _textBg = c),
        ),
        CreateStoryBottomBar(
          galleryThumb: _galleryThumb, mediaPreview: _mediaPreview,
          textMode: _textMode,
          onGallery: _openGallery, onCapturePhoto: _capturePhoto,
          onCaptureVideo: _captureVideo, onSwitchCamera: _switchCamera,
          onNext: _onNext, onNavigateTab: _navigateToTab,
        ),
      ]),
    );
  }

  Widget _buildGradient({required bool top}) => Positioned(
    top: top ? 0 : null, bottom: top ? null : 0,
    left: 0, right: 0,
    child: Container(
      height: top ? 140 : 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter    : Alignment.bottomCenter,
          end:   top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: top ? 0.65 : 0.85), Colors.transparent],
        ),
      ),
    ),
  );
}