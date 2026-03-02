import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/controllers/post_controller.dart';
import 'package:otakuverse/shared/services/storage_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController(); // ✅ Saisie manuelle
  final List<File> _selectedImages = [];
  bool _allowComments = true;
  bool _isPublishing = false;

  final _postsController = Get.find<PostsController>();
  final _uploadService = StorageUploadService();

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── SÉLECTION D'IMAGES ──────────────────────────────────────────
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(limit: 10);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages
          ..clear()
          ..addAll(images.map((e) => File(e.path)));
      });
    }
  }

  // ─── PUBLIER ─────────────────────────────────────────────────────
  Future<void> _publishPost() async {
    if (_captionController.text.trim().isEmpty) {
      Get.snackbar('Champ requis', 'Ajoute une légende',
          backgroundColor: AppColors.errorRed, colorText: AppColors.pureWhite);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Upload images
      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        Get.snackbar('Upload', 'Envoi des images en cours...',
            backgroundColor: AppColors.darkGray, colorText: AppColors.pureWhite);
        mediaUrls = await _uploadService.uploadImages(_selectedImages, userId);
      }

      // 2. Créer le post
      final success = await _postsController.createPost(
        caption: _captionController.text.trim(),
        mediaUrls: mediaUrls,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        allowComments: _allowComments,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        Get.snackbar('Succès', '✅ Post publié !',
            backgroundColor: AppColors.successGreen, colorText: AppColors.pureWhite);
      } else {
        Get.snackbar('Erreur', _postsController.errorMessage.value,
            backgroundColor: AppColors.errorRed, colorText: AppColors.pureWhite);
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Erreur', '❌ $e',
          backgroundColor: AppColors.errorRed, colorText: AppColors.pureWhite);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text('Nouveau post', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publishPost,
            child: _isPublishing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimsonRed))
                : const Text('Publier',
                    style: TextStyle(color: AppColors.crimsonRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildCaptionField(),
            const SizedBox(height: 16),
            _buildLocationField(), // ✅ Saisie manuelle (geolocator supprimé)
            const SizedBox(height: 16),
            _buildAllowComments(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Médias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('(optionnel)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.crimsonRed, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppColors.crimsonRed, size: 32),
                      SizedBox(height: 6),
                      Text('Ajouter', style: TextStyle(color: AppColors.crimsonRed, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              ..._selectedImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4, right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('${_selectedImages.length}/10 images', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildCaptionField() {
    return TextField(
      controller: _captionController,
      maxLength: 2200, maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Écris ta légende...',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true, fillColor: AppColors.darkGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        counterStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  // ✅ Saisie manuelle de la localisation (remplace geolocator)
  Widget _buildLocationField() {
    return TextField(
      controller: _locationController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Ajouter une localisation (ex: Paris, France)',
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.crimsonRed),
        filled: true, fillColor: AppColors.darkGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimsonRed),
        ),
      ),
    );
  }

  Widget _buildAllowComments() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.darkGray, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Autoriser les commentaires', style: TextStyle(color: Colors.white)),
        value: _allowComments,
        activeColor: AppColors.crimsonRed,
        onChanged: (val) => setState(() => _allowComments = val),
      ),
    );
  }
}