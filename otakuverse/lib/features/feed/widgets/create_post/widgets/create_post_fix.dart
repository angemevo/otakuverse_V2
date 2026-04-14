// Correction ciblée dans _publish() de create_post_screen.dart
// Remplacer la méthode _publish() existante par cette version :

/*
  Future<void> _publish() async {
    if (_captionCtrl.text.trim().isEmpty && _selectedImages.isEmpty) {
      Helpers.showWarningSnackbar('Ajoute une légende ou une image');
      return;
    }

    // ✅ FIX : vérifier mounted AVANT chaque setState
    if (!mounted) return;
    setState(() => _isPublishing = true);

    try {
      // ✅ FIX : SessionGuard à la place de currentUser!
      final userId = SessionGuard.requiredUid;

      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        mediaUrls = await _uploadService.uploadImages(
            _selectedImages, userId);
      }

      // ✅ FIX : vérifier mounted après chaque await long
      if (!mounted) return;

      final ok = await _postsCtrl.createPost(
        caption:         _captionCtrl.text.trim(),
        mediaUrls:       mediaUrls,
        location:        _locationCtrl.text.trim().isEmpty
            ? null : _locationCtrl.text.trim(),
        allowComments:   _allowComments,
        musicTitle:      _selectedSong?.title,
        musicArtist:     _selectedSong?.artist,
        musicTrackId:    _selectedSong?.id,
        musicPreviewUrl: _selectedSong?.previewUrl,
        musicImageUrl:   _selectedSong?.imageUrl,
      );

      // ✅ FIX : vérifier mounted avant navigation/snackbar
      if (!mounted) return;

      if (ok) {
        Get.offAllNamed(Routes.home);
        Helpers.showSuccessSnackbar('Ton post est maintenant visible');
      } else {
        Helpers.showErrorSnackbar(_postsCtrl.errorMessage.value);
      }
    } on SessionExpiredException {
      // ✅ Gérer la session expirée proprement
      // SessionGuard redirige déjà vers login — pas d'autre action
    } on UploadValidationException catch (e) {
      // ✅ Erreur de validation upload (taille/format)
      if (mounted) Helpers.showErrorSnackbar(e.message);
    } catch (e) {
      if (mounted) Helpers.showErrorSnackbar('Erreur : $e');
    } finally {
      // ✅ FIX : mounted check dans finally
      if (mounted) setState(() => _isPublishing = false);
    }
  }
*/

// ─── Imports à ajouter dans create_post_screen.dart ──────────────────────
//
// import 'package:otakuverse/core/utils/session_guard.dart';
// import 'package:otakuverse/shared/services/storage_upload_service.dart';
//   (déjà importé, mais la nouvelle version lève UploadValidationException)
