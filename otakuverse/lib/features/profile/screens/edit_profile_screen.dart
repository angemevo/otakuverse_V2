import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/profile/models/profile_model.dart';
import 'package:otakuverse/features/profile/services/profile_service.dart';
import 'package:otakuverse/shared/services/storage_upload_service.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _websiteController;

  String? _selectedGender;
  bool _isLoading = false;

  // ✅ XFile + bytes pour compatibilité web/mobile
  XFile? _newAvatarFile;
  XFile? _newBannerFile;
  Uint8List? _newAvatarBytes;
  Uint8List? _newBannerBytes;

  final _profileService = ProfileService();
  final _uploadService  = StorageUploadService();

  final List<String> _genders = ['male', 'female', 'other', 'prefer_not_to_say'];
  final Map<String, String> _genderLabels = {
    'male': 'Homme', 'female': 'Femme',
    'other': 'Autre', 'prefer_not_to_say': 'Préfère ne pas dire',
  };

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _bioController         = TextEditingController(text: widget.profile.bio);
    _websiteController     = TextEditingController(text: widget.profile.website);
    _selectedGender        = widget.profile.gender;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // ─── Sélection avatar ─────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newAvatarFile  = picked;
        _newAvatarBytes = bytes;
      });
    }
  }

  // ─── Sélection bannière ───────────────────────────────────────────
  Future<void> _pickBanner() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newBannerFile  = picked;
        _newBannerBytes = bytes;
      });
    }
  }

  // ─── Sauvegarde ───────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      String? avatarUrl = widget.profile.avatarUrl;
      String? bannerUrl = widget.profile.bannerUrl;

      // ✅ Upload avec bytes — pas de File, pas de dart:io
      if (_newAvatarBytes != null) {
        print('📤 Upload avatar...');
        final ext = _newAvatarFile?.name.split('.').last ?? 'jpg';
        avatarUrl = await _uploadService.uploadImageBytes(
          _newAvatarBytes!,
          userId,
          folder: 'avatars',
          ext: ext,
        );
        print('✅ Avatar URL : $avatarUrl');
      }

      if (_newBannerBytes != null) {
        print('📤 Upload bannière...');
        final ext = _newBannerFile?.name.split('.').last ?? 'jpg';
        bannerUrl = await _uploadService.uploadImageBytes(
          _newBannerBytes!,
          userId,
          folder: 'banners',
          ext: ext,
        );
        print('✅ Banner URL : $bannerUrl');
      }

      print('💾 Update profil avatarUrl=$avatarUrl bannerUrl=$bannerUrl');

      await _profileService.updateProfile(
        displayName: _displayNameController.text.trim().isEmpty
            ? null : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null : _bioController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null : _websiteController.text.trim(),
        gender:    _selectedGender,
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Get.snackbar(
        'Succès', '✅ Profil mis à jour',
        backgroundColor: AppColors.successGreen,
        colorText: AppColors.pureWhite,
      );
    } catch (e) {
      print('🔴 Erreur save : $e');
      if (!mounted) return;
      Get.snackbar(
        'Erreur', '❌ $e',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.pureWhite,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helper : affichage image universel ──────────────────────────
  // ✅ Fonctionne sur web ET mobile
  Widget _buildImagePreview({
    required Uint8List? newBytes,
    required XFile? newFile,
    required String? networkUrl,
    required BoxFit fit,
    Widget? fallback,
  }) {
    if (newBytes != null) {
      return Image.memory(newBytes, fit: fit);
    }
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(networkUrl, fit: fit);
    }
    return fallback ?? const SizedBox.shrink();
  }

  // ─── Helper : ImageProvider universel (pour CircleAvatar) ─────────
  ImageProvider? _avatarImageProvider() {
    if (_newAvatarBytes != null) return MemoryImage(_newAvatarBytes!);
    if (widget.profile.hasAvatar)  return NetworkImage(widget.profile.avatarUrl!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack, elevation: 0,
        title: Text('Modifier le profil',
            style: GoogleFonts.poppins(
                color: AppColors.pureWhite, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.crimsonRed))
                : Text('Sauvegarder',
                    style: GoogleFonts.inter(
                        color: AppColors.crimsonRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPhotoSection(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('Nom affiché', _displayNameController,
                      icon: Icons.person_outline,
                      hint: 'Ton nom visible publiquement'),
                  const SizedBox(height: 16),
                  _buildField('Bio', _bioController,
                      maxLines: 4, maxLength: 500,
                      icon: Icons.info_outline,
                      hint: 'Parle de toi...'),
                  const SizedBox(height: 16),
                  _buildField('Site web', _websiteController,
                      icon: Icons.link, hint: 'https://...'),
                  const SizedBox(height: 16),
                  _buildGenderPicker(),
                  const SizedBox(height: 32),
                  _buildFavoritesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ─── Bannière ─────────────────────────────────────────────
          GestureDetector(
            onTap: _pickBanner,
            child: SizedBox(
              width: double.infinity, height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ Image.memory au lieu de Image.file
                  _buildImagePreview(
                    newBytes:   _newBannerBytes,
                    newFile:    _newBannerFile,
                    networkUrl: widget.profile.bannerUrl,
                    fit:        BoxFit.cover,
                    fallback:   Container(
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient),
                    ),
                  ),
                  Container(color: AppColors.blackWithOpacity(0.45)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt,
                            color: AppColors.pureWhite, size: 28),
                        const SizedBox(height: 6),
                        Text('Modifier la bannière',
                            style: GoogleFonts.inter(
                                color: AppColors.pureWhite, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Avatar ───────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 16,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepBlack, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.darkGray,
                      // ✅ MemoryImage au lieu de FileImage
                      backgroundImage: _avatarImageProvider(),
                      child: _avatarImageProvider() == null
                          ? const Icon(Icons.person,
                              color: AppColors.pureWhite, size: 36)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppColors.crimsonRed, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: AppColors.pureWhite, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    int? maxLength,
    IconData? icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.inter(color: AppColors.pureWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.mediumGray),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.crimsonRed, size: 20)
                : null,
            filled: true,
            fillColor: AppColors.darkGray,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.crimsonRed, width: 1.5),
            ),
            counterStyle: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genre',
            style: GoogleFonts.inter(
                color: AppColors.mediumGray, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(12)),
          child: DropdownButton<String>(
            value: _selectedGender,
            isExpanded: true,
            dropdownColor: AppColors.darkGray,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.mediumGray),
            hint: Text('Sélectionner',
                style: GoogleFonts.inter(color: AppColors.mediumGray)),
            style: GoogleFonts.inter(
                color: AppColors.pureWhite, fontSize: 15),
            items: _genders
                .map((g) => DropdownMenuItem(
                    value: g, child: Text(_genderLabels[g]!)))
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    final hasContent = widget.profile.favoriteAnime.isNotEmpty ||
        widget.profile.favoriteManga.isNotEmpty ||
        widget.profile.favoriteGenres.isNotEmpty;
    if (!hasContent) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Préférences',
              style: GoogleFonts.poppins(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const Spacer(),
          Text('Modifiable bientôt',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        if (widget.profile.favoriteGenres.isNotEmpty) ...[
          Text('Genres favoris',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8, runSpacing: 8,
              children: widget.profile.favoriteGenres
                  .map((g) => _chip(g)).toList()),
          const SizedBox(height: 16),
        ],
        if (widget.profile.favoriteAnime.isNotEmpty) ...[
          Text('Animés favoris',
              style: GoogleFonts.inter(
                  color: AppColors.mediumGray, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8, runSpacing: 8,
              children: widget.profile.favoriteAnime
                  .map((a) => _chip(a)).toList()),
        ],
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.crimsonWithOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.crimsonWithOpacity(0.4)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              color: AppColors.lightCrimson,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }
}