import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/constants/app_keys.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/core/services/music_service.dart';
import 'package:otakuverse/core/utils/session_guard.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/widgets/create_post/caption_section.dart';
import 'package:otakuverse/features/feed/widgets/create_post/location_section.dart';
import 'package:otakuverse/features/feed/widgets/create_post/post_preview_widget.dart';
import 'package:otakuverse/features/feed/widgets/create_post/quick_options_widget.dart';
import 'package:otakuverse/features/feed/widgets/create_post/share_button.dart';
import 'package:otakuverse/features/feed/widgets/create_post/music_section.dart';
import 'package:otakuverse/main.dart';
import 'package:otakuverse/shared/services/storage_upload_service.dart';

class CreatePostScreen extends StatefulWidget {
  final List<XFile> preselectedFiles;

  const CreatePostScreen({
    super.key,
    this.preselectedFiles = const [],
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionCtrl  = TextEditingController();
  final _locationCtrl = TextEditingController();

  final List<XFile>     _selectedImages = [];
  final List<Uint8List> _imagePreviews  = [];

  bool        _allowComments  = true;
  bool        _isPublishing   = false;
  int         _currentPreview = 0;
  MusicTrack? _selectedSong;
  PollData?   _pollData;

  final _postsCtrl     = Get.find<PostsController>();
  final _uploadService = StorageUploadService();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFiles.isNotEmpty) _loadPreselected();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreselected() async {
    final previews = await Future.wait(
        widget.preselectedFiles.map((f) => f.readAsBytes()));
    if (!mounted) return;
    setState(() {
      _selectedImages..clear()..addAll(widget.preselectedFiles);
      _imagePreviews..clear()..addAll(previews);
    });
  }

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    final previews = await Future.wait(files.map((f) => f.readAsBytes()));
    if (!mounted) return;
    setState(() {
      _selectedImages..clear()..addAll(files);
      _imagePreviews..clear()..addAll(previews);
      _currentPreview = 0;
    });
  }

  Future<void> _publish() async {
    if (_captionCtrl.text.trim().isEmpty && _selectedImages.isEmpty) {
      Helpers.showWarningSnackbar('Ajoute une légende ou une image');
      return;
    }
    if (!mounted) return;
    setState(() => _isPublishing = true);

    try {
      final userId = SessionGuard.requiredUid;
      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        mediaUrls = await _uploadService.uploadImages(
            _selectedImages, userId);
      }
      if (!mounted) return;

      final ok = await _postsCtrl.createPost(
        caption:           _captionCtrl.text.trim(),
        mediaUrls:         mediaUrls,
        location:          _locationCtrl.text.trim().isEmpty
            ? null : _locationCtrl.text.trim(),
        allowComments:     _allowComments,
        musicTitle:        _selectedSong?.title,
        musicArtist:       _selectedSong?.artist,
        musicTrackId:      _selectedSong?.id,
        musicPreviewUrl:   _selectedSong?.previewUrl,
        musicImageUrl:     _selectedSong?.imageUrl,
        pollQuestion:      _pollData?.question,
        pollOptionA:       _pollData?.optionA,
        pollOptionB:       _pollData?.optionB,
        pollDurationHours: _pollData?.durationHours,
      );

      if (!mounted) return;
      if (ok) {
        Get.offAllNamed(Routes.home);
        Helpers.showSuccessSnackbar('Ton post est maintenant visible');
      } else {
        Helpers.showErrorSnackbar(_postsCtrl.errorMessage.value);
      }
    } on SessionExpiredException {
      // SessionGuard redirige déjà vers login
    } on UploadValidationException catch (e) {
      if (mounted) Helpers.showErrorSnackbar(e.message);
    } catch (e) {
      if (mounted) Helpers.showErrorSnackbar('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:     AppColors.bgPrimary,
      appBar:              _buildAppBar(),
      bottomNavigationBar: ShareButton(
          isPublishing: _isPublishing, onTap: _publish),
      body: SingleChildScrollView(
        child: Column(children: [
          PostPreviewWidget(
            imagePreviews:  _imagePreviews,
            currentPreview: _currentPreview,
            onPageChanged:  (i) => setState(() => _currentPreview = i),
            onAddImage:     _pickImages,
          ),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          CaptionSection(controller: _captionCtrl),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          QuickOptionsWidget(
            onPollCreated: (data) => setState(() => _pollData = data),
          ),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          MusicSection(
            selectedSong:   _selectedSong,
            onSongSelected: (t) => setState(() => _selectedSong = t),
          ),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          LocationSection(
            controller:        _locationCtrl,
            onLocationChanged: () => setState(() {}),
          ),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          _buildCommentsOption(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation:       0,
      leading: IconButton(
        icon: const Icon(Icons.close,
            color: AppColors.textPrimary, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Nouvelle publication',
          style: GoogleFonts.poppins(
            color:      AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize:   16,
          )),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          // ✅ Key sur le bouton Partager de l'AppBar
          child: GestureDetector(
            key:  AppKeys.sharePostButton,
            onTap: _isPublishing ? null : _publish,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _isPublishing
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Partager',
                      style: GoogleFonts.inter(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsOption() {
    return Container(
      color: AppColors.bgPrimary,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 0),
        title: Text('Autoriser les commentaires',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontSize: 15)),
        subtitle: Text('Les gens peuvent commenter ton post',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 12)),
        value:              _allowComments,
        activeThumbColor:   AppColors.primary,
        activeTrackColor:   AppColors.primary.withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.2),
        onChanged: (v) => setState(() => _allowComments = v),
      ),
    );
  }
}
