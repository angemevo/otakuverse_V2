import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/music_service.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/features/feed/widgets/create_post/caption_section.dart';
import 'package:otakuverse/features/feed/widgets/create_post/location_section.dart';
import 'package:otakuverse/features/feed/widgets/create_post/post_preview_widget.dart';
import 'package:otakuverse/features/feed/widgets/create_post/quick_options_widget.dart';
import 'package:otakuverse/features/feed/widgets/create_post/share_button.dart';
import 'package:otakuverse/features/feed/widgets/create_post/music_section.dart';
import 'package:otakuverse/main.dart';
import 'package:otakuverse/shared/services/storage_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  final List<XFile> preselectedFiles;

  const CreatePostScreen({
    super.key,
    this.preselectedFiles = const [],
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController  = TextEditingController();
  final _locationController = TextEditingController();

  final List<XFile>     _selectedImages = [];
  final List<Uint8List> _imagePreviews  = [];

  bool          _allowComments  = true;
  bool          _isPublishing   = false;
  int           _currentPreview = 0;
  SpotifyTrack? _selectedTrack; // ✅ Nom correct

  final _postsController = Get.find<PostsController>();
  final _uploadService   = StorageUploadService();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFiles.isNotEmpty) {
      _loadPreselected();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── CHARGER FICHIERS PRÉSÉLECTIONNÉS ────────────────────────────
  Future<void> _loadPreselected() async {
    final previews = await Future.wait(
      widget.preselectedFiles.map((f) => f.readAsBytes()),
    );
    if (!mounted) return;
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(widget.preselectedFiles);
      _imagePreviews
        ..clear()
        ..addAll(previews);
    });
  }

  // ─── PUBLIER ─────────────────────────────────────────────────────
  Future<void> _publish() async {
    if (_captionController.text.trim().isEmpty &&
        _selectedImages.isEmpty) {
      Get.snackbar(
        'Champ requis',
        'Ajoute une légende ou une image',
        backgroundColor: AppColors.errorRed,
        colorText:       AppColors.pureWhite,
        snackPosition:   SnackPosition.BOTTOM,
        margin:          const EdgeInsets.all(16),
        borderRadius:    12,
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final userId =
          Supabase.instance.client.auth.currentUser!.id;

      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        mediaUrls = await _uploadService.uploadImages(
          _selectedImages, userId,
        );
      }

      final success = await _postsController.createPost(
        caption:         _captionController.text.trim(),
        mediaUrls:       mediaUrls,
        location:        _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        allowComments:   _allowComments,
        musicTitle:      _selectedTrack?.title,      // ✅
        musicArtist:     _selectedTrack?.artist,     // ✅
        musicTrackId:    _selectedTrack?.id,         // ✅
        musicPreviewUrl: _selectedTrack?.previewUrl, // ✅
        musicImageUrl:   _selectedTrack?.imageUrl,   // ✅
      );

      if (!mounted) return;

      if (success) {
        Get.offAllNamed(Routes.home);
        Get.snackbar(
          '✅ Post publié !',
          'Ton post est maintenant visible',
          backgroundColor: AppColors.successGreen,
          colorText:       AppColors.pureWhite,
          snackPosition:   SnackPosition.BOTTOM,
          margin:          const EdgeInsets.all(16),
          borderRadius:    12,
        );
      } else {
        Get.snackbar(
          'Erreur',
          _postsController.errorMessage.value,
          backgroundColor: AppColors.errorRed,
          colorText:       AppColors.pureWhite,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Erreur', '❌ $e',
          backgroundColor: AppColors.errorRed,
          colorText:       AppColors.pureWhite);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar:          _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─ Preview ────────────────────────────────────
            PostPreviewWidget(
              imagePreviews:  _imagePreviews,
              currentPreview: _currentPreview,
              onPageChanged:  (i) =>
                  setState(() => _currentPreview = i),
            ),

            const Divider(
                color: Color(0xFF1F1F1F), height: 1),

            // ─ Caption ────────────────────────────────────
            CaptionSection(
              controller: _captionController,
            ),

            const Divider(
                color: Color(0xFF1F1F1F), height: 1),

            // ─ Sondage / Invite ───────────────────────────
            const QuickOptionsWidget(),

            const Divider(
                color: Color(0xFF1F1F1F), height: 1),

            // ─ Musique Spotify ────────────────────────────
            MusicSection(
              selectedTrack:   _selectedTrack,           // ✅
              onTrackSelected: (track) =>
                  setState(() => _selectedTrack = track), // ✅
            ),

            const Divider(
                color: Color(0xFF1F1F1F), height: 1),

            // ─ Localisation ───────────────────────────────
            LocationSection(
              controller:        _locationController,
              onLocationChanged: () => setState(() {}),
            ),

            const Divider(
                color: Color(0xFF1F1F1F), height: 1),

            // ─ Commentaires ───────────────────────────────
            _buildCommentsOption(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: ShareButton(
        isPublishing: _isPublishing,
        onTap:        _publish,
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.deepBlack,
      elevation:       0,
      leading: IconButton(
        icon: const Icon(Icons.close,
            color: AppColors.pureWhite, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Nouvelle publication',
          style: GoogleFonts.poppins(
              color:      AppColors.pureWhite,
              fontWeight: FontWeight.w600,
              fontSize:   16)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _isPublishing ? null : _publish,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: _isPublishing
                    ? AppColors.crimsonRed
                        .withValues(alpha: 0.4)
                    : AppColors.crimsonRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:       Colors.white))
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

  // ─── OPTION COMMENTAIRES ─────────────────────────────────────────
  Widget _buildCommentsOption() {
    return Container(
      color: AppColors.deepBlack,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 0),
        title: Text('Autoriser les commentaires',
            style: GoogleFonts.inter(
                color:    AppColors.pureWhite,
                fontSize: 15)),
        subtitle: Text(
          'Les gens peuvent commenter ton post',
          style: GoogleFonts.inter(
              color:    AppColors.mediumGray,
              fontSize: 12),
        ),
        value:              _allowComments,
        activeColor:        AppColors.crimsonRed,
        activeTrackColor:   AppColors.crimsonRed
            .withValues(alpha: 0.3),
        inactiveThumbColor: AppColors.mediumGray,
        inactiveTrackColor: AppColors.mediumGray
            .withValues(alpha: 0.2),
        onChanged: (val) =>
            setState(() => _allowComments = val),
      ),
    );
  }
}